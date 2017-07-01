#!/usr/bin/env perl

# ABSTRACT: Telegram bot that send you a snapshot from IP camera using ffmpeg (don't forget to install it!)

=head1 RUNNING

Docker way

  wget https://raw.githubusercontent.com/pavelsr/camshotbot/master/docker-compose.yml.example > docker-compose.yml

then edit CAMSHOTBOT_* variables and change network if needed

  docker-compose up -d

Standalone way

1) Place .camshotbot file in home user directory or camshotbot.conf.json in directory from what you will run camshotbot
Add all essential variables:  telegram_api_token, stream_url, bot_domain

2) As alternative to (1) you can set all CAMSHOTBOT_* environment variables (see ENVIRONMENT VARIABLES section)

3) run

  camshotbot daemon

For performance you can run ffmpeg in a separate "caching" docker container.
String below will output a single image that is continuously overwritten with new images

  docker run -d -it -v $(pwd):/tmp/workdir --network=host jrottenberg/ffmpeg:3.3-alpine -hide_banner -loglevel error -i rtsp://10.132.193.9//ch0.h264 -f image2 -vf fps=1/3 -y -update 1 latest.jpg

For more details please see docker-compose.yml.example

!! ATTENTION ! Bot is working correctly only if version of Telegram::CamshotBot >= 0.03.
There are some critical errors in previous versions, sorry for that.

=head1 ENVIRONMENT VARIABLES

Environment variables are always checked firstly, before any config files

To get list of all available environment variables plese run after git clone:

  grep -o -P "CAMSHOTBOT_\w+" lib/Telegram/CamshotBot.pm | sort -u

Actual List (useful for Docker deployment):

  CAMSHOTBOT_CONFIG
  CAMSHOTBOT_DOMAIN
  CAMSHOTBOT_FFMPEG_DOCKER
  CAMSHOTBOT_LAST_SHOT_FILENAME
  CAMSHOTBOT_POLLING
  CAMSHOTBOT_POLLING_TIMEOUT
  CAMSHOTBOT_STREAM_URL
  CAMSHOTBOT_TELEGRAM_API_TOKEN
  CAMSHOTBOT_TELEGRAM_DEBUG
  CAMSHOTBOT_WEBTAIL_LOG_FILE

Check more details about their usage at docker-compose.yml.example

To check which variables are set you can run

  printenv | grep CAMSHOTBOT_* | sort -u

For setting environment variable you can use

  export CAMSHOTBOT_POLLING=1

=cut

package Telegram::CamshotBot;

use Telegram::CamshotBot::Util qw(first_existing_file random_caption abs_path_of_sample_mojo_conf fev);
use Mojolicious::Lite;
use Mojolicious::Plugin::JSONConfig;
use Mojolicious::Plugin::Webtail;
use WWW::Telegram::BotAPI;
use Date::Format;
use Telegram::Bot::Message;
use feature 'say';
use Data::Dumper;
use Data::Printer;
use Cwd;
use Net::Ping;
use Regexp::Common qw /net/;

my $config_file_path = first_existing_file(
  $ENV{"CAMSHOTBOT_CONFIG"},
  $ENV{"HOME"}.'/.camshotbot',
  getcwd.'/camshotbot.conf.json',
  abs_path_of_sample_mojo_conf(__PACKAGE__),
);

print "Using config: ".$config_file_path."\n";

my $config_values = plugin 'JSONConfig' => { file => $config_file_path };

  plugin( 'Webtail', file => $ENV{CAMSHOTBOT_WEBTAIL_LOG_FILE} || $config_values->{log_file} ); # https://metacpan.org/pod/Mojolicious::Plugin::Webtail

# BEGIN { $ENV{TELEGRAM_BOTAPI_DEBUG}=1 };

my $api;
my $bot_name = '';
my $telegram_token = $ENV{CAMSHOTBOT_TELEGRAM_API_TOKEN} || $config_values->{telegram_api_token};
my $screenshot_file = $ENV{CAMSHOTBOT_LAST_SHOT_FILENAME} || $config_values->{last_shot_filename} || 'latest.jpg'; # name of last screenshot or env
my $stream_url = $ENV{CAMSHOTBOT_STREAM_URL} || $config_values->{stream_url};
my $ffmpeg_cmd = 'ffmpeg -hide_banner -loglevel panic -i '.$stream_url.' -f image2 -vframes 1 '.$screenshot_file if ($stream_url);
my ($camera_ip) = ($stream_url  =~ /($RE{net}{IPv4})/) if ($stream_url);
my $bot_domain = $ENV{VIRTUAL_HOST} || $ENV{LETSENCRYPT_HOST} || $ENV{CAMSHOTBOT_DOMAIN} || $config_values->{bot_domain};
my $polling_flag = $ENV{CAMSHOTBOT_POLLING} || $config_values->{polling}; # 0 or not set -> webhook, 1 -> polling
my $polling_timeout = 3; # default
if ($polling_flag) {
  $polling_timeout = $ENV{CAMSHOTBOT_POLLING_TIMEOUT} || $config_values->{polling_timeout};
} else {
  $polling_timeout = undef;
}
my $docker_flag = $ENV{CAMSHOTBOT_FFMPEG_DOCKER} || $config_values->{ffmpeg_docker}; # any value to send cached image

if ($telegram_token) { # maybe add
  $api = WWW::Telegram::BotAPI->new (
      token => $telegram_token
  );
  $bot_name = $api->getMe->{result}{username};
} else {
  say "Attention! Telegram API token isn't specified. Please edit ".$config_file_path." or CAMSHOTBOT_TELEGRAM_API_TOKEN";
}


helper answer => sub {
	my ($c, $update) = @_;

	app->log->info("Processing new update...");
	my $mo = Telegram::Bot::Message->create_from_hash($update->{message});

	my $msg = $mo->text;
  my $chat_id = $mo->chat->id;
  my $from_id = $mo->from->id;
  my $date = $mo->date;
  my $date_str = time2str("%R %a %o %b %Y" ,$mo->date); # 11:59 Sun 29th Jan 2017


  ###### Loggging
	if ($ENV{CAMSHOTBOT_TELEGRAM_DEBUG} || $config_values->{debug}) {
		# full log, convenient if you need to restict chat_id's and check what's wrong
		app->log->info("Update from Telegram API: ".Dumper $update);
		app->log->info("Update parsed by Telegram::Bot::Message: ".Dumper $mo);
	} else {
		my $from_str = '';
		my $username = $mo->from->username;
		if ($username) {
			$from_str = $username;
		} else {
			$from_str = $mo->from->first_name." ".$mo->from->first_name." (id ".$from_id.")";
		}
		app->log->info($msg." from ".$from_str." sent at ".$date_str);
	};
  ###### end loggging

  if ($docker_flag) {
    app->log->info("Sending a screenshot generated by ffmpeg docker container some time ago");
  } else {
    `rm -f $screenshot_file`; # remove old screenshot
   	my $o = `$ffmpeg_cmd`;
    app->log->info("Screenshot got with command: ".$ffmpeg_cmd.', result : '.$o);
  }

   	if ( ($msg eq "/shot") || ($msg eq '/shot@'.$bot_name )) {

		$api->sendPhoto ({
		    chat_id => $chat_id,
		    photo   => {
		        file => $screenshot_file
		    },
		    caption => random_caption(),
		    reply_to_message_id => $mo->message_id
		});
	}

	if ($msg eq "/help") {

		$api->sendMessage ({
		    chat_id => $chat_id,
		    text => '/shot - Get online camera shot',
		    reply_to_message_id => $mo->message_id
		});
	}

};

# for local testing purposes. also shows how many unprocessed updates in queue on server
helper check_for_updates => sub {
	my $c = shift;
	my $res = $api->deleteWebhook() ; # disable webhooks
	# warn Dumper $res;
	my $updates = $api->getUpdates();
	my $h = {
		updates_in_queue => {}
	};
	$h->{updates_in_queue}{count} = scalar @{$updates->{result}};
	$h->{updates_in_queue}{details} = \@{$updates->{result}};

	my @u_ids;
	for (@{$updates->{result}}) {
		push @u_ids, $_->{update_id};
	}

	$h->{updates_in_queue}{update_ids} = \@u_ids;

	$c->setWebhook() if !($polling_flag); # set Webhook again if needed

	return $h;
};

helper setWebhook => sub {
	my $c = shift;
	return $api->setWebhook({ url => 'https://'.$bot_domain.'/'.$telegram_token });
};


post '/'.$telegram_token => sub {
  my $c = shift;
  my $update = $c->req->json;
  $c->answer($update);
  $c->render(json => "ok");
};

get '/' => sub {
	shift->render(text => 'bot is running');
};

get '/status' => sub {
	my $c = shift;
	my $status = {};
	$status->{telegram_api} = eval { $api->getMe } or $status->{telegram_api} = $api->parse_error->{msg};
  $status->{stream_url} = $stream_url;
  $status->{ffmpeg_docker} = $docker_flag;
	my $p = Net::Ping->new();
	$status->{vpn_status} = 'down';
	$status->{vpn_status} = 'up' if $p->ping($camera_ip);
	$status->{WebhookInfo} = $api->getWebhookInfo;
	$p->close();
	$c->render(json => $status);
};

get '/setwebhook' => sub {
	my $c = shift;
	my $res = $c->setWebhook();
	$c->render( json => $res );
};

# shows info about unprocessed updates on server
get '/debug' => sub {
	my $c = shift; # $c = Mojolicious::Controller object
	$c->render( json => $c->check_for_updates() );
};




if ($telegram_token && $polling_flag) {

	my $res = $api->deleteWebhook();
	app->log->info("Webhook was deleted. Starting polling with ".$polling_timeout."secs timeout ...") if $res;

	Mojo::IOLoop->recurring($polling_timeout => sub {

		my @updates = @{$api->getUpdates->{result}};

		if (@updates) {
			for my $u (@updates) {
				#app->build_controller->answer($u); # Mojolicious::Lite ->  Mojolicious::Controller -> Mojolicious::Helper
        app->answer($u); # Mojolicious::Lite ->  Mojolicious::Controller -> Mojolicious::Helper
        $api->getUpdates({ offset => $u->{update_id} + 1.0 }); # clear buffer
			}
		}

	});
}

# my $queue = app->build_controller->check_for_updates()->{updates_in_queue};
# if ne daemon

if ($telegram_token) {
  my $queue = app->check_for_updates()->{updates_in_queue};
  app->log->info('Starting bot @'.$bot_name."...");
  app->log->info("Having ".$queue->{count}." stored Updates at Telegram server");
  app->log->info("Unprocessed update ids (for offset debug): ".join(',', @{$queue->{update_ids}}) );
}

push @{app->commands->namespaces}, 'Telegram::CamshotBot::Command';
app->start;

1;


=head1 DEVELOPMENT

If you want to run unit tests without dzil test

  prove -l -v t

or

  perl -Ilib

=cut
