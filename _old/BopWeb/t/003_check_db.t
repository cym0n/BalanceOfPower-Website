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
use Data::Dumper;
use BopWeb;

`cp autotest.sql.freeze autotest.sqlite`;

my $app = BopWeb->to_app;
schema->resultset("BopGame")->create({ name => 'autotest', file => 'autotest', admin_password => 'autotest', active => 1, open => 1 });
my $game = schema->resultset("BopGame")->find({ name => 'autotest' });

ok($game, "A game with name autotest exists");
is($game->id, 1001, "Autotest game has the first ID");

done_testing();


