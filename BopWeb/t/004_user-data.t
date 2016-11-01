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

`cp autotest.sql.freeze autotest.sqlite`;

my $app = BopWeb->to_app;
my $test = Plack::Test->create($app);
my $res  = $test->request( POST '/api/thegame/user-data', [player => 'user1', password => 'thegame', money => 500, position => 'Romania'] );
is($res->content, 'OK', "API answered OK");

my $user1 = schema->resultset("BopPlayer")->find(1000);
is($user1->money, 500, "User1 money changed to 500");

$res  = $test->request( POST '/api/thegame/user-data', [player => 'baduser1', password => 'thegame', money => 500, position => 'Romania'] );
is($res->code, 400, "Bad user provided");

$res  = $test->request( POST '/api/thegame/user-data', [player => 'user3', password => 'thegame', money => 750, position => 'Greece'] );
is($res->code, 200, "User update done");

my $usergame3 = schema->resultset("UserGame")->find({ user => 1002, game => 1000 });
is($usergame3->player->id, 1002, "New row on player created");
my $player3 = schema->resultset("BopPlayer")->find(1002);
is($player3->money, 750, "User3 money is 750");
is($player3->position, 'Greece', "User3 position is Greece");

done_testing();
