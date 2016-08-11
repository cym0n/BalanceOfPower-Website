use utf8;
package BopWeb::BopWebDB::Result::BopPlayer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BopWeb::BopWebDB::Result::BopPlayer

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

=head1 TABLE: C<BOP_PLAYERS>

=cut

__PACKAGE__->table("BOP_PLAYERS");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 money

  data_type: 'integer'
  is_nullable: 1

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

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "money",
  { data_type => "integer", is_nullable => 1 },
  "position",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "destination",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "arrival_time",
  { data_type => "timestamp", is_nullable => 1 },
  "disembark_time",
  { data_type => "timestamp", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2016-08-05 23:25:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:S6aVhDy9X1ULVFEqBfss7Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration


sub money_to_print
{
    my $self = shift;
    my $money = $self->money;
    $money = (int($money * 100)/100);
    return $money;
}
1;
