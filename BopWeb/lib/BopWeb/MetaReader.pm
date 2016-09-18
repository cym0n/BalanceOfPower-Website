package BopWeb::MetaReader;

use Moo;

has path => (
    is => 'ro'
);



sub get_meta
{
    my $self = shift;
    my $game = shift;
    return $self->read_metafile($self->path . '/' . $game . '.meta');
}

sub get_nation_meta
{
    my $self = shift;
    my $game = shift;
    my $nation = shift;
    return $self->read_metafile($self->path . '/' . $game . "/n/$nation.data");
}

sub get_player_meta
{
    my $self = shift;
    my $game = shift;
    my $user = shift;
    my $type = shift;
    return undef if ! $user;
    return $self->read_metafile($self->path . '/' . $game . "/p/$user-$type.data");
}

sub read_metafile
{
    my $self = shift;
    my $meta = shift;
    if(-e $meta)
    {
        open my $metafile, '<', $meta || die $!;
        my $data;
        {
            local $/;    # slurp mode
            my $metafile_data = <$metafile>;
            my $VAR1;
            eval $metafile_data;
            return $VAR1;
        }
    }
    else
    {
        return undef;
    }
}
sub get_nation_codes
{
    my $self = shift;
    my $game = shift;
    my $meta = $self->get_meta($game);
    my $nations = $meta->{nations};
    my %out = ();
    foreach my $n (keys %{$nations})
    {
        $out{$n} = $nations->{$n}->{'code'};
    }
    return \%out;
}

1;
