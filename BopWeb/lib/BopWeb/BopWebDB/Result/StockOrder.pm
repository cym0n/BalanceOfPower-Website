use utf8;
package BopWeb::BopWebDB::Result::StockOrder;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BopWeb::BopWebDB::Result::StockOrder

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

=head1 TABLE: C<STOCK_ORDERS>

=cut

__PACKAGE__->table("STOCK_ORDERS");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 game

  data_type: 'integer'
  is_nullable: 1

=head2 user

  data_type: 'integer'
  is_nullable: 1

=head2 command

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 nation

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 quantity

  data_type: 'integer'
  is_nullable: 1

=head2 turn

  data_type: 'varchat'
  is_nullable: 1
  size: 10

=head2 exec_order

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "game",
  { data_type => "integer", is_nullable => 1 },
  "user",
  { data_type => "integer", is_nullable => 1 },
  "command",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "nation",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "quantity",
  { data_type => "integer", is_nullable => 1 },
  "turn",
  { data_type => "varchat", is_nullable => 1, size => 10 },
  "exec_order",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2016-03-02 00:23:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:exWgww5JfCSly+/kF11PFw


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub as_string
{
    my $self = shift;
    return lc($self->command) . " " . $self->quantity . " " . $self->nation;
}
1;
