use utf8;
package BopWeb::BopWebDB::Result::UserGame;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BopWeb::BopWebDB::Result::UserGame

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

=head1 TABLE: C<USER_GAMES>

=cut

__PACKAGE__->table("USER_GAMES");

=head1 ACCESSORS

=head2 user

  data_type: 'integer'
  is_nullable: 0

=head2 game

  data_type: 'integer'
  is_nullable: 0

=head2 player

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "user",
  { data_type => "integer", is_nullable => 0 },
  "game",
  { data_type => "integer", is_nullable => 0 },
  "player",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2016-08-12 18:17:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qgSvHznZi6J3ncmXHCDtHQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->belongs_to(
  "user",
  "BopWeb::BopWebDB::Result::BopUser",
  { id => "user" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

__PACKAGE__->belongs_to(
  "game",
  "BopWeb::BopWebDB::Result::BopGame",
  { id => "game" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

__PACKAGE__->set_primary_key('user', 'game');

1;
