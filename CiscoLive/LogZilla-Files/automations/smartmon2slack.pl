#!/usr/bin/env perl
# This script will attempt to ssh to the affected host and run
# smartctl -A
# to get more information about the affected disk
# using Smartmontools
# Requires:
# * smartmontools on target server
# * ssh keys between this and the target host (for passwordless logins)
#  - Make sure you can ssh from the logzilla user to root@$raidHost without a password!
#
# for Ubuntu, install using:
# apt install smartmontools
#
my $raidHost=$ENV{'EVENT_HOST'};
my $filename = "/tmp/test.txt";
open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
#-----------------------------------------------------------------------------
# Required modules (install using cpanminus):
# cpanm File::Sync Net::DNS::Resolver JSON HTTP::Request::Common LWP::UserAgent LWP::Protocol::https
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
# Currently, LogZilla passes the following:
#-----------------------------------------------------------------------------
# EVENT_COUNTER=<integer>
# EVENT_CISCO_MNEMONIC=<string>
# EVENT_STATUS=<integer>
# EVENT_ID=<integer>
# EVENT_SEVERITY=<integer>
# EVENT_FACILITY=<integer>
# EVENT_HOST=<string>
# EVENT_FIRST_OCCURRENCE=<float>
# EVENT_SNARE_ID=<integer>
# EVENT_PROGRAM=<string>
# EVENT_LAST_OCCURRENCE=<float>
# EVENT_MESSAGE=<string>
# EVENT_TRIGGER_ID=<integer>


#-----------------------------------------------------------------------------
# Change these values to match your setup:
#-----------------------------------------------------------------------------
# You will need to obtain your webhook URL from the slack admin interface
my $posturl = 'https://hooks.slack.com/services/XXXXXXXXX/XXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXX';
my $default_channel = '#rawr';
my $slack_user = 'logzilla-bot';

use strict;

use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use JSON;
use Getopt::Std;

=pod
=head1 lz2slack

Post a LogZila notificaion message to a channel in a slack.com group using the
"Incoming Webhooks" integration.

To configure Slack, you need to enable the Incoming Webhooks
integration. The posturl variable at the top of this script needs to
be set to the token from that integration

=cut



# Sample EVENT_MESSAGE:
# Device: /dev/bus/0 [megaraid_disk_04] [SAT], SMART Usage Attribute: 195 Hardware_ECC_Recovered changed from 119 to 120
#$ENV{'EVENT_MESSAGE'} = "Device: /dev/bus/4 [megaraid_disk_28], SMART Failure: FAILURE PREDICTION THRESHOLD EXCEEDED";
my ($device, $disk, $errormsg);
my @megaOutput;
if ($ENV{'EVENT_MESSAGE'} =~ /Device:\s+(\S+)\s+\[megaraid_disk_(\d+)\],?\s+?(.*)/) {
    $device = $1;
    $disk = $2;
    $errormsg = $3;
    print $fh "Device: $device\n";
    print $fh "Disk $disk\n";
    @megaOutput = qx(ssh root\@bfs.lzil.la /usr/sbin/smartctl -A $device -d megaraid,$disk 2>&1);
}

# Testing - output to file to see if the event is being passed
#my $vars;
#foreach my $key (sort keys(%ENV)) {
#next if $key !~ /^EVENT|^TRIGGER/;
#$vars .= "$key = $ENV{$key}\n";
#}

#print $fh "$vars\n";
#print $fh "Running Remote Command:\nssh root\@bfs.lzil.la /usr/sbin/smartctl -A $device -d megaraid,$disk\n";
#print $fh "MegaOutput: @megaOutput\n";

my $i=1;
my $megaText;
for my $v (@megaOutput) {
    chomp $v;
    $megaText .= "    $v\n";
#    print $fh $megaText;
}
close $fh;

my $payload = {
    username => $slack_user,
    channel => $default_channel,
    icon_url => "http://www.logzilla.net/images/logo_orange_png_cropped_40x40.png",
    attachments => [{
            fallback => "S.M.A.R.T. Raid Disk Error",
            title => 'S.M.A.R.T. Raid Disk Error',
            color => '#9C1A22',
            pretext => "$errormsg",
            author_name => "$ENV{'EVENT_HOST'}",
            author_link => "http://$ENV{'EVENT_HOST'}",
            author_icon => "http://www.logzilla.net/images/log_file_icon_25x25.png",
            fields => [{
                    title => 'Program',
                    value => "$ENV{'EVENT_PROGRAM'}",
                    short => 'true',
                }, {
                    title => 'Severity',
                    value => "$ENV{'EVENT_SEVERITY'}",
                    short => 'true',
                }],
            mrkdwn_in => ["text", "fields"],
            text => "```$megaText```",
            thumb_url => "http://www.logzilla.net/images/icon_warning_25x25.png",
        }]
};

my $ua = LWP::UserAgent->new;
$ua->timeout(15);

my $req = POST("${posturl}", ['payload' => encode_json($payload)]);


my $resp = $ua->request($req);

if ($resp->is_success) {
    #print $resp->decoded_content;
}
else {
    die $resp->status_line;
}
exit(0);

=pod

=head1 COPYRIGHT

Copyright LogZilla Corporation

=cut
