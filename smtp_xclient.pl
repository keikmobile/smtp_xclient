#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);
use FindBin;
use IO::Socket;

my $smtphost = '127.0.0.1';
my $smtpport = 25;
my $help;

#------------------------------------------------------------------------------
# SMTP
#------------------------------------------------------------------------------
package SMTPClient;
sub new {
    my ( $class, @args ) = @_;
    my %args = ref $args[0] eq 'HASH' ? %{ $args[0] } : @args;
    bless {
        sock        => undef,
        res_reg     => qr{^[2-5][0-9][0-9][ ].+}x,
        host        => '',
        port        => '',
        %args,
    }, $class;
}

sub sock {
    my ($self, $sock) = @_;
    if ($sock) {
        $self->{sock} = $sock;
    }
    return $self->{sock};
}

sub res_reg {
    my ($self) = @_;
    return $self->{res_reg};
}

sub recv_res {
    my ( $self ) = @_;
    if ( defined $self->sock ) {
      my $line;
      my $buf;
      do {
         $line = $self->sock->getline or die print "Error: $!";
         $buf .= $line;
      } until ( $line =~ $self->res_reg );
      return $buf;
    }
}

sub connect_serv {
  my ( $self, $host, $port ) = @_;
  my $buf = '';
  $self->sock( 
    IO::Socket::INET->new(
      PeerAddr => $host,
      PeerPort => $port,
      Proto    => 'tcp',
      Blocking => 1,
    ) or die print "Error: Can't create a socket $host $port."
  );
  $buf .= $self->recv_res();
  return $buf;
}

sub send_line {
    my ( $self, $line ) = @_;
    if ( defined $self->sock ) {
      $self->sock->printflush($line . "\r\n");
    }
    return $line . "\r\n";
}

sub send_cmd {
    my ( $self, $cmd ) = @_;
    my $buf = '';
    $buf .= $self->send_line($cmd);
    $buf .= $self->recv_res();
    return $buf;
}

1;


package main;

#------------------------------------------------------------------------------
# USAGE
#------------------------------------------------------------------------------
sub usage {
    print <<"USAGE";
Usage: $0 [options] 
[smtp options]
--host                : smtphost : $smtphost
--port                : smtpport : $smtphost
--help                : help
USAGE
    exit 1;
}

#------------------------------------------------------------------------------
# OPTION
#------------------------------------------------------------------------------
sub set_opt {
    GetOptions(
        'host=s' => \$smtphost,
        'port=i' => \$smtpport,
        'help' => \$help,
    );
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------


$SIG{INT} = sub { exit };


if (__FILE__ eq $0){
  set_opt();
  if ($help) { usage; }
  my $smtp = SMTPClient->new();
  print $smtp->connect_serv($smtphost,$smtpport);
  print $smtp->send_cmd("EHLO localhost");
  print $smtp->send_cmd("XCLIENT ADDR=168.100.189.2");
  print $smtp->send_cmd("MAIL FROM:<>");
  print $smtp->send_cmd("RCPT TO:<vagrant\@localhost>");
  print $smtp->send_cmd("DATA");
  print $smtp->send_line("TEST MESSAGE");
  print $smtp->send_cmd(".");
  print $smtp->send_cmd("QUIT");
}
