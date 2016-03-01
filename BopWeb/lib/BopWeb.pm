package BopWeb;
use lib "/home/cymon/works/nations/repo/src/lib";
use Dancer2;
use Dancer2::Plugin::DBIC;

use Cwd 'abs_path';
use HTML::FormFu;
use Data::Dumper;
use Dancer2::Serializer::JSON;
use Authen::Passphrase::BlowfishCrypt;

use BalanceOfPower::Utils qw (prev_turn);

our $VERSION = '0.1';

### GAME

my $module_file_path = __FILE__;
my $root_path = abs_path($module_file_path);
$root_path =~ s/lib\/BopWeb\.pm//;

my $metadata_path = $root_path . "metadata";
my @reports_menu = ('r/situation', 'r/hotspots', 'r/alliances', 'r/influences', 'r/supports', 'r/rebel-supports', 'r/war-history', 'r/events' );
my @nation_reports_menu = ('n/actual', 'n/borders', 'n/near', 'n/diplomacy', 'n/events' );
my @player_reports_menu = ('r/market', 'p/stocks', 'p/events' );

my %report_configuration = (
           'r/situation' => {
               menu_name => 'Situation',
               custom_js => 'blocks/alldata.tt'
            },
            'r/hotspots' => {
               menu_name => 'Hotspots',
            },
            'r/alliances' => {
               menu_name => 'Alliances',
            },
            'r/influences' => {
               menu_name => 'Influences',
            },
            'r/supports' => {
               menu_name => 'Military Supports',
            },
            'r/rebel-supports' => {
               menu_name => 'Rebel Supports',
            },
            'r/war-history' => {
               menu_name => 'War History',
            },
            'r/events' => {
               menu_name => 'Events',
            },
            'n/actual' => {
               menu_name => 'Status'
            },
            'n/borders' => {
                menu_name => 'Borders'
            },
            'n/near' => {
                menu_name => 'Military Range'
            },
            'n/diplomacy' => {
                menu_name => 'Diplomacy',
            },
            'n/events' => {
                menu_name => 'Events'
            },
            'r/market' => {
                menu_name => 'Market',
                menu => \@player_reports_menu,
                active_top => 'market',
                logged => 1
            },
            'p/stocks' => {
                menu_name => 'My Stocks',
                logged => 1
            },
            'p/events' => {
                menu_name => 'Market Events',
                logged => 1
            }
    );


get '/' => sub {
    template 'home';
};

get '/play/:game/:year/:turn/:context/:object/:report' => sub {
    my $report_id = params->{context} . '/' . params->{report};
    my $meta = get_metafile($metadata_path . '/' . params->{game} . '.meta');
    my $user = session->read('user');
    my $standards = get_report_standard_from_context(params->{context});
    my $report_conf = $report_configuration{$report_id};
    for(keys $standards)
    {
        if(! exists $report_conf->{$_})
        {
            $report_conf->{$_} = $standards->{$_}
        }
    }
    if($report_conf->{logged} == 1)
    {
        if(! $user)
        {
            send_error("Access denied", 403);
            return;
        }
        if(params->{context} eq 'p' && $user != params->{object})
        {
            send_error("Access denied", 403);
            return;
        }
    }
    my $obj_dir = params->{object} eq 'year' ? '' : params->{object} . '/';
    my $report_to_show = 'generated/' . 
                         params->{game} . '/' .
                         params->{year} . '/' .
                         params->{turn} . '/' . $report_conf->{'subdir'} .
                         $obj_dir .
                         params->{report} . '.tt'; 
    my $page_title;
    if($report_conf->{'title'} eq 'year')
    {
        $page_title = params->{year} . '/' . params->{turn};
    }
    elsif($report_conf->{'title'} eq 'nation')
    {
        $page_title = params->{object} . " - " .params->{year} . '/' . params->{turn};
    }
    elsif($report_conf->{'title'} eq 'player')
    {
        $page_title = $user;
    }
    my ($menu, $ordered) = make_menu($report_conf->{menu}, params->{object}, $user);
    my $wallet = undef;
    if(params->{context} eq 'n' && $user)
    {
        $wallet =     my $meta = get_metafile($metadata_path . '/' . params->{game} . "/p/$user-wallet.data");
    }
    template $report_conf->{template}, {
       'object' => params->{object},
       'report' => $report_to_show,
       'menu' => $menu,
       'menu_urls' => $ordered,
       'active' => make_complete_url($report_id, params->{object}, $user),
       'game' => params->{game},
       'year' => params->{year},
       'turn' => params->{turn},
       'active_top' => $report_conf->{active_top},
       'custom_js' => $report_conf->{custom_js},
       'player' => $user,
       'page_title' => $page_title,
       'wallet' => $wallet,
       'context' => params->{context}
    }; 
};



get '/play/:game' => sub {
    my $meta = get_metafile($metadata_path . '/' . params->{game} . '.meta');
    if($meta)
    {
        my $redirection = "/play/" . params->{game} . "/" . $meta->{'current_year'} . "/r/year/situation";
        redirect $redirection, 302;
    }
    else
    {
        pass;
    }
};
get '/play/:game/n' => sub {
    my $meta = get_metafile($metadata_path . '/' . params->{game} . '.meta');
    if($meta)
    {
        template 'nations', {
            areas => ['North America', 'South America', 'Europe', 'Africa', 'Middle East', 'Far East', 'Pacific'],
            nations => $meta->{nations},
            game => params->{game},
            year => $meta->{'current_year'},
            active_top => 'nations'
        }
    }
    else
    {
        pass;
    }
};
get '/play/:game/n/:nation' => sub {
    my $meta = get_metafile($metadata_path . '/' . params->{game} . '.meta');
    my $redirection = "/play/" . params->{game} . "/" . $meta->{'current_year'} . "/n/" . params->{nation};
        redirect $redirection, 302;
};
get '/play/:game/:year/:turn/n/:nation' => sub {
        my $redirection = "/play/" . params->{game} . "/" . params->{year} . "/" . params->{turn} . "/n/" . params->{nation} . "/actual";
        redirect $redirection, 302;
};

sub get_metafile
{
    my $meta = shift;
    if(-e $meta)
    {
        open my $metafile, '<', $meta || die $!;
        my $data;
        {
            local $/;    # slurp mode
            my $metafile_data = <$metafile>;
            my $VAR1;
            eval $metafile_data;
            return $VAR1;
        }
    }
    else
    {
        return undef;
    }
}

sub get_report_standard_from_context
{
    my $context = shift;
    my $menu;
    my $title;
    my $active_top;
    my $subdir;
    if($context eq 'r')
    {
        $menu = \@reports_menu;
        $title = 'year';
        $active_top = 'year';
        $subdir = '';

    }
    elsif($context eq 'n')
    {
        $menu = \@nation_reports_menu,
        $title = 'nation';
        $active_top = 'nations';
        $subdir = 'n/';
    }
    elsif($context eq 'p')
    {
        $menu = \@player_reports_menu,
        $title = 'player';
        $active_top = 'market';
        $subdir = 'p/';
    }
    return { title => $title, 
             menu => $menu,
             subdir => $subdir,
             template => 'report',
             custom_js => undef,
             active_top => $active_top,
             logged => 0,
           };
}
sub make_complete_url
{
    my $menu = shift;
    my $obj = shift;
    my $user = shift;
    if($menu =~ /^r/)
    {
        $menu =~ s/\//\/year\//;
    }
    elsif($menu =~ /^n/)
    {
        $menu =~ s/\//\/$obj\//;
    }
    elsif($menu =~ /^p/)
    {
        $menu =~ s/\//\/$user\//;
    }
    return $menu;
}
sub make_menu
{
    my $entries = shift;
    my $obj = shift;
    my $user = shift;
    my %out = ();
    my @order = ();
    for(@{$entries})
    {
        my $original_menu = $_;
        my $menu = make_complete_url($original_menu, $obj, $user);
        $out{$menu} = $report_configuration{$original_menu}->{menu_name};
        push @order, $menu;
    }
    return (\%out, \@order);
}

### USER MANAGEMENT

my $form_path = $root_path . "forms";

any '/users/register' => sub {
    my $form = HTML::FormFu->new;
    my $params_hashref = params;
    $form->load_config_file( $form_path . '/register.yml' );
    $form->process($params_hashref);
    my $message = undef;
    if($form->submitted_and_valid)
    {
        if(params->{repassword} ne params->{password})
        {
            $message = "Password mismetch. Retype the right password!"
        } 
        else
        {
            my $user = schema->resultset('BopUser')->find({'user' => params->{user}});
            if($user)
            {
                $message = "Username already taken";
            }    
            else
            {
                my $user_data = generate_crypted_password(params->{password});
                $user_data->{user}  = params->{user};
                $user_data->{role} = 'player';
                schema->resultset('BopUser')->create($user_data);
                session 'user' => $user_data->{'user'};
                redirect '/users/logged', 302;
                return;
            }
        
        }
    }
    template 'user', {
        form => $form->render(),
        message => $message
    }
};

any '/users/login' => sub {
    my $form = HTML::FormFu->new;
    my $params_hashref = params;
    $form->load_config_file( $form_path . '/login.yml' );
    $form->process($params_hashref);
    my $message = undef;
    if($form->submitted_and_valid)
    {
        if(valid_login(params->{user}, params->{password}))
        {
            session 'user' => params->{user};
            redirect '/users/logged', 302;
            return;
        }    
        else
        {
            $message = "Wrong username or password";
        }
    }
    template 'user', {
        form => $form->render(),
        message => $message
    }
};

get '/users/logged' => sub {
    my $user = session->read('user');
    if($user)
    {
        my $user_db = schema->resultset("BopUser")->find({ user => $user });
        my $game = $user_db->usergames->first->game;
        if($game)
        {
            redirect '/play/' . $game->file;
            return;
        }
        else
        {
            redirect '/users/choose-game';
            return;
        }
    }
    else
    {
         redirect '/users/login', 302;
         return;
    }
};

get '/users/choose-game' => sub {
    my $user = session->read('user');
    my @games = schema->resultset("BopGame")->search({ active => 1});
    template 'choose_game', {
        games => \@games
    }
};

get '/users/select-game' => sub {
    my $user = session->read('user');
    my $user_db = schema->resultset("BopUser")->find({ user => $user });
    if($user)
    {
        my $game = params->{game};
        my @user_games = schema->resultset("UserGame")->search({ user => $user_db->id });
        if(@user_games)
        {
            redirect '/users/logged', 302;
            return;
        }
        else
        {
            schema->resultset("UserGame")->create({ user => $user_db->id, game => $game});
            redirect '/users/logged', 302;
            return;
        }
    }
    else
    {
        redirect '/users/login', 302;
    }
};

### API

get '/api/:game/users' => sub {
    my $game = params->{game};
    my $game_db = schema->resultset("BopGame")->find({ file => $game });
    my @usergames = $game_db->usergames;
    my @out = ();
    for(@usergames)
    {
        push @out, $_->user->user;
    }
    content_type('application/json');
    return serialize(\@out, undef);
};



sub generate_crypted_password
{
    my $clean_password = shift;
    my $ppr = Authen::Passphrase::BlowfishCrypt->new(
                cost => 8, salt_random => 1,
                passphrase => $clean_password);
    return { password_hash => $ppr->hash_base64, password_salt => $ppr->salt_base64 };
}

sub valid_login
{
    my $user = shift;
    my $password = shift;
    my $rs = schema->resultset('BopUser')->find({'user' => $user});
    if($rs && $rs->user eq $user)
    {
        my $ppr = Authen::Passphrase::BlowfishCrypt->new(
                  cost => 8, salt_base64 => $rs->password_salt,
                  hash_base64 => $rs->password_hash);
        if($ppr->match($password))
        {
            return $user;
        }
    }
    return undef;
}

sub serialize
{
    my $content = shift;
    my $callback = shift;;
    my $serializer = Dancer2::Serializer::JSON->new();
    my $serialized = $serializer->serialize($content);
    if($callback)
    {
        $serialized = $callback . '( '. $serialized . ')';
    }
    return $serialized;
}


true;
