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

#Missions in test env
#18|parcel||1987/3|1|0|{"assignment":"Italy","from":"Chile","to":"Indonesia"}|{"money":100,"friendship":{"assignment":3,"from":-2,"to":1}}|Italy
#19|parcel||1987/3|1|0|{"assignment":"Pakistan","from":"France","to":"USA"}|{"money":100,"friendship":{"assignment":3,"from":-2,"to":1}}|Pakistan


my $res;
my $mission;
my $player;

my $good_mission = 18;
my $second_mission = 19;

diag("Accept mission");
$res  = $test->request( POST '/interact/thegame/mission-command', 
                           [command => 'accept', mission => $good_mission] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/network?mission-posted=ok&err=accepted&showme=18&active-tab=mymissions', 'Redirect is correct, mission-posted=ok err=accepted');
$mission = schema->resultset('BopMission')->find({ id => $good_mission });
is($mission->assigned, 1000, "Mission is assigned to user1");

diag("ERROR: not-owned");
$res  = $test->request( POST '/interact/thegame/mission-command', 
                           [command => 'action', mission => $second_mission] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/network?mission-posted=ko&err=not-owned', 'Redirect is correct, mission-posted=ko err=not-owned');

diag("ERROR: action-not-available");
$res  = $test->request( POST '/interact/thegame/mission-command', 
                           [command => 'action', mission => $good_mission] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/network?mission-posted=ko&err=action-not-available', 'Redirect is correct, mission-posted=ko err=action-not-available');

diag("Progress");
$player = schema->resultset('BopPlayer')->find({ id => 1000});
$player->position('Chile');
$player->update;
$res  = $test->request( POST '/interact/thegame/mission-command', 
                           [command => 'action', mission => $good_mission] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/network?mission-posted=ok&err=action-done&showme=18&active-tab=mymissions', 'Redirect is correct, mission-posted=ok err=action-done');
$mission = schema->resultset('BopMission')->find({ id => $good_mission });
is($mission->progress, 1, "Mission progressed");

diag("ERROR: action-not-available");
$res  = $test->request( POST '/interact/thegame/mission-command', 
                           [command => 'action', mission => $good_mission] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/network?mission-posted=ko&err=action-not-available', 'Redirect is correct, mission-posted=ko err=action-not-available');

diag("Progress and success");
$player = schema->resultset('BopPlayer')->find({ id => 1000});
$player->position('Indonesia');
$player->update;
$res  = $test->request( POST '/interact/thegame/mission-command', 
                           [command => 'action', mission => $good_mission] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), "http://localhost/play/thegame/i/accomplished?mission=$good_mission", 'Redirect is correct, mission-posted=ok err=action-done');
$mission = schema->resultset('BopMission')->find({ id => $good_mission });
is($mission->progress, 2, "Mission progressed");
is($mission->status, 2, "Mission accomplished");
$player = schema->resultset('BopPlayer')->find({ id => 1000});
is($player->money, 1100, "100 money earned");
is($player->get_friendship('Italy'), 53, "Italy friendship is now 53");
is($player->get_friendship('Chile'), 48, "Chile friendship is now 48");
is($player->get_friendship('Indonesia'), 51, "Indonesia friendship is now 51");












done_testing();

