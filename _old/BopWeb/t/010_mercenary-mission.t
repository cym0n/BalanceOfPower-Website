use strict;
use warnings;
use v5.10;

use lib 'lib';
BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'autotest';
}

use Test::More;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Plack::Test;
use HTTP::Request::Common;
use Data::Dumper;
use BopWeb;
use DateTime;

### TEST BOOTSTRAP
`cp autotest.sql.freeze autotest.sqlite`;
my $app = BopWeb->to_app;
my $test = Plack::Test->create($app);
my $player;
my $res;
my $mission;
my $good_mission = 22;

$player = schema->resultset('BopPlayer')->find({ id => 1000});
$player->position('France');
$player->update;

diag("Accept mission");
$res  = $test->request( POST '/interact/thegame/mission-command', 
                           [command => 'accept', mission => $good_mission] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/network?mission-posted=ok&err=accepted&showme=22&active-tab=mymissions', 'Redirect is correct, mission-posted=ok err=accepted');
$mission = schema->resultset('BopMission')->find({ id => $good_mission });
is($mission->assigned, 1000, "Mission is assigned to user1");

diag("Joining Vietnam");
$player = schema->resultset('BopPlayer')->find({ id => 1000});
$player->position('Brazil');
$player->update;
$res  = $test->request( POST '/interact/thegame/join-army-command', 
                           [position => 'Brazil',
                            join => 'Vietnam',
                            role => 'invader'] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/network?join-army-posted=ok&err=Vietnam&active-tab=mercenary', 'Redirect is correct, join-army-posted=ok Vietnam army joined');
$mission = schema->resultset('BopMission')->find({ id => $good_mission });
is($mission->progress, 1, "Mission progressed");
is($mission->status, 2, "Mission accomplished");
$player = schema->resultset('BopPlayer')->find({ id => 1000});
is($player->money, 1100, "100 money earned");
is($player->get_friendship('France'), 53, "France friendship is now 53");

done_testing();

