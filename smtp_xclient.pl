#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);
use FindBin;
use IO::Socket;

my $SMTPHOST  = '127.0.0.1';
my $SMTPPORT  = 25;
my $XADDR = undef;
my $XNAME = undef;
my $HELODOMAIN = 'localhost';
my $MAILFROM   = 'localhost@localhost';
my $RCPTTO     = 'localhost@localhost';
my $help = undef;

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
        host        => undef,
        port        => undef,
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

sub cmd_xclient {
    my ( $self, $xaddr , $xname ) = @_;
    my $buf = '';
    my $xclient = "XCLIENT";
    if ($xaddr){ $xclient .= " ADDR=$xaddr" }
    if ($xname){ $xclient .= " NAME=$xname" }
    $buf .= $self->send_cmd($xclient);
    return $buf;
}

sub cmd_help {
    my ( $self, $helodomain ) = @_;
    my $buf = '';
    $buf .= $self->send_cmd("HELO $helodomain");
    return $buf;
}

sub cmd_ehlo {
    my ( $self, $helodomain ) = @_;
    my $buf = '';
    $buf .= $self->send_cmd("EHLO $helodomain");
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
--host                : smtp host : $SMTPHOST
--port                : smtp port : $SMTPHOST
--xaddr               : xclient addr : $XADDR
--xname               : xclient name : $XNAME
--helodomain          : smtp helo domain :  $HELODOMAIN
--help                : help
USAGE
    exit 1;
}

#------------------------------------------------------------------------------
# OPTION
#------------------------------------------------------------------------------
sub set_opt {
    GetOptions(
        'host=s'  =>      \$SMTPHOST,
        'port=i'  =>      \$SMTPPORT,
        'xaddr=s' =>      \$XADDR,
        'xname=s' =>      \$XNAME,
        'helodomain=s' => \$HELODOMAIN,
        'help'    =>      \$help,
    );
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

sub send_message {
  my ($arg_ref) = @_;
  my $host =  $arg_ref->{host}  ? $arg_ref->{host}  : $SMTPHOST;
  my $port =  $arg_ref->{port}  ? $arg_ref->{port}  : $SMTPPORT;
  my $xaddr = $arg_ref->{xaddr} ? $arg_ref->{xaddr} : undef;
  my $xname = $arg_ref->{xname} ? $arg_ref->{xname} : undef;
  my $helodomain = $arg_ref->{helodomain} ? $arg_ref->{helodomain} : $HELODOMAIN;

  my $smtp = SMTPClient->new();
  print $smtp->connect_serv($host,$port);
  if( $xaddr or $xname ){
    print $smtp->cmd_xclient($xaddr,$xname);
  }
  print $smtp->cmd_ehlo("EHLO $helodomain");
  print $smtp->send_cmd("MAIL FROM:<>");
  print $smtp->send_cmd("RCPT TO:<vagrant\@localhost>");
  print $smtp->send_cmd("DATA");
  print $smtp->send_line("TEST MESSAGE");
  print $smtp->send_cmd(".");
  print $smtp->send_cmd("QUIT");
}

$SIG{INT} = sub { exit };

if (__FILE__ eq $0){
  set_opt();
  if ($help) { usage; }
  send_message(
    {
      host => $SMTPHOST,
      port => $SMTPPORT,
      xaddr => $XADDR,
      xname => $XNAME,
      helodomain => $HELODOMAIN
    }
  );
}

1;
