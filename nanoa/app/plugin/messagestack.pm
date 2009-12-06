package plugin::messagestack;

use strict;
use warnings;
use utf8;

use base qw(NanoA::Plugin);
use plugin::session;

sub _filter_message {
	my $message_hashref = shift;
	my $limiting_params = shift;
	# check scope
	if ($limiting_params->{'-scope'}) {
		if ($message_hashref->{'-scope'}) {
			my @scopes = ref($message_hashref->{'-scope'}) ? @$message_hashref->{'-scope'} : ($message_hashref->{'-scope'});
			my $scope_match = (grep { $_ eq $limiting_params->{'-scope'} } @scopes);
			return unless ($scope_match);
		}
	}
	# check classification
	if ($limiting_params->{'-classification'}) {
		return unless ($message_hashref->{'-classification'} eq $limiting_params->{'-classification'});
	}
	return 1;
}

sub init_plugin {
	my ($klass, $controller) = @_;
	plugin::session->init_plugin($controller);
	no strict 'refs';
	no warnings 'redefine';

	*{$controller . '::push_message'} = sub {
		my $app = shift;
		my $session = $app->session;
		my $message_hash = { @_ };
		if (not (grep { /^-/ } @_) && @_) {
			$message_hash = { -message => shift };
			$message_hash->{'-classification'} = shift || 'INFO';
			$message_hash->{'-scope'} = shift if (@_);
		}
		my $message_array = $session->get( '__nanoa_messagestack_stack' ) || [];
		push @$message_array, $message_hash;
		$session->set( '__nanoa_messagestack_stack' => $message_array );
	};

	*{$controller . '::message_stack'} = sub {
		my $app = shift;
		my $session = $app->session;
		my %limiting_params = @_;
		my $message_array = $session->get( '__nanoa_messagestack_stack' ) || [];
		my @messages = grep { plugin::messagestack::_filter_message( $_, \%limiting_params ) } @{$message_array};
		return [@messages];
	};

	*{$controller . '::pop_message'} = sub {
		my $app = shift;
		my $session = $app->session;
		my %limiting_params = @_;
		my $message = undef;
		my $message_array = $session->get( '__nanoa_messagestack_stack' );

		for (my $index = $#{$message_array}; $index--; $index >= 0) {
			my $message_hashref = $message_array->[$index];
			if (plugin::messagestack::_filter_message($message_hashref, \%limiting_params)) {
				$message = $message_hashref->{'-message'} || '';
				splice( @$message_array, $index, 1 );
				last;
			}
		}
		return $message;
	};

	*{$controller . '::clear_messages'} = sub {
		my $app = shift;
		my $session = $app->session;
		my %limiting_params = @_;

		if (not $limiting_params{'-scope'} && not $limiting_params{'-classification'}) {
			$session->remove( '__nanoa_messagestack_stack' );
			return;
		}

		my $message_array = $session->get( '__nanoa_messagestack_stack' );
		for (my $index = $#{$message_array}; $index--; $index >= 0) {
			my $message_hashref = $message_array->[$index];
			plugin::messagestack::_filter_message($message_hashref, \%limiting_params) || next;
			if (plugin::messagestack::_filter_message($message_hashref, \%limiting_params)) {
				splice( @$message_array, $index, 1 );
			}
		}
		$session->remove( '__nanoa_messagestack_stack' ) if (scalar(@{$message_array}) == 0);
	};
}

__PACKAGE__->init_plugin(__PACKAGE__);

1;
