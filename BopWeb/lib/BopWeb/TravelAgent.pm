package BopWeb::TravelAgent;

use Moo;
use List::Util qw(shuffle);

use BopWeb::MetaReader;
use Data::Dumper;

has metareader => (
    is => 'ro',
    default => sub { BopWeb::MetaReader->new() },
    handles => { get_meta => 'get_meta',
                 get_nation_meta => 'get_nation_meta',
                 get_player_meta => 'get_player_meta',
                 get_nation_codes => 'get_nation_codes',
               }
);

has schema => (
    is => 'ro'
);

sub get_travel_plan
{
    my $self = shift;
    my $game = shift;
    my $player = shift;
    my $nation_meta = $self->get_nation_meta($game, $player->position);
    my $travelplan = $nation_meta->{'travels'};
    
    my @bots = $self->schema->resultset('BopBot')->search({ game => $game, position => $player->position });
    for my $bot (@bots)
    {
        my @blocks = $bot->actions->search({ action => 'block' });;
        foreach my $b (@blocks)
        {
            if(exists $travelplan->{'air'}->{$b->param1} && $travelplan->{'air'}->{$b->param1}->{'status'} eq 'OK')
            {
                $travelplan->{'air'}->{$b->param1}->{'status'} = 'KO';
                $travelplan->{'air'}->{$b->param1}->{'block'} = $b->bot;
            }
            if(exists $travelplan->{'ground'}->{$b->param1} && $travelplan->{'ground'}->{$b->param1}->{'status'} eq 'OK')
            {
                $travelplan->{'ground'}->{$b->param1}->{'status'} = 'KO';
                $travelplan->{'ground'}->{$b->param1}->{'block'} = $b->bot;
            }
        }
    }
    return $travelplan;
}

sub go
{
    my $self = shift;
    my $game = shift;
    my $player = shift;
    my $destination = shift;
    die "no-destination\n" if(! $destination);
    die "not-ready-to-travel\n" if( ! $self->enabled_to_travel($player));
    die "ongoing-travel\n" if($player->destination);

    my $travelplan = $self->get_travel_plan($game, $player);
    my $data;
    $data = exists $travelplan->{'air'}->{$destination} &&  $travelplan->{'air'}->{$destination}->{'status'} eq 'OK' ? 
                $travelplan->{'air'}->{$destination} :
                    exists $travelplan->{'ground'}->{$destination} && $travelplan->{'ground'}->{$destination}->{'status'} eq 'OK' ?
                        $travelplan->{'ground'}->{$destination} :
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

sub go_random
{
    my $self = shift;
    my $game = shift;
    my $player = shift;
    my @destinations;
    my $travelplan = $self->get_travel_plan($game, $player);
    for( keys %{$travelplan->{'air'}})
    {
        push @destinations, $_ if $travelplan->{'air'}->{$_}->{'status'} eq 'OK';
    }
    for( keys %{$travelplan->{'ground'}})
    {
        push @destinations, $_ if $travelplan->{'ground'}->{$_}->{'status'} eq 'OK';
    }
    @destinations = shuffle @destinations;
    if(@destinations)
    {
        eval { $self->go($game, $player, $destinations[0]) };
        if($@)
        {
            return 0;
        }
        else
        {
            return 1;
        }
    }
    else
    {
        return 0;
    }
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
        if( (ref($player)) eq 'BopWeb::BopWebDB::Result::BopPlayer' )
        {
            $player->reset_used();
            $self->notify_arrival($player);
        }
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
    return 1;
    
    #No more waiting time after travel
    #my $disembark_time = $player->disembark_time;
    #return 1 if ! $disembark_time;
    
    #my $enable_to_travel = $disembark_time->clone;
    #$enable_to_travel->set_time_zone('Europe/Rome');
    #$enable_to_travel->add( hours => 2);
    #my $now = DateTime->now;
    #$now->set_time_zone('Europe/Rome');
    #return DateTime->compare($now, $enable_to_travel) == 1
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

sub notify_arrival
{
    my $self = shift;
    my $player = shift;

    my $time = DateTime->now();
    $time->set_time_zone('Europe/Rome');
    $self->schema->resultset('BopNotification')->create({
                                player => $player,
                                position => $player->position,
                                tag => 'arrival',
                                text => "You arrived in " . $player->position,
                                timestamp => $time,
                                read => 0 });
}

1;
