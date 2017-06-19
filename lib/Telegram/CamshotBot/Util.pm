package Telegram::CamshotBot::Util;

# ABSTRACT: Reusable functions

# use Mojo::Base -strict;
# use base qw (Exporter);

use File::Basename;
use Exporter 'import';
use Data::Dumper;

our @EXPORT_OK = (
  qw(first_existing_file fef get_pm_from_mod random_caption abs_path_of_sample_mojo_conf first_existing_variable fev)
);


=method random_caption

Select a random element from array

Accepts ARRAYREF like

  [
    "Common sense is not so common",
    "Just do it",
    "We make porn here",
    "Learn by doing"
  ]

=cut

sub random_caption {
  my $arr = shift;
  my @array = @$arr;
	my $index  = rand @array;
	my $element = $array[$index];
	return $element;
}


=method random_caption

Return first file from array which exists

=cut

sub first_existing_file {
  my @files = @_;
  for my $filename (@files) {
    if (-e $filename) {
      return $filename;
    }
  }
  return undef;
}


sub get_pm_from_mod {
  my $p = shift; # $p = package name
  my @s = split(/::/, $p);
  $p = join('::', $s[0], $s[1]);
  $p =~ s/::/\//g;
  $p =~ s/$/.pm/;
  # warn "inc :".$INC{$p};
  return $INC{$p};
}


=method abs_path_of_sample_mojo_conf

When packaging as module Mojolicious applications that use
L<Mojolicious::Plugin::JSONConfig> or L<Mojolicious::Plugin::Config>
it's needed to create a sample file inside of it

This function accepts package name and return abs_path of attached config file

Developer must place config file in same dir where main module located an call it same as *.pm file NAME

E.g. you have CamshotBot.pm so you must name config as CamshotBot.json.example


=cut


sub abs_path_of_sample_mojo_conf {
  my $package = shift;
  my $pm_location = get_pm_from_mod($package);
  my $app_pm_basename = basename($pm_location);
  my $app_name = $app_pm_basename;
  $app_name =~ s/\.pm//;
  return dirname($pm_location).'/'.$app_name.".json.example";
}

=method first_existing_variable

Return first existing non-empty variable or undef from given array

It's convenient to check ENV variables

Usage

  first_existing_variable(undef, '', 'a')

will return 'a'

=cut

sub first_existing_variable {
  for(@_){ return $_ if $_ }
  # return (grep{$_}@_)[0];
}

=method fev

Alias for first_existing_variable()


=method fef

Alias for first_existing_file()


=cut

*fev = \&first_existing_variable;
*fef = \&first_existing_file;

# sub fev {return first_existing_variable(@_);}


1;
