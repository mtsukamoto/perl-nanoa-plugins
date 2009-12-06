package plugin::config;

# This is not my original. Original code is on below url.
# http://d.hatena.ne.jp/khashi/20090901/1251794630

use strict;
use warnings;
use utf8;

use base qw{ NanoA::Plugin };

sub NanoA::conf {
	my $self = shift;

	require YAML;
	$self->{stash}{plugin_conf} ||= YAML::Load(
		$self->config->prefs( $self->config->app_name )
	);

	my $conf = $self->{stash}{plugin_conf};

	return $conf if not @_;
	return $conf->{$_[0]} if @_ == 1;
	return undef;
}

1;
