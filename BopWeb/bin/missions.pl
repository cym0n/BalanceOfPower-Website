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

die "No game!" if ! $game;

my $root_path = "$FindBin::Bin/../lib/../";
my $metadata_path = config->{'metadata_path'} || $root_path . "metadata";
my $metareader = BopWeb::MetaReader->new(path => $metadata_path);
my $travelagent = BopWeb::TravelAgent->new(metareader => $metareader, schema => schema);
my $mercenary = BopWeb::Mercenary->new(metareader => $metareader, schema => schema);


my $file = "$root_path/games/$game.dmp";


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
my @missions = schema->resultset("BopMission")->search({ status => 1, game => $game });
foreach my $m (@missions)
{
    if($m->check($world->current_year, $mercenary) == 0)
    {
        say $m->id . " expired";
    }
}





