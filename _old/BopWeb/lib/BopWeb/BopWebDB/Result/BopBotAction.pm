use utf8;
package BopWeb::BopWebDB::Result::BopBotAction;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BopWeb::BopWebDB::Result::BopBotAction

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

=head1 TABLE: C<BOP_BOT_ACTIONS>

=cut

__PACKAGE__->table("BOP_BOT_ACTIONS");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 game

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 bot

  data_type: 'integer'
  is_nullable: 1

=head2 action

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 param1

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 param2

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 param3

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 param4

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 param5

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 start_turn

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 start_time

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "game",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "bot",
  { data_type => "integer", is_nullable => 1 },
  "action",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "param1",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "param2",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "param3",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "param4",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "param5",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "start_turn",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "start_time",
  { data_type => "timestamp", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2016-09-29 22:55:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9WhS3s3qf1OYsqIgkJ2pfg


# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->belongs_to(
  "bot",
  "BopWeb::BopWebDB::Result::BopBot",
  { id => "bot" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);
1;
