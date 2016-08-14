use utf8;
package BopWeb::BopWebDB::Result::Hold;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BopWeb::BopWebDB::Result::Hold

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

=head1 TABLE: C<HOLD>

=cut

__PACKAGE__->table("HOLD");

=head1 ACCESSORS

=head2 player

  data_type: 'number'
  is_nullable: 0

=head2 type

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 quantity

  data_type: 'number'
  is_nullable: 0

=head2 price

  data_type: 'real'
  is_nullable: 1

=head2 stat

  data_type: 'real'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "player",
  { data_type => "number", is_nullable => 0 },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "quantity",
  { data_type => "number", is_nullable => 0 },
  "price",
  { data_type => "real", is_nullable => 1 },
  "stat",
  { data_type => "real", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2016-08-14 18:33:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4V1cOnLhQj2Q7EZns/AMxA


# You can replace this text with custom code or comments, and it will be preserved on regeneration


__PACKAGE__->set_primary_key('player', 'type');

1;
