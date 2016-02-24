package BopWeb;
use lib "/home/cymon/works/nations/repo/src/lib";
use Dancer2;
use Dancer2::Plugin::DBIC;

use Cwd 'abs_path';
use HTML::FormFu;
use Data::Dumper;
use Authen::Passphrase::BlowfishCrypt;

use BalanceOfPower::Utils qw (prev_turn);

our $VERSION = '0.1';

### GAME

my $module_file_path = __FILE__;
my $root_path = abs_path($module_file_path);
$root_path =~ s/lib\/BopWeb\.pm//;

my $metadata_path = $root_path . "metadata";

my @reports = ('situation', 'hotspots', 'alliances', 'influences', 'supports', 'rebel-supports', 'war-history', 'events' );
my %report_names = ('situation' => 'Situation',
                    'hotspots' => 'Hotspots',
                    'alliances' => 'Alliances',
                    'influences' => 'Influences',
                    'supports' => 'Military Supports',
                    'rebel-supports' => 'Rebel Supports',
                    'war-history' => 'War History',
                    'events' => 'Events'
                );
my @nation_reports = ('actual', 'borders', 'near', 'diplomacy', 'events' );
my %nation_report_names = ('actual' => 'Status',
                           'borders' => 'Borders',
                           'near' => 'Military Range',
                           'diplomacy' => 'Diplomacy',
                           'events' => 'Events' 
                    );


get '/' => sub {
    template 'home';
};

get '/play/:game' => sub {
    my $meta = get_meta(params->{game});
    if($meta)
    {
        my $redirection = "/play/" . params->{game} . "/" . $meta->{'current_year'} . "/r/situation";
        redirect $redirection, 302;
    }
    else
    {
        pass;
    }
};
get '/play/:game/n' => sub {
    my $meta = get_meta(params->{game});
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
    my $meta = get_meta(params->{game});
    my $redirection = "/play/" . params->{game} . "/" . $meta->{'current_year'} . "/n/" . params->{nation};
        redirect $redirection, 302;
};
get '/play/:game/:year/:turn/r/:report' => sub {
    my $report_to_show = 'generated/' . 
                         params->{game} . '/' .
                         params->{year} . '/' .
                         params->{turn} . '/' .
                         params->{report} . '.tt'; 
    my $custom_js = undef;
    if(params->{report} eq 'situation')
    {
        $custom_js = "blocks/alldata.tt";
    }
    template 'report', {
       'report' => $report_to_show,
       'reports' => \@reports,
       'report_names' => \%report_names,
       'active' => params->{report},
       'game' => params->{game},
       'year' => params->{year},
       'turn' => params->{turn},
       'active_top' => 'year',
       'custom_js' => $custom_js
    }; 
};
get '/play/:game/:year/:turn/n/:nation' => sub {
        my $redirection = "/play/" . params->{game} . "/" . params->{year} . "/" . params->{turn} . "/n/" . params->{nation} . "/actual";
        redirect $redirection, 302;
};


get '/play/:game/:year/:turn/n/:nation/:report' => sub {
    my $meta = get_meta(params->{game});
    my $nation_name;
    for(keys %{$meta->{nations}})
    {    
        if($meta->{nations}->{$_}->{'code'} eq params->{nation})
        {
            $nation_name = $_;
        }
    }
    my $report_to_show = 'generated/' . 
                         params->{game} . '/' .
                         params->{year} . '/' .
                         params->{turn} . '/' .
                         params->{nation} . '/'.
                         params->{report} . '.tt'; 
    my $custom_js = undef;
    template 'nation_report', {
       'report' => $report_to_show,
       'reports' => \@nation_reports,
       'report_names' => \%nation_report_names,
       'active' => params->{report},
       'game' => params->{game},
       'year' => params->{year},
       'nation' => params->{nation},
       'turn' => params->{turn},
       'active_top' => 'nations',
       'custom_js' => $custom_js,
       'nation_name' => $nation_name,
    }; 

};


sub get_meta
{
    my $game = shift;
    my $meta = $metadata_path . '/' . $game . '.meta';
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
        my @user_games = schema->resultset("UserGame")->search({ user => $user_db->id });
        if(@user_games)
        {
            my $game = schema->resultset("BopGame")->find($user_games[0]->game);
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


true;
