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
my $travelagent = BopWeb::TravelAgent->new(metareader => $metareader, schema => schema);

my @bots = schema->resultset("BopBot")->search({ game => $game });

foreach my $bot (@bots)
{
    say "Working on " . $bot->name;
    my @log = $bot->action($travelagent);
    for(@log)
    {
        say "  " . $_;
    }
}
