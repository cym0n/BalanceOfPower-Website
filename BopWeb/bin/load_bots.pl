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
        $bot->photo($row->[1]);
        $bot->nation($row->[2]);
        $bot->position($row->[3]);
        $bot->update();
    }
    else
    {
        $bot = schema->resultset("BopBot")->create({
                    game => $game,
                    name => $row->[0],
                    photo => $row->[1],
                    nation => $row->[2],
                    position => $row->[3] 
                });
    }
    say $bot->name . " generated";
}
