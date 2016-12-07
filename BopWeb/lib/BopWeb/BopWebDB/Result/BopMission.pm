use utf8;
package BopWeb::BopWebDB::Result::BopMission;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BopWeb::BopWebDB::Result::BopMission

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<BOP_MISSIONS>

=cut

__PACKAGE__->table("BOP_MISSIONS");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 type

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 assigned

  data_type: 'integer'
  is_nullable: 1

=head2 expire_turn

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 status

  data_type: 'integer'
  is_nullable: 1

=head2 configuration

  data_type: 'text'
  is_nullable: 1

=head2 reward

  data_type: 'text'
  is_nullable: 1

=head2 location

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 progress

  data_type: 'integer'
  is_nullable: 1

=head2 game

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "type",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "assigned",
  { data_type => "integer", is_nullable => 1 },
  "expire_turn",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "status",
  { data_type => "integer", is_nullable => 1 },
  "configuration",
  { data_type => "text", is_nullable => 1 },
  "reward",
  { data_type => "text", is_nullable => 1 },
  "location",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "progress",
  { data_type => "integer", is_nullable => 1 },
  "game",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2016-09-04 16:40:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:V79nSDDVHDjqptiKVTZlrA


# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->belongs_to(
  "player",
  "BopWeb::BopWebDB::Result::BopPlayer",
  { id => "assigned" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

use JSON;
use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils;
use BopWeb::BopWebDB::Result::BopNotification;

sub to_hash
{
    my $self = shift;
    my %out;
    $out{'id'} = $self->id;
    $out{'type'} = $self->type;
    $out{'expire_turn'} = $self->expire_turn;
    $out{'status'} = $self->status;
    $out{'location'} = $self->location;
    $out{'configuration'} = decode_json $self->configuration;
    $out{'reward'} = decode_json $self->reward;
    $out{'drop_penalty'} = $self->drop_penalty;
    $out{'progress'} = $self->progress;
    return \%out;
}

sub drop_penalty
{
    my $self = shift;
    my $reward =  decode_json $self->reward;
    if(exists $reward->{'money'} && $reward->{'money'} > 0)
    {
        return int(($reward->{'money'} * PENALTY_FACTOR_FOR_DROP_MISSION) * 100)/100;
    }
    else
    {
        return 0;
    }
}

sub action_available
{
    my $self = shift;
    my $player = $self->player;
    my $data = $self->to_hash;

    if($self->type eq 'parcel')
    {
        if($self->progress == 0) #Parcel must be retrieved
        {
            return $data->{'configuration'}->{'from'} eq $player->position;
        }
        elsif($self->progress == 1)
        {
            return $data->{'configuration'}->{'to'} eq $player->position;
        }
        else
        {
            return 0;
        }
    }
    else
    {
        return 0;
    }
}

sub progress_limit
{
    my $self = shift;
    if($self->type eq 'parcel')
    {
        return 2;
    }
}

sub action
{
    my $self = shift;
    if($self->progress < $self->progress_limit)
    {
        $self->progress($self->progress + 1);
        $self->update;
    }
}

sub accomplished
{
    my $self = shift;
    if( $self->progress == $self->progress_limit)
    {
        $self->status(2);
        $self->update;
        $self->notify('success');
        return 1;
    }
    else
    {
        return 0;
    }
}

sub notify
{
    my $self = shift;
    my $action = shift;
    my $schema = $self->result_source->schema;
    return if ! $self->assigned;
    my $time = DateTime->now();
    $time->set_time_zone('Europe/Rome');
    my $text;
    my $tag = "mission-$action-" . $self->type;
    if($action eq 'success')
    {
       $text = "*Mission accomplished*\n";
    }
    elsif($action eq 'drop')
    {
        $text = "*Mission dropped*\n";
    }
    elsif($action eq 'failure')
    {
        $text = "*Mission failed*\n";
    }
    my $data = $self->to_hash;
    if($self->type eq 'parcel' and $action eq 'success')
    {
        $text .= "Parcel delivered from " . $data->{'configuration'}->{'from'} . " to " .
                 $data->{'configuration'}->{'to'};
    }
    else
    {
        $text .= "Parcel not delivered from " . $data->{'configuration'}->{'from'} . " to " .
                 $data->{'configuration'}->{'to'};
    }

    $schema->resultset('BopNotification')->create({
                              player => $self->player,
                              position => $self->player->position,
                              tag => $tag,
                              text => $text,
                              timestamp => $time,
                              read => 0 });
}

sub expired
{
    my $self = shift;
    my $now = shift;
    my $compare = BalanceOfPower::Utils::compare_turns($now, $self->expire_turn);
    return $compare > -1;
}


1;
