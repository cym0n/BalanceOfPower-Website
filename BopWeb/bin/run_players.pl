#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Text::CSV;

use Dancer2;
use Dancer2::Plugin::DBIC;
use BopWeb;

my $game = $ARGV[0];

die "No game!" if ! $game;

my $root_path = "$FindBin::Bin/../lib/../";
my $metadata_path = config->{'metadata_path'} || $root_path . "metadata";
my $metareader = BopWeb::MetaReader->new(path => $metadata_path);
my $travelagent = BopWeb::TravelAgent->new(metareader => $metareader, schema => schema);

my @players = schema->resultset("BopGame")->find({ name => $game })->get_players;

foreach my $p (@players)
{
    #Check arrival of a travel
    eval { $travelagent->arrive($p) };
    if($@)
    {
        if($@ eq 'not-arrived')
        {
        }
        else
        {
            die $@;
        }
    }
    else
    {
        say "Player " . $p->id . " completed a travel";
    }
}

