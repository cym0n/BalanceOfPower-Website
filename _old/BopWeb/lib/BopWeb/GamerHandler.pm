package BopWeb::GamerHandler;

use Moo;

use BopWeb::MetaReader;

has metareader => (
    is => 'ro',
    default => sub { BopWeb::MetaReader->new() },
    handles => { get_meta => 'get_meta',
                 get_nation_meta => 'get_nation_meta',
                 get_player_meta => 'get_player_meta',
                 get_nation_codes => 'get_nation_codes',
               }
);

has schema => (
    is => 'ro'
);

1;
