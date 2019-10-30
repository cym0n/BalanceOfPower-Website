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

diag("ERROR: no war to leave");
$res  = $test->request( GET '/interact/thegame/leave-army-command' );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/network?leave-army-posted=ko&err=no-war&active-tab=mercenary', 'Redirect is correct, leave-army-posted=ko err=no-war');

diag("ERROR: wrong-position");
$res  = $test->request( POST '/interact/thegame/join-army-command', 
                           [position => 'Brazil',
                            join => 'Brazil',
                            role => 'defender'] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/network?join-army-posted=ko&err=wrong-position&active-tab=mercenary', 'Redirect is correct, join-army-posted=ko err=wrong-position');

$player = schema->resultset('BopPlayer')->find({ id => 1000});
$player->health(1);
$player->position('Brazil');
$player->update;



diag("ERROR: unable to fight, low health");
$res  = $test->request( POST '/interact/thegame/join-army-command', 
                           [position => 'Brazil',
                            join => 'Brazil',
                            role => 'defender'] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/network?join-army-posted=ko&err=unable-to-fight&active-tab=mercenary', 'Redirect is correct, join-army-posted=ko err=unable-to-fight');

$player->health(4);
$player->update;

diag("ERROR: invalid nation");
$res  = $test->request( POST '/interact/thegame/join-army-command', 
                           [position => 'Brazil',
                            join => 'Brazil',
                            role => 'invader'] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/network?join-army-posted=ko&err=invalid-nation&active-tab=mercenary', 'Redirect is correct, join-army-posted=ko err=invalid-nation');


diag("Joining Brazil");
$res  = $test->request( POST '/interact/thegame/join-army-command', 
                           [position => 'Brazil',
                            join => 'Brazil',
                            role => 'defender'] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/network?join-army-posted=ok&err=Brazil&active-tab=mercenary', 'Redirect is correct, join-army-posted=ok Brazil army joined');

$player = schema->resultset('BopPlayer')->find({ id => 1000});
is($player->joined_army, 'Brazil', "Player joined Brazil");

diag("ERROR: army already joined");
$res  = $test->request( POST '/interact/thegame/join-army-command', 
                           [position => 'Brazil',
                            join => 'Vietnam',
                            role => 'invader'] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/network?join-army-posted=ko&err=already&active-tab=mercenary', 'Redirect is correct, join-army-posted=ko err=already');


diag("ERROR: can't leave too early");
$res  = $test->request( GET '/interact/thegame/leave-army-command' );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/network?leave-army-posted=ko&err=not-enough-time&active-tab=mercenary', 'Redirect is correct, leave-army-posted=ko err=not-enough-time');


$player = schema->resultset('BopPlayer')->find({ id => 1000});
$player->fight_start(DateTime->now->subtract( hours => 2));
$player->update;

diag("Leaving war");
$res  = $test->request( GET '/interact/thegame/leave-army-command' );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/network?leave-army-posted=ok&active-tab=mercenary', 'Redirect is correct, leave-army-posted=ok');

$player = schema->resultset('BopPlayer')->find({ id => 1000});
is($player->joined_army, undef, "Player is not fighting");
is($player->get_friendship('Brazil'), 53, "Brazil friendship is now 53");
is($player->get_friendship('Vietnam'), 48, "Vietnam friendship is now 48");
is($player->get_friendship('Thailand'), 48, "Thailand friendship is now 48");
is($player->get_friendship('Poland'), 50, "Poland friendship not changed");








done_testing();
