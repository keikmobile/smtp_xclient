use strict;
use warnings;
use Test::More;
use IO::Socket::INET;

my $SMTPHOST='127.0.0.1';
my $SMTPPORT=20025;

use_ok 'smtp_xclient';
system("smtp-sink $SMTPHOST:$SMTPPORT 5 &");
sleep 1;

my $smtp = SMTPClient->new();
isa_ok($smtp, 'SMTPClient' );
like($smtp->connect_serv($SMTPHOST,$SMTPPORT), '/220/' ,'Connect SMTP server');

system("pkill -u $ENV{USER} smtp-sink");

done_testing();
