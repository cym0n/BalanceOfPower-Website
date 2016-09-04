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

my $res;
my $mission;
my $player;

#Missions in test env
#18|parcel||1987/3|1|0|{"assignment":"Italy","from":"Chile","to":"Indonesia"}|{"money":100,"friendship":{"assignment":3,"from":-2,"to":1}}|Italy
#19|parcel||1987/3|1|0|{"assignment":"Pakistan","from":"France","to":"USA"}|{"money":100,"friendship":{"assignment":3,"from":-2,"to":1}}|Pakistan
#20|parcel||1982/3|0|0|{"assignment":"Italy","from":"Chile","to":"Indonesia"}|{"money":100,"friendship":{"assignment":3,"from":-2,"to":1}}|Italy
#21|parcel|1001|1987/3|1|0|{"assignment":"China","from":"Taiwan","to":"Japan"}|{"money":100,"friendship":{"assignment":3,"from":-2,"to":1}}|China

my $good_mission = 18;
my $second_mission = 19;
my $expired_mission = 20;
my $owned_mission = 21;

diag("NETWORK PAGE");
$res =$test->request( GET '/play/thegame/i/network' );
is($res->code, 200, "Shop page retrieved");

diag("ERROR: no-input");
$res  = $test->request( POST '/interact/thegame/mission-command', 
                           [command => 'accept'] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/network?mission-posted=ko&err=no-input', 'Redirect is correct, mission-posted=ko err=no-input');

diag("ERROR: bad-command");
$res  = $test->request( POST '/interact/thegame/mission-command', 
                           [command => 'wrong', mission => $good_mission] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/mymissions?mission-posted=ko&err=bad-command', 'Redirect is correct, mission-posted=ko err=bad-command');


diag("ERROR: no-mission");
$res  = $test->request( POST '/interact/thegame/mission-command', 
                           [command => 'accept', mission => 48] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/network?mission-posted=ko&err=no-mission', 'Redirect is correct, mission-posted=ko err=no-mission');

diag("ERROR: bad-mission");
$res  = $test->request( POST '/interact/thegame/mission-command', 
                           [command => 'accept', mission => $expired_mission] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/network?mission-posted=ko&err=bad-mission', 'Redirect is correct, mission-posted=ko err=bad-mission');

diag("ERROR: assigned");
$res  = $test->request( POST '/interact/thegame/mission-command', 
                           [command => 'accept', mission => $owned_mission] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/network?mission-posted=ko&err=assigned', 'Redirect is correct, mission-posted=ko err=assigned');

diag("ERROR: not-here");
$res  = $test->request( POST '/interact/thegame/mission-command', 
                           [command => 'accept', mission => $second_mission] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/network?mission-posted=ko&err=not-here', 'Redirect is correct, mission-posted=ko err=not-here');
$mission = schema->resultset('BopMission')->find({ id => $second_mission });
is($mission->assigned, undef, "Mission not assigned");

diag("Accept mission");
$res  = $test->request( POST '/interact/thegame/mission-command', 
                           [command => 'accept', mission => $good_mission] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/mymissions?mission-posted=ok&err=accepted&showme=18', 'Redirect is correct, mission-posted=ok err=accepted');
$mission = schema->resultset('BopMission')->find({ id => $good_mission });
is($mission->assigned, 1000, "Mission is assigned to user1");

diag("ERROR: missions-limit");
$player = schema->resultset('BopPlayer')->find({ id => 1000});
$player->position('Pakistan');
$player->update;
$res  = $test->request( POST '/interact/thegame/mission-command', 
                           [command => 'accept', mission => $second_mission] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/network?mission-posted=ko&err=missions-limit', 'Redirect is correct, mission-posted=ko err=missions-limit');
$mission = schema->resultset('BopMission')->find({ id => $second_mission });
is($mission->assigned, undef, "Mission not assigned");

diag("ERROR: not-owned");
$res  = $test->request( POST '/interact/thegame/mission-command', 
                           [command => 'drop', mission => $second_mission] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/mymissions?mission-posted=ko&err=not-owned', 'Redirect is correct, mission-posted=ko err=not-owned');

diag("Drop mission");
$res  = $test->request( POST '/interact/thegame/mission-command', 
                           [command => 'drop', mission => $good_mission] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/mymissions?mission-posted=ok&err=dropped', 'Redirect is correct, mission-posted=ok err=dropped');
$mission = schema->resultset('BopMission')->find({ id => $second_mission });
is($mission->assigned, undef, "Mission not assigned");
is($mission->progress, 0, "Progress reset");
$player = schema->resultset('BopPlayer')->find({ id => 1000});
is($player->money, 950, "Player payed the penalty");

diag("MY MISSIONS PAGE");
$res =$test->request( GET '/play/thegame/i/mymissions' );
is($res->code, 200, "Shop page retrieved");





done_testing();

