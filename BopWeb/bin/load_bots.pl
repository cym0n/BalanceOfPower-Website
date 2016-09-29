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
#my $site_root = $ENV{'BOP_SITE_ROOT'};
#my $gamefile = "$site_root/games/$game.dmp";
#my $world = BalanceOfPower::World->load_world($file);

die "No game!" if ! $game;

my $inputfile = $ARGV[1];
open(my $input, "< $inputfile") || die "Errors opening $inputfile: $@";

my $csv = Text::CSV->new( { sep_char => ';',
                            allow_whitespace => 1, } );

$csv->getline($input);

say "Loading bots for $game";

while(my $row = $csv->getline($input))
{
    my $bot = schema->resultset("BopBot")->find({ game => $game,
                                                  name => $row->[0] });
    if($bot)
    {
        $bot->class($row->[1]);
        $bot->photo($row->[2]);
        $bot->nation($row->[3]);
        $bot->position($row->[4]);
        $bot->update();
    }
    else
    {
        $bot = schema->resultset("BopBot")->create({
                    game => $game,
                    name => $row->[0],
                    class => $row->[1],
                    photo => $row->[2],
                    nation => $row->[3],
                    position => $row->[4] 
                });
    }
    say $bot->name . " generated";
}
