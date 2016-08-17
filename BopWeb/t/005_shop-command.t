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


### TEST BOOTSTRAP
`cp autotest.sql.freeze autotest.sqlite`;
my $app = BopWeb->to_app;
my $test = Plack::Test->create($app);

### VARIABLES
my $res;
my $player;
my %cargo;
my $hold;

diag("BUY 5 GOODS IN ITALY (GOODS COST: 10)");
$res  = $test->request( POST '/interact/thegame/shop-command', 
                           [command => 'buy', 
                            type => 'goods', 
                            quantity => 5] );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/shop?shop-posted=ok', 'Redirect is correct, shop-posted=ok');
$player = schema->resultset('BopPlayer')->find({ id => 1000 });
%cargo = $player->cargo_status([ 'goods' ]);
$hold = $player->get_hold('goods');
is($cargo{'goods'}, 5, "5 units of goods in the hold");
is($cargo{'free'}, 495, "495 free space in the hold");
is($player->money, 950, "Money of player is now 950");
is($hold->{price}, 10, "Price is 10");
is($hold->{stat}, 40, "Stat is 40");
is($hold->{used}, 1, "Goods is used");

$player->reset_used(); #Reset used to allow next test

diag("BUY 10 MORE GOODS IN ITALY (GOODS COST: 10)");
$res  = $test->request( POST '/interact/thegame/shop-command', 
                           [command => 'buy', 
                            type => 'goods', 
                            quantity => 10] );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/shop?shop-posted=ok', 'Redirect is correct, shop-posted=ok');
$player = schema->resultset('BopPlayer')->find({ id => 1000 });
%cargo = $player->cargo_status([ 'goods' ]);
$hold = $player->get_hold('goods');
is($cargo{'goods'}, 15, "15 units of goods in the hold");
is($cargo{'free'}, 485, "485 free space in the hold");
is($player->money, 850, "Money of player is now 850");
is($hold->{price}, 10, "Price is 10");
is($hold->{stat}, 40, "Stat is 40");
is($hold->{used}, 1, "Goods is used");

$player->reset_used(); #Reset used to allow next test

diag("SELL 5 GOODS IN ITALY (GOODS COST: 10)");
$res  = $test->request( POST '/interact/thegame/shop-command', 
                           [command => 'sell', 
                            type => 'goods', 
                            quantity => 5] );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/shop?shop-posted=ok', 'Redirect is correct, shop-posted=ok');
$player = schema->resultset('BopPlayer')->find({ id => 1000 });
%cargo = $player->cargo_status([ 'goods' ]);
$hold = $player->get_hold('goods');
is($cargo{'goods'}, 10, "10 units of goods in the hold");
is($cargo{'free'}, 490, "490 free space in the hold");
is($player->money, 900, "Money of player is now 900");
is($hold->{price}, 10, "Price is 10");
is($hold->{stat}, 40, "Stat is 40");
is($hold->{used}, 1, "Goods is used");

$player->reset_used(); #Reset used to allow next test

diag("SELL 5 GOODS IN ITALY ON BLACK MARKET (GOODS COST: 10 + 10% = 11)");
$res  = $test->request( POST '/interact/thegame/shop-command', 
                           [command => 'sell', 
                            type => 'goods', 
                            quantity => 5,
                            bm => 1] );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/shop?shop-posted=ok', 'Redirect is correct, shop-posted=ok');
$player = schema->resultset('BopPlayer')->find({ id => 1000 });
%cargo = $player->cargo_status([ 'goods' ]);
$hold = $player->get_hold('goods');
is($cargo{'goods'}, 5, "5 units of goods in the hold");
is($cargo{'free'}, 495, "495 free space in the hold");
is($player->money, 955, "Money of player is now 955");
is($player->get_friendship('Italy'), 45, "Friendship with Italy is now 45");
is($hold->{price}, 10, "Price is 10");
is($hold->{stat}, 40, "Stat is 40");
is($hold->{used}, 1, "Goods is used");

$player->reset_used(); #Reset used to allow next test

diag("BUY 5 GOODS IN FRANCE (GOODS COST: 20)");
$player->position("France");
$player->update;
$res  = $test->request( POST '/interact/thegame/shop-command', 
                           [command => 'buy', 
                            type => 'goods', 
                            quantity => 5] );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/shop?shop-posted=ok', 'Redirect is correct, shop-posted=ok');
$player = schema->resultset('BopPlayer')->find({ id => 1000 });
%cargo = $player->cargo_status([ 'goods' ]);
$hold = $player->get_hold('goods');
is($cargo{'goods'}, 10, "10 units of goods in the hold");
is($cargo{'free'}, 490, "490 free space in the hold");
is($player->money, 855, "Money of player is now 855");
is($hold->{price}, 15, "Price is 15");
is($hold->{stat}, 35, "Stat is 35");
is($hold->{used}, 1, "Goods is used");

$player->reset_used(); #Reset used to allow next test
$player->position("Italy"); #undo scenario
$player->update;

diag("ERRORS: no-input");
$res  = $test->request( POST '/interact/thegame/shop-command', 
                           [command => 'sell', 
                            quantity => 5] );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/shop?shop-posted=ko&err=no-input', 'Redirect is correct, shop-posted=ko err=no-input');

diag("ERRORS: not-owned");
$res  = $test->request( POST '/interact/thegame/shop-command', 
                           [command => 'sell', 
                            type => 'luxury',
                            quantity => 5] );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/shop?shop-posted=ko&err=not-owned', 'Redirect is correct, shop-posted=ko err=not-owned');

diag("ERRORS: hate");
$player = schema->resultset('BopPlayer')->find({ id => 1000 });
$player->add_friendship("Italy", -40);
$res  = $test->request( POST '/interact/thegame/shop-command', 
                           [command => 'buy', 
                            type => 'luxury',
                            quantity => 5] );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/shop?shop-posted=ko&err=hate', 'Redirect is correct, shop-posted=ko err=hate');
$player->add_friendship("Italy", 40); #undo scenario

diag("ERRORS: no-money");
$res  = $test->request( POST '/interact/thegame/shop-command', 
                           [command => 'buy', 
                            type => 'goods',
                            quantity => 105] );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/shop?shop-posted=ko&err=no-money', 'Redirect is correct, shop-posted=ko err=no-money');

diag("ERRORS: no-space");
$player = schema->resultset('BopPlayer')->find({ id => 1000 });
$player->add_cargo('tech', 500);
$res  = $test->request( POST '/interact/thegame/shop-command', 
                           [command => 'buy', 
                            type => 'luxury',
                            quantity => 5] );
is($res->code, 302, "API redirection");
is($res->header('location'), 'http://localhost/play/thegame/i/shop?shop-posted=ko&err=no-space', 'Redirect is correct, shop-posted=ko err=no-space');
$player->add_cargo('tech', -500); #undo scenario















done_testing();
