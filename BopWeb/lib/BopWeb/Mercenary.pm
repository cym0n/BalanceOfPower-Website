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
sub able_to_leave
{
    my $self = shift;
    my $player = shift;
    my $force = shift;
    my $units = $self->war_duration($player);
    $units = 1 if($units < 1 && $force);
    return $units >= 1;
}


sub role_in_war
{
    my $self = shift;
    my $game = shift;
    my $position = shift;
    my $nation = shift;
    open(my $log, ">> rolelog");
    print {$log} "Calculate role of $nation in $position\n";
    my $nation_meta = $self->get_nation_meta($game, $position);
    my $role;
    if($position eq $nation)
    {
        $role = 'defender';
    }
    elsif($nation eq $nation_meta->{foreigners}->{supporter})
    {
        $role = 'supporter';
    }
    elsif(grep { $_ eq $nation} @{$nation_meta->{foreigners}->{invaders}})
    {
        $role = 'invader';
    }
    else
    {
        $role = 'none';
    }
    return $role;
}
    

sub war_duration
{
    my $self = shift;
    my $player = shift;
    return 0 if ! $player->joined_army;
    return 0 if ! $player->fight_start;
    my $fight_start = $player->fight_start;
    $fight_start->set_time_zone('Europe/Rome');
    my $now = DateTime->now;
    $now->set_time_zone('Europe/Rome');
    my $delta = $now->delta_ms($fight_start);
    my $units = $delta->in_units('hours');
    return $units;
}

sub war_time_limit_reached
{
    my $self = shift;
    my $player = shift;
    my $units = $self->war_duration($player);
    return $units >= 3;
}

sub end_of_war
{
    my $self = shift;
    my $game = shift;
    my $player = shift;
    my $force = shift;
    die 'no-war' if(! $player->joined_army);
    die 'not-enough-time' if ! $self->able_to_leave($player, $force);
    my $units = $self->war_duration($player);
    $units = 1 if($units < 1 && $force);
    $units = 3 if($units > 3);
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

    #Changes
    $player->add_health(-1 * $lost_health_points);
    foreach my $f (keys %{$friendship_bonus})
    {
        $player->add_friendship($f, $friendship_bonus->{$f});
    }
    $player->reset_war();
    $self->notify_war_end($player, $units, $lost_health_points, $friendship_bonus);
    return 1;
}

sub notify_war_end
{
    my $self = shift;
    my $player = shift;
    my $units = shift;
    my $lost_health = shift;
    my $friendships = shift;
    my $time = DateTime->now();

    my $text = "You left the war in " . $player->position . " after $units units of time\n\n";
    $text   .= "$lost_health health points lost\n";
    $text   .= "Relationships changes:\n";
    foreach my $f (keys %{$friendships})
    {
        $text .= "$f: " . $friendships->{$f} . "\n";
    }
 
    $time->set_time_zone('Europe/Rome');
    $self->schema->resultset('BopNotification')->create({
                                player => $player,
                                position => $player->position,
                                tag => 'warend',
                                text => $text,
                                timestamp => $time,
                                read => 0 });
}
1;
