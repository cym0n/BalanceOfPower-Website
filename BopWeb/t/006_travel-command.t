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
my $player;

diag("TRAVEL PAGE");
$res =$test->request( GET '/play/thegame/i/travel' );
is($res->code, 200, "Travel page retrieved");

diag("---- GO ----");
diag("ERROR: not-ready");
$player = schema->resultset('BopPlayer')->find({ id => 1000 });
$player->disembark_time(DateTime->now);
$player->update;
$res  = $test->request( POST '/interact/thegame/go', 
                           [destination => 'Japan'] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/travel?travel-posted=ko&err=not-ready-to-travel', 'Redirect is correct, travel-posted=ko err=not-ready-to-travel');
$player->disembark_time(undef);
$player->update;

diag("ERROR: bad destination");
$res  = $test->request( POST '/interact/thegame/go', 
                           [destination => 'China'] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/travel?travel-posted=ko&err=bad-destination', 'Redirect is correct, travel-posted=ko err=bad-destination');

diag("ERROR: bad destination caused by borderguard bot");
$res  = $test->request( POST '/interact/thegame/go', 
                           [destination => 'Angola'] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/travel?travel-posted=ko&err=bad-destination', 'Redirect is correct, travel-posted=ko err=bad-destination');

diag("Go to Japan");
$res  = $test->request( POST '/interact/thegame/go', 
                           [destination => 'Japan'] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/travel?travel-posted=ok&err=posted', 'Redirect is correct, travel-posted=ok err=post');
$player = schema->resultset('BopPlayer')->find({ id => 1000 });
is($player->destination, 'Japan', "Destionation is Japan");
ok($player->arrival_time, "Arrival time populated");
is($player->disembark_time, undef, "Disembark time is empty");

diag("ERROR: ongoing-travel");
$res  = $test->request( POST '/interact/thegame/go', 
                           [destination => 'Spain'] 
                      );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/travel?travel-posted=ko&err=ongoing-travel', 'Redirect is correct, travel-posted=ko err=ongoing-travel');

diag("---- ARRIVE ----");
diag("ERROR: not-arrived");
$res  = $test->request( GET '/interact/thegame/arrive' );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/travel?travel-posted=ko&err=not-arrived', 'Redirect is correct, travel-posted=ko err=not-arrived');

diag("Arrive");
$player = schema->resultset('BopPlayer')->find({ id => 1000 });
my $good_arrival = DateTime->now;
$good_arrival->subtract( hours => 1);
$player->arrival_time($good_arrival);
$player->update;
$res  = $test->request( GET '/interact/thegame/arrive' );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/travel?travel-posted=ok&err=arrived', 'Redirect is correct, travel-posted=ok err=arrived');
$player = schema->resultset('BopPlayer')->find({ id => 1000 });
is($player->position, 'Japan', "Player is now in Japan");
is($player->arrival_time, undef, "Arrival time is empty");
ok($player->disembark_time, "Disembark time is populated");








done_testing();
