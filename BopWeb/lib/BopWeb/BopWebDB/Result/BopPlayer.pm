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

=head2 joined_army

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 fight_start

  data_type: 'timestamp'
  is_nullable: 1

=head2 health

  data_type: 'number'
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
  "joined_army",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "fight_start",
  { data_type => "timestamp", is_nullable => 1 },
  "health",
  { data_type => "number", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2016-10-13 23:57:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:efMFFskuiNpAlWWWz9WE9A


# You can replace this text with custom code or comments, and it will be preserved on regeneration

use lib "/home/cymon/works/nations/repo/src/lib";
use BalanceOfPower::Constants ':all';

use constant MAX_LIFE => 5;




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
    my $price = shift;
    my $stat = shift;
    my $cargo_obj = $self->holds->find({ type => $type });
    if(! $cargo_obj && $q > 0)
    {
        $self->holds->create({ 'type' => $type,
                               'quantity' => $q, 
                               'price' => $price,
                               'stat' => $stat,
                               'used' => 1});
    }
    else
    {
        my $new_q = $cargo_obj->quantity + $q;
        if($q > 0)
        {
            my $new_stat = (($cargo_obj->stat * $cargo_obj->quantity) + ($stat * $q)) / $new_q;
            my $new_price = (($cargo_obj->price * $cargo_obj->quantity) + ($price * $q)) / $new_q;
            $cargo_obj->stat($new_stat);
            $cargo_obj->price($new_price);
        }
        $cargo_obj->quantity($new_q);
        $cargo_obj->used(1);
        $cargo_obj->update;
    }
}
sub reset_used
{
    my $self = shift;
    my @holds =  $self->holds;
    foreach my $h (@holds)
    {
        $h->used(0);
        $h->update();
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
sub get_hold
{
    my $self = shift;
    my $product = shift;
    my $hold = $self->holds->find({ type => $product });
    if($hold)
    {
        return { quantity => $hold->quantity,
                 stat     => $hold->stat,
                 price    => $hold->price,
                 used     => $hold->used };
    }
    else
    {
        return { quantity => 0,
                 stat     => 0,
                 price    => 0,
                 used     => 0 };
    }
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
sub add_health
{
    my $self = shift;
    my $health = shift;
    my $new_health = $self->health + $health;
    $new_health = 0 if($new_health < 0);
    $self->health($new_health);
    $self->update();
}
sub reset_war
{
    my $self = shift;
    $self->fight_start(undef);
    $self->joined_army(undef);
    $self->update();
}


1;
