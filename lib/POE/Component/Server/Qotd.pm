# $Id: Qotd.pm,v 1.1.1.1 2005/01/27 14:15:42 chris Exp $
#
# POE::Component::Server::Echo, by Chris 'BinGOs' Williams <chris@bingosnet.co.uk>
#
# This module may be used, modified, and distributed under the same
# terms as Perl itself. Please see the license that came with your Perl
# distribution for details.
#

package POE::Component::Server::Qotd;

#ABSTRACT: A POE component that implements an RFC 865 QotD server.

use strict;
use warnings;
use Carp;
use POE;
use Socket;
use base qw(POE::Component::Server::Echo);

use constant DATAGRAM_MAXLEN => 1024;
use constant DEFAULT_PORT => 17;

sub spawn {
  my $package = shift;
  croak "$package requires an even number of parameters" if @_ & 1;

  my %parms = @_;

  $parms{'Alias'} = 'Qotd-Server' unless defined $parms{'Alias'} and $parms{'Alias'};
  $parms{'tcp'} = 1 unless defined $parms{'tcp'} and $parms{'tcp'} == 0;
  $parms{'udp'} = 1 unless defined $parms{'udp'} and $parms{'udp'} == 0;
  $parms{'Quote'} = 'Parts that positively cannot be assembled in improper order will be.'
	unless defined $parms{'Quote'} and length $parms{'Quote'} <= 512;

  my $self = bless { }, $package;

  $self->{CONFIG} = \%parms;

  POE::Session->create(
        object_states => [
                $self => { _start => '_server_start',
                           _stop  => '_server_stop',
                           shutdown => '_server_close' },
                $self => [ qw(_accept_new_client _accept_failed _client_input _client_error _client_flushed _get_datagram) ],
                          ],
        ( ref $parms{'options'} eq 'HASH' ? ( options => $parms{'options'} ) : () ),
  );

  return $self;
}

sub _accept_new_client {
  my ($kernel,$self,$socket,$peeraddr,$peerport,$wheel_id) = @_[KERNEL,OBJECT,ARG0 .. ARG3];
  $peeraddr = inet_ntoa($peeraddr);

  my $wheel = POE::Wheel::ReadWrite->new (
        Handle => $socket,
        Filter => POE::Filter::Line->new(),
        InputEvent => '_client_input',
        ErrorEvent => '_client_error',
	FlushedEvent => '_client_flushed',
  );

  $self->{Clients}->{ $wheel->ID() } = { Wheel => $wheel, peeraddr => $peeraddr, peerport => $peerport };
  $wheel->put( $self->{CONFIG}->{Quote} );
  undef;
}

sub _client_input {
  undef;
}

sub _client_flushed {
  my ($kernel,$self,$wheel_id) = @_[KERNEL,OBJECT,ARG0];
  delete $self->{Clients}->{ $wheel_id }->{Wheel};
  delete $self->{Clients}->{ $wheel_id };
  undef;
}

sub _get_datagram {
  my ( $kernel, $self, $socket ) = @_[ KERNEL, OBJECT, ARG0 ];

  my $remote_address = recv( $socket, my $message = "", DATAGRAM_MAXLEN, 0 );
    return unless defined $remote_address;

  send( $socket, $self->{CONFIG}->{Quote}, 0, $remote_address ) == length( $self->{CONFIG}->{Quote} )
      or warn "Trouble sending response: $!";
  undef;
}

qq[What is the frequency, Kenneth?];

=pod

=head1 SYNOPSIS

 use POE::Component::Server::Qotd;

 my $self = POE::Component::Server::Qotd->spawn( 
	Alias => 'Chargen-Server',
	BindAddress => '127.0.0.1',
	BindPort => 7777,
	options => { trace => 1 },
 );

=head1 DESCRIPTION

POE::Component::Server::Chargen implements a RFC 865 L<http://www.faqs.org/rfcs/rfc865.html> TCP/UDP QotD server, using
L<POE>. It is a class inherited from L<POE::Component::Server::Echo>.

=head1 METHODS

=over

=item C<spawn>

Takes a number of optional values:

  "Alias", the kernel alias that this component is to be blessed with; 
  "BindAddress", the address on the local host to bind to, defaults to 
                 POE::Wheel::SocketFactory default; 
  "BindPort", the local port that we wish to listen on for requests, 
	      defaults to 19 as per RFC, this will require "root" privs on UN*X; 
  "options", should be a hashref, containing the options for the component's session, 
             see POE::Session for more details on what this should contain; 
  "Quote", text to be sent to connecting clients, default quote is applied if this 
           is not supplied or is greater than 512 characters.

=back

=head1 BUGS

Report any bugs through L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<POE>

L<POE::Session>

L<POE::Wheel::SocketFactory>

L<POE::Component::Server::Echo>

L<http://www.faqs.org/rfcs/rfc865.html>

=cut
