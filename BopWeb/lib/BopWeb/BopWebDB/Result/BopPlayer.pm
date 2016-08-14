use utf8;
package BopWeb::BopWebDB::Result::BopPlayer;
use lib "/home/cymon/works/nations/repo/src/lib";
use BalanceOfPower::Constants ':all';;


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

  data_type: 'real'
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
  { data_type => "real", is_nullable => 1 },
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


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2016-08-14 16:35:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Sq0F6PxoSRPB9Oe2igPs8A


# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->has_many(
  "friendships",
  "BopWeb::BopWebDB::Result::BopPlayerFriendship",
  { "foreign.player" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "holds",
  "BopWeb::BopWebDB::Result::Hold",
  { "foreign.player" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

sub money_to_print
{
    my $self = shift;
    my $money = $self->money;
    $money = (int($money * 100)/100);
    return $money;
}

sub get_friendship
{
    my $self = shift;
    my $nation = shift;
    my $f = $self->friendships->find({ nation => $nation });
    if($f)
    {
        return 50 + $f->value;
    }
    else
    {
        return 50;
    }
}
sub add_friendship
{
    my $self = shift;
    my $nation = shift;
    my $value = shift;
    my $f = $self->friendships->find({ nation => $nation });
    if(! $f)
    {
        $self->friendships->create({ nation => $nation, value => $value });
    }
    else
    {
        my $new_value = $f->value + $value;
        $new_value = 50 if $new_value > 50;
        $new_value = -50 if $new_value < -50;
        $f->value($new_value);
        $f->update;
    }
}

sub add_cargo
{
    my $self = shift;
    my $type = shift;
    my $q = shift;
    my $cargo_obj = $self->holds->find({ type => $type });
    if(! $cargo_obj)
    {
        $self->holds->create({ type => $type,
                               quantity => $q });
    }
    else
    {
        my $new_q = $cargo_obj->quantity + $q;
        $cargo_obj->quantity($new_q);
        $cargo_obj->update;
    }
}
sub cargo_status
{
    my $self = shift;
    my $products = shift;
    my $tot_q = 0;
    my %hold = ();
    foreach my $h ($self->holds)
    {
        $hold{$h->type} = $h->quantity;
        $tot_q += $h->quantity;
    }
    foreach my $p(@{$products})
    {
        if(! exists $hold{$p})
        {
            $hold{$p} = 0;
        }
    }
    $hold{'free'} = CARGO_TOTAL_SPACE - $tot_q; 
    return %hold;
}



sub add_money
{
    my $self = shift;
    my $money = shift;
    my $new_money = $self->money + $money;
    $new_money = 0 if($new_money < 0);
    $self->money($new_money);
    $self->update();
}

1;
