package BopWeb::Mercenary;

use v5.10;
use Moo;

extends 'BopWeb::GamerHandler';

use BalanceOfPower::Dice;
use Data::Dumper;

sub join
{
    my $self = shift;
    my $game = shift;
    my $player = shift;
    my $position = shift;
    my $join = shift;
    my $role = shift;
    die "wrong-position\n" if($position ne $player->position);
    die "already\n" if $player->joined_army;
    die "unable-to-fight\n" if ! $self->able_to_fight($player);

    my $nation_meta = $self->get_nation_meta($game, $player->position);
    die "invalid-nation\n" if($role ne $self->role_in_war($game, $position, $join));
    my $time = DateTime->now;
    $time->set_time_zone('Europe/Rome');
    $player->joined_army($join);
    $player->fight_start($time);
    $player->update;
}

sub able_to_fight
{
    my $self = shift;
    my $player = shift;
    return $player->health >= 3;
}

sub role_in_war
{
    my $self = shift;
    my $game = shift;
    my $position = shift;
    my $nation = shift;
    open(my $log, "> rolelog");
    print {$log} "Calculate role of $nation in $position\n";
    my $nation_meta = $self->get_nation_meta($game, $position);
    print {$log} Dumper($nation_meta);
    close($log);
    if($position eq $nation)
    {
        return 'defender';
    }
    elsif($nation eq $nation_meta->{foreigners}->{supporter})
    {
        return 'supporter';
    }
    elsif(grep { $_ eq $nation} @{$nation_meta->{foreigners}->{invaders}})
    {
        return 'invader';
    }
    else
    {
        return 'none';
    }
    
}

sub war_duration
{
    my $self = shift;
    my $player = shift;
    return 0 if ! $player->joined_army;
    my $fight_start = $player->fight_start;
    $fight_start->set_time_zone('Europe/Rome');
    my $now = DateTime->now;
    $now->set_time_zone('Europe/Rome');
    my $delta = $now->delta_ms($fight_start);
    my $units = $delta->in_units('hours');
    return $units;
}

sub end_of_war
{
    my $self = shift;
    my $game = shift;
    my $player = shift;
    my $force = shift;
    die 'no-war' if(! $player->joined_army);
    my $units = $self->war_duration($player);
    $units = 1 if($units < 1 && $force);
    die 'not-enough-time' if ($units < 1);
    my $nation_meta = $self->get_nation_meta($game, $player->position);
    my $friendship_bonus;
    my $role = $self->role_in_war($game, $player->position, $player->joined_army);

    #Here is the logic about diplomacy changes
    $friendship_bonus->{$player->joined_army} = 1 + $units;
    if($role eq 'invader')
    {
        $friendship_bonus->{$player->position} = -1 - $units;
        $friendship_bonus->{$nation_meta->{foreigners}->{supporter}} = 1 - $units;
        for(@{$nation_meta->{foreigners}->{invaders}})
        {
            if($_ ne $player->joined_army)
            {
                $friendship_bonus->{$_} = -1 + $units;
            }
        }
    }
    elsif($role eq 'supporter')
    {
        for(@{$nation_meta->{foreigners}->{invaders}})
        {
            $friendship_bonus->{$_} = 0 - $units;
        }
        $friendship_bonus->{$player->position} = $units -1;
    }
    elsif($role eq 'defender')
    {
        for(@{$nation_meta->{foreigners}->{invaders}})
        {
            $friendship_bonus->{$_} = 0 - $units;
        }
    }
    my $dice = BalanceOfPower::Dice->new();
    my $lost_health_points = $dice->random(0, $units);
    
    say " === Friendship changes === ";
    say Dumper($friendship_bonus);
    say " === Health lost === ";
    say $lost_health_points;
    say "";
}
1;
