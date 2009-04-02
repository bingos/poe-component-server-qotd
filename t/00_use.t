use Test::More tests => 1;

BEGIN {
	use_ok( 'POE::Component::Server::Qotd' );
}

diag( "Testing POE::Component::Server::Qotd-$POE::Component::Server::Qotd::VERSION, POE-$POE::VERSION, Perl $], $^X" );
