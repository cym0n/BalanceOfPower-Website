use utf8;
use v5.10;
package BopWeb::BopWebDB::Result::BopBot;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BopWeb::BopWebDB::Result::BopBot

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

=head1 TABLE: C<BOP_BOTS>

=cut

__PACKAGE__->table("BOP_BOTS");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 game

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 photo

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 nation

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 position

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 destination

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 arrival_time

  data_type: 'timestamp'
  is_nullable: 1

=head2 disembark_time

  data_type: 'timestamp'
  is_nullable: 1

=head2 class

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "game",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "photo",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "nation",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "position",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "destination",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "arrival_time",
  { data_type => "timestamp", is_nullable => 1 },
  "disembark_time",
  { data_type => "timestamp", is_nullable => 1 },
  "class",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2016-09-29 22:48:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rVS0qnfsntP9buhT77vBMw


# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->has_many(
  "actions",
  "BopWeb::BopWebDB::Result::BopBotAction",
  { "foreign.bot" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

use BalanceOfPower::Dice;

sub action
{
    my $self = shift;
    my $travelagent = shift;
    my @log = ();
    if($self->class eq 'borderguard')
    {
        my $arrive = $self->travel($travelagent);
        if($arrive == 2)
        {
            push @log, $self->name . " arrived in " . $self->position;
            $self->actions->delete_all();
            my $dice = BalanceOfPower::Dice->new();
            my $travelplan = $travelagent->get_travel_plan($self->game, $self);
            foreach my $way ( qw(air ground))
            {
                foreach my $dest (keys %{$travelplan->{$way}})
                {
                    if($travelplan->{$way}->{$dest}->{'status'} eq 'OK')
                    {
                        my $coin = $dice->random(1, 2, $self->name . " decides to block $dest");
                        if($coin == 2)
                        {
                            push @log, $self->name . " blocking $dest";
                            $self->actions->create({ game => $self->game,
                                                    bot => $self,
                                                    action => 'block',
                                                    param1 => $dest });
                        }
                        else
                        {
                        }
                    }
                }
            }
        }
        elsif($arrive == 1)
        {
            push @log, $self->name . " started a travel to " . $self->destination;
        }
        else
        {
        }
    }
    else
    {
        push @log, "Unrecognized class " . $self->class . " for " . $self->name;
    }
    return @log;
}

sub travel
{
    my $self = shift;
    my $travelagent = shift;
    if($self->destination && $travelagent->finished_travel($self))
    {
        $travelagent->arrive($self);
        return 2;
    }
    else
    {
        if($travelagent->enabled_to_travel($self) && $travelagent->go_random($self->game, $self))
        {
            return 1;
        }
        else
        {
            return 0;
        }
    }
}

1;
