use utf8;
package BopWeb::BopWebDB::Result::BopNotification;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BopWeb::BopWebDB::Result::BopNotification

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

=head1 TABLE: C<BOP_NOTIFICATIONS>

=cut

__PACKAGE__->table("BOP_NOTIFICATIONS");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 player

  data_type: 'number'
  is_nullable: 0

=head2 position

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 tag

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 text

  data_type: 'text'
  is_nullable: 1

=head2 timestamp

  data_type: 'timestamp'
  is_nullable: 1

=head2 read

  data_type: 'tinyint'
  is_nullable: 1
  size: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "player",
  { data_type => "number", is_nullable => 0 },
  "position",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "tag",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "text",
  { data_type => "text", is_nullable => 1 },
  "timestamp",
  { data_type => "timestamp", is_nullable => 1 },
  "read",
  { data_type => "tinyint", is_nullable => 1, size => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2016-11-01 15:12:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:H6gTO/1zD97YARr2uM1h0g


# You can replace this text with custom code or comments, and it will be preserved on regeneration

use Text::Markdown 'markdown';

__PACKAGE__->belongs_to(
  "player",
  "BopWeb::BopWebDB::Result::BopPlayer",
  { id => "player" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

sub printed_timestamp
{
    my $self = shift;
    my $ts = $self->timestamp;
    $ts->set_time_zone("Europe/Rome");
    return $ts->dmy . " " . $ts->hms;
}

sub printed_notification
{
    my $self = shift;
    return markdown($self->text);
}

1;
