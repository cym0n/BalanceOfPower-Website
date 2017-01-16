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

diag("ERROR: wrong position");
$res  = $test->request( GET '/interact/thegame/bot-command?bot=2&command=cure' );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/lounge?bot-command-posted=ko&err=bad-position', 'Redirect is correct, bot-command-posted=ko err=bad-position');

diag("ERROR: wrong bot");
$res  = $test->request( GET '/interact/thegame/bot-command?bot=1&command=cure' );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/lounge?bot-command-posted=ko&err=bad-bot', 'Redirect is correct, bot-command-posted=ko err=bad-bot');

diag("ERROR: no money");
$player = schema->resultset('BopPlayer')->find({ id => 1000});
$player->money(50);
$player->position('Zaire');
$player->update;
$res  = $test->request( GET '/interact/thegame/bot-command?bot=2&command=cure' );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/lounge?bot-command-posted=ko&err=not-enough-money', 'Redirect is correct, bot-command-posted=ko err=not-enough-money');

diag("ERROR: no money");
$player = schema->resultset('BopPlayer')->find({ id => 1000});
$player->money(1000);
$player->update;
$res  = $test->request( GET '/interact/thegame/bot-command?bot=2&command=cure' );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/lounge?bot-command-posted=ko&err=useless-command', 'Redirect is correct, bot-command-posted=ko err=useless-command');

diag("Cure");
$player = schema->resultset('BopPlayer')->find({ id => 1000});
$player->health(1);
$player->update;
$res  = $test->request( GET '/interact/thegame/bot-command?bot=2&command=cure' );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/lounge?bot-command-posted=ok&err=cure', 'Redirect is correct, bot-command-posted=ok err=cure');
$player = schema->resultset('BopPlayer')->find({ id => 1000});
is($player->money, 900, "Player paied 100");
is($player->health, 5, "Player's health restored");






done_testing();



