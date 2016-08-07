use strict;
use warnings;
use v5.10;

use lib 'lib';

use Test::More;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Plack::Test;
use HTTP::Request::Common;
use Data::Dumper;
use BopWeb;

`cp autotest.sql.freeze autotest.sqlite`;
BopWeb->config->{'plugins'}->{'DBIC'}->{'default'}->{'dsn'} = 'dbi:SQLite:dbname=autotest.sqlite' ;

my $app = BopWeb->to_app;
my $test = Plack::Test->create($app);
my $res  = $test->request( POST '/api/thegame/user-data', [player => 'user1', password => 'thegame', money => 500] );
is($res->content, 'OK', "API answered OK");

my $user1 = schema->resultset("BopPlayer")->find(1000);
is($user1->money, 500, "User1 money changed to 500");

done_testing();
