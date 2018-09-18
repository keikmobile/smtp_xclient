use strict;
use warnings;
use Test::More;
use IO::Socket::INET;

my $SMTPHOST='127.0.0.1';
my $SMTPPORT=20025;

use_ok 'smtp_xclient';
system("smtp-sink -f CONNECT $SMTPHOST:$SMTPPORT 5 &");
#       -f command,command,...
#              Reject the specified commands with a hard (5xx) error code.  This option implies -p.
#              Examples of commands are CONNECT, HELO, EHLO, LHLO, MAIL, RCPT, VRFY, DATA, ., RSET,  NOOP,  and  QUIT.  Separate
#              command  names  by white space or commas, and use quotes to protect white space from the shell. Command names are
#              case-insensitive.
sleep 1;

my $smtp = SMTPClient->new();
isa_ok($smtp, 'SMTPClient' );
like($smtp->connect_serv($SMTPHOST,$SMTPPORT), '/500 /' ,'Connect SMTP server');
like($smtp->cmd_helo('localhost'), '/HELO[ ].+\r\n250/' ,"HELO command");
like($smtp->cmd_ehlo('localhost'), '/EHLO[ ].+\r\n250/' ,"EHLO command");
like($smtp->cmd_mailfrom('localhost@localhost'), '/MAIL FROM:.+\r\n250/' ,"MAIL FROM command");
like($smtp->cmd_rcptto('localhost@localhost'), '/RCPT TO:.+\r\n250/' ,"MAIL FROM command");
like($smtp->cmd_data('TEST Message'), '/DATA\r\n354/' ,"DATA command");
like($smtp->cmd_quit(),  '/QUIT\r\n221/' ,'QUIT and Close connection');

END {
  system("pkill -u $ENV{USER} smtp-sink");
}

done_testing();
