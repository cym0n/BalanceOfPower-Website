package BopWeb::TravelAgent;

use Moo;

use BopWeb::MetaReader;

has metareader => (
    is => 'ro',
    default => sub { BopWeb::MetaReader->new() },
    handles => { get_meta => 'get_meta',
                 get_nation_meta => 'get_nation_meta',
                 get_player_meta => 'get_player_meta',
                 get_nation_codes => 'get_nation_codes',
               }
);

sub go
{
    my $self = shift;
    my $game = shift;
    my $player = shift;
    my $destination = shift;
    die "no-destination\n" if(! $destination);
    die "not-ready-to-travel\n" if( ! $self->enabled_to_travel($player));
    die "ongoing-travel\n" if($player->destination);

    my $codes = $self->get_nation_codes($game);
    my $nation_meta = $self->get_nation_meta($game, $codes->{$player->position});
    my $data;
    $data = exists $nation_meta->{'travels'}->{'air'}->{$destination} &&  $nation_meta->{'travels'}->{'air'}->{$destination}->{'status'} eq 'OK' ? 
                $nation_meta->{'travels'}->{'air'}->{$destination} :
                    exists $nation_meta->{'travels'}->{'ground'}->{$destination} &&  $nation_meta->{'travels'}->{'ground'}->{$destination}->{'status'} eq 'OK' ?
                        $nation_meta->{'travels'}->{'ground'}->{$destination} :
                            undef;
    die "bad-destination\n" if ! $data;
    
    my $time = DateTime->now();
    $time->add( hours => $data->{cost});
    $time->set_time_zone('Europe/Rome');
    $player->destination($destination);
    $player->arrival_time($time);
    $player->update;
    return $destination;
}

sub arrive
{
    my $self = shift;
    my $player = shift;
    if($self->finished_travel($player))
    {
        $player->position($player->destination);
        $player->destination(undef);
        $player->arrival_time(undef);
        my $time = DateTime->now;
        $time->set_time_zone('Europe/Rome');
        $player->disembark_time($time);
        $player->reset_used();
        $player->update();
        return $player->position;
    }
    else
    {
        die "not-arrived\n";
    }
}

sub enabled_to_travel
{
    my $self = shift;
    my $player = shift;
    my $disembark_time = $player->disembark_time;
    return 1 if ! $disembark_time;
    
    my $enable_to_travel = $disembark_time->clone;
    $enable_to_travel->set_time_zone('Europe/Rome');
    $enable_to_travel->add( hours => 2);
    my $now = DateTime->now;
    $now->set_time_zone('Europe/Rome');
    return DateTime->compare($now, $enable_to_travel) == 1
}

sub finished_travel
{
    my $self = shift;
    my $player = shift;
    my $arrival_time = $player->arrival_time;
    return 1 if ! $arrival_time;
    $arrival_time->set_time_zone('Europe/Rome');
    my $now = DateTime->now;
    $now->set_time_zone('Europe/Rome');
    if(DateTime->compare($now, $arrival_time) == 1)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

1;
