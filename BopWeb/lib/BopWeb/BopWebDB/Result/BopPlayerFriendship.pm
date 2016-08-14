use utf8;
package BopWeb::BopWebDB::Result::BopPlayerFriendship;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BopWeb::BopWebDB::Result::BopPlayerFriendship

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

=head1 TABLE: C<BOP_PLAYER_FRIENDSHIP>

=cut

__PACKAGE__->table("BOP_PLAYER_FRIENDSHIP");

=head1 ACCESSORS

=head2 player

  data_type: 'integer'
  is_nullable: 0

=head2 nation

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 value

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "player",
  { data_type => "integer", is_nullable => 0 },
  "nation",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "value",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2016-08-14 15:20:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:m52jqvC2vQ1110/cozmpDA


# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->set_primary_key('player', 'nation');
1;
