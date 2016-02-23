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
  is_nullable: 1

=head2 game

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "user",
  { data_type => "integer", is_nullable => 1 },
  "game",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2016-02-23 23:16:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XVw/HnBnkjpV9921Dv7aLw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
