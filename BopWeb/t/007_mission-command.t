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

diag("NETWORK PAGE");
$res =$test->request( GET '/play/thegame/i/network' );
is($res->code, 200, "Shop page retrieved");

diag("MY MISSIONS PAGE");
$res =$test->request( GET '/play/thegame/i/mymissions' );
is($res->code, 200, "Shop page retrieved");





done_testing();

