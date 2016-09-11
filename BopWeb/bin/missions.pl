#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Dancer2;
use Dancer2::Plugin::DBIC;
use Data::Dumper;

use BopWeb;

use BalanceOfPower::World;
use BalanceOfPower::Constants ":all";

my $game = $ARGV[0];
my $site_root = $ENV{'BOP_SITE_ROOT'};
my $file = "$site_root/games/$game.dmp";


my $world = BalanceOfPower::World->load_world($file);

say "Generating missions for $game (" . $world->current_year . ")";

for(my $i = 0; $i < MISSIONS_TO_GENERATE_PER_TURN; $i++)
{
    my %m = $world->generate_mission('parcel');
    my $config = BopWeb::serialize({ assignment => $m{'assignment'},
                                     from => $m{'from'},
                                     to => $m{'to'} });
    my $reward = BopWeb::serialize($m{'reward'});
    my $mission = schema->resultset("BopMission")->create({
        game => $game,
        assigned => undef,
        type => 'parcel',
        expire_turn => $m{'expire'},
        status => 1,
        configuration => $config,
        reward => $reward,
        location => $m{'assignment'},
        progress => 0
    });
    say "Mission " . $mission->id . " generated";
}

say "Turning off missions for $game expired in " . $world->current_year;
schema->resultset("BopMission")->search({ expire_turn => $world->current_year })->update({ status => 0 });

