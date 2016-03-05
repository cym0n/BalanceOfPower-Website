use utf8;
package BopWeb::BopWebDB::Result::InfluenceOrder;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BopWeb::BopWebDB::Result::InfluenceOrder

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

=head1 TABLE: C<INFLUENCE_ORDERS>

=cut

__PACKAGE__->table("INFLUENCE_ORDERS");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 game

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 user

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 turn

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 nation

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 command

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 target

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 exec_order

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "game",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "user",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "turn",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "nation",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "command",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "target",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "exec_order",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2016-03-05 15:27:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+og25hyw2qYlq2Uyy9+vwA


# You can replace this text with custom code or comments, and it will be preserved on regeneration


sub as_string
{
    my $self = shift;
    if($self->target)
    {
        return $self->command . " " . $self->target;
    }
    else
    {
        return $self->command;
    }

}
1;
