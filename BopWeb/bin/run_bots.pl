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
say "Metadata path: $metadata_path";
my $metareader = BopWeb::MetaReader->new(path => $metadata_path);
my $travelagent = BopWeb::TravelAgent->new(metareader => $metareader);

my @bots = schema->resultset("BopBot")->search({ game => $game });

foreach my $bot (@bots)
{
    if($bot->destination && $travelagent->finished_travel($bot))
    {
        $travelagent->arrive($bot);
        say $bot->name . " arrived in " . $bot->position;
    }
    else
    {
        if($travelagent->enabled_to_travel($bot) && $travelagent->go_random($game, $bot))
        {
            say $bot->name . " started a travel to " . $bot->destination;
        }
        else
        {
            say $bot->name . " do nothing";
        }
    }
}
