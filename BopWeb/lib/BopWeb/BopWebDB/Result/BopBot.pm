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


sub action
{
    my $self = shift;
    my $travelagent = shift;
    if($self->class eq 'borderagent')
    {
        my $arrive = $self->travel($travelagent);
        if($arrive == 2)
        {
            $self->actions->delete_all();
    
        }

    }
}

sub travel
{
    my $self = shift;
    my $travelagent = shift;
    if($self->destination && $travelagent->finished_travel($self))
    {
        $travelagent->arrive($self);
        say $self->name . " arrived in " . $self->position;
        return 2;
    }
    else
    {
        if($travelagent->enabled_to_travel($self) && $travelagent->go_random($self->game, $self))
        {
            say $self->name . " started a travel to " . $self->destination;
            return 1;
        }
        else
        {
            say $self->name . " do nothing";
            return 0;
        }
    }
}

1;
