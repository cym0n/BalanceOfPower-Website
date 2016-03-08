use utf8;
package BopWeb::BopWebDB::Result::BopGame;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BopWeb::BopWebDB::Result::BopGame

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

=head1 TABLE: C<BOP_GAMES>

=cut

__PACKAGE__->table("BOP_GAMES");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 file

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 admin_password

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 invite_password

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 active

  data_type: 'tinyint'
  is_nullable: 1
  size: 1

=head2 open

  data_type: 'tinyint'
  is_nullable: 1
  size: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "file",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "admin_password",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "invite_password",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "active",
  { data_type => "tinyint", is_nullable => 1, size => 1 },
  "open",
  { data_type => "tinyint", is_nullable => 1, size => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2016-03-08 23:39:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:e22GPO3eR5WI1iScGKU8Yw


# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->has_many(
  "usergames",
  "BopWeb::BopWebDB::Result::UserGame",
  { "foreign.game" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
1;
