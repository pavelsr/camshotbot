package Telegram::CamshotBot::Command::env;

# ABSTRACT: prints list of all environment variables

use Mojo::Base 'Mojolicious::Command';
use Data::Printer;

has description => 'Prints list of set CAMSHOTBOT_* environment variables and its values';
has usage       => "Usage: APPLICATION env\n";

sub run {
  my $self = shift;
  print "### SETTED ENVIRONMENT VARIABLES ###\n";
  print `printenv | grep CAMSHOTBOT_* | sort -u`;
  print "\n\n";
  print "### VARIABLES FROM CONFIG ###\n";
  p $self->app->config;
  print "\n\n";
}

1;
