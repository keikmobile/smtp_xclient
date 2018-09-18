use strict;
use warnings;
use Test::More;
use IO::Socket::INET;

my $SMTPHOST='127.0.0.1';
my $SMTPPORT=20025;
system("smtp-sink $SMTPHOST:$SMTPPORT 5 &");
sleep 1;

use_ok 'smtp_xclient';

my $smtp = SMTPClient->new();
isa_ok($smtp, 'SMTPClient' );
like($smtp->connect_serv($SMTPHOST,$SMTPPORT), '/220/' ,'Connect SMTP server');
like($smtp->cmd_helo('localhost'), '/HELO[ ].+\r\n250/' ,"HELO command");
like($smtp->cmd_ehlo('localhost'), '/EHLO[ ].+\r\n250/' ,"EHLO command");
like($smtp->cmd_mailfrom('localhost@localhost'), '/MAIL FROM:.+\r\n250/' ,"MAIL FROM command");
like($smtp->cmd_rcptto('localhost@localhost'), '/RCPT TO:.+\r\n250/' ,"MAIL FROM command");
like($smtp->cmd_data('TEST Message'), '/DATA\r\n354/' ,"DATA command");
like($smtp->cmd_quit(),  '/QUIT\r\n221/' ,'QUIT and Close connection');

END{
  system("pkill -u $ENV{USER} smtp-sink");
}

done_testing();
