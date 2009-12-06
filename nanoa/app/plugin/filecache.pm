package plugin::filecache;

use strict;
use warnings;
use utf8;

use base qw(NanoA::Plugin);
use Cache::FileCache;

sub init_plugin {
	my ($klass, $controller) = @_;
	no strict 'refs';
	no warnings 'redefine';

	*{$controller . '::filecache'} = sub {
		my $app = shift;
		my $opts = shift || {};
		$opts->{'cache_root'} ||= join('/', $app->config->data_dir, $app->config->app_name, 'cache');
		$opts->{'namespace'} ||= $app->config->app_name;
		my $cache = new Cache::FileCache($opts);
		return $cache;
	};
}

__PACKAGE__->init_plugin(__PACKAGE__);

1;
