package BopWeb;
use lib "/home/cymon/works/nations/repo/src/lib";
use Dancer2;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::Ajax;

use Cwd 'abs_path';
use HTML::FormFu;
use Data::Dumper;
use Dancer2::Serializer::JSON;
use Authen::Passphrase::BlowfishCrypt;

use BalanceOfPower::Utils qw (prev_turn);

our $VERSION = '0.1';

get '/keepalive' => sub {
    return 'OK';
};



### GAME

my $module_file_path = __FILE__;
my $root_path = abs_path($module_file_path);
$root_path =~ s/lib\/BopWeb\.pm//;

my $metadata_path = $root_path . "metadata";
my @reports_menu = ('r/situation', 'r/hotspots', 'r/alliances', 'r/influences', 'r/supports', 'r/rebel-supports', 'r/war-history', 'r/events' );
my @nation_reports_menu = ('n/actual', 'n/borders', 'n/near', 'n/diplomacy', 'n/events' );
my @player_reports_menu = ('r/market', 'p/stocks', 'p/events', 'db/orders', 'p/ranking' );

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

sub nation_from_code
{
    my $code = shift;
    my $nations = shift;
    for(keys %{$nations})
    {
        if($nations->{$_}->{code} eq $code)
        {
            return $_;
        }
    }
}

get '/' => sub {
    my $user = session->read('user');
    template 'home', { player => $user };
};

get '/about' => sub {
    template 'about';
};


### REPORTS

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
               menu_name => 'Status',
               custom_js => 'blocks/commands.tt'
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
            },
            'p/ranking' => {
                menu_name => 'Players',
                logged => 1,
                title => 'year',
                custom_js => 'blocks/players.tt',
            },
            'db/orders' => {
                menu_name => 'My Orders',
                logged => 1,
                template => 'orders_report.tt',
            }
    );

get '/play/:game/:context/:report' => sub {
    my $report_id = params->{context} . '/' . params->{report};
    my $meta = get_metafile($metadata_path . '/' . params->{game} . '.meta');
    my ($year, $turn) = split '/', $meta->{'current_year'};
    my $context = params->{context};
    my $user = session->read('user');
    my $nation = params->{nation};
    my $nation_name;
    if($context ne 'r' && $context ne 'p' && $context ne 'n')
    {
        pass;
    }
    if($nation)
    {
        $nation_name = nation_from_code($nation, $meta->{nations});
    }

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
    }
    my $obj_dir = "";
    if($context eq 'n')
    {
        $obj_dir = "n/$nation/";
    }
    elsif($context eq 'p')
    {
        $obj_dir = "p/$user/";
    }
    my $report_to_show = 'generated/' . 
                         params->{game} . '/' .
                         $year . '/' .
                         $turn . '/' . 
                         $obj_dir .
                         params->{report} . '.tt'; 
    my $page_title;
    if($report_conf->{'title'} eq 'year')
    {
        $page_title = $year . '/' . $turn;
    }
    elsif($report_conf->{'title'} eq 'nation')
    {
        $page_title = "$nation_name - $year/$turn";
    }
    elsif($report_conf->{'title'} eq 'player')
    {
        $page_title = $user;
    }
    my ($menu, $ordered) = make_menu($report_conf->{menu}, $nation);
    my $wallet = undef;
    my $nation_meta = undef;
    my $selected_stock_action = undef;
    my $selected_influence_action = undef;
    if(params->{context} eq 'n' && $user)
    {
        $wallet = get_metafile($metadata_path . '/' . params->{game} . "/p/$user-wallet.data");
        $nation_meta = get_metafile($metadata_path . '/' . params->{game} . "/n/$nation.data");
        $selected_stock_action = schema->resultset('StockOrder')->find({
                game => params->{game},
                user => $user,
                turn => "$year/$turn",
                nation => nation_from_code($nation, $meta->{nations})
            });
        $selected_stock_action = $selected_stock_action->as_string() if($selected_stock_action);
        $selected_influence_action = schema->resultset('InfluenceOrder')->find({
                game => params->{game},
                user => $user,
                turn => "$year/$turn",
                nation => nation_from_code($nation, $meta->{nations})
            });
        $selected_influence_action = $selected_influence_action->as_string() if($selected_influence_action);
    }
    template $report_conf->{template}, {
       'nation' => $nation,
       'report' => $report_to_show,
       'menu' => $menu,
       'menu_urls' => $ordered,
       'active' => $report_id,
       'game' => params->{game},
       'year' => $year,
       'turn' => $turn,
       'active_top' => $report_conf->{active_top},
       'custom_js' => $report_conf->{custom_js},
       'player' => $user,
       'page_title' => $page_title,
       'wallet' => $wallet,
       'context' => params->{context},
       'stockposted' => params->{'stock-posted'},
       'influenceposted' => params->{'influence-posted'},
       'nation_meta' => $nation_meta,
       'selected_stock_action' => $selected_stock_action,
       'selected_influence_action' => $selected_influence_action,
    }; 
};

get '/play/:game/db/orders' => sub {
    my $report_id = 'db/orders';
    my $game = params->{game};
    my $meta = get_metafile($metadata_path . '/' . params->{game} . '.meta');
    my ($year, $turn) = split '/', $meta->{'current_year'};
    my $context = 'db';
    my $user = session->read('user');
    my $standards = get_report_standard_from_context(params->{context});
    my $report_conf = $report_configuration{$report_id};
    my $nation = undef;
    my $nation_name = undef;
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
    }
    my $page_title;
    if($report_conf->{'title'} eq 'year')
    {
        $page_title = $year . '/' . $turn;
    }
    elsif($report_conf->{'title'} eq 'nation')
    {
        $page_title = "$nation_name - $year/$turn";
    }
    elsif($report_conf->{'title'} eq 'player')
    {
        $page_title = $user;
    }
    my ($menu, $ordered) = make_menu($report_conf->{menu}, undef);
    my @stock_orders = schema->resultset('StockOrder')->search({
                            game => $game,
                            user => $user,
                            turn => $meta->{current_year} });
    my @influence_orders = schema->resultset('InfluenceOrder')->search({
                            game => $game,
                            user => $user,
                            turn => $meta->{current_year} });
    template $report_conf->{template}, {
       'player' => $user,
       'menu' => $menu,
       'menu_urls' => $ordered,
       'active' => $report_id,
       'game' => params->{game},
       'year' => $year,
       'turn' => $turn,
       'active_top' => $report_conf->{active_top},
       'custom_js' => $report_conf->{custom_js},
       'player' => $user,
       'page_title' => $page_title,
       'stock_orders' => \@stock_orders,
       'influence_orders' => \@influence_orders,
       'context' => params->{context},
       'nation_codes' => get_nation_codes($meta->{nations}),
       'deletestock' => params->{'delete-stock'},
       'deleteinfluence' => params->{'delete-influence'},
       'custom_js' => $report_conf->{custom_js},
    }; 
};


get '/play/:game' => sub {
    my $meta = get_metafile($metadata_path . '/' . params->{game} . '.meta');
    if($meta)
    {
        my $redirection = "/play/" . params->{game} . "/r/situation";
        redirect $redirection, 302;
    }
    else
    {
        pass;
    }
};

get '/play/:game/n' => sub {
    my $nation = params->{nation};
    my $meta = get_metafile($metadata_path . '/' . params->{game} . '.meta');
    if($meta)
    {
        if($nation)
        {
            my $redirection = "/play/" . params->{game} . "/n/actual?nation=" . $nation;
            redirect $redirection, 302;
        }
        else
        {
            template 'nations', {
                areas => ['North America', 'South America', 'Europe', 'Africa', 'Middle East', 'Far East', 'Pacific'],
                nations => $meta->{nations},
                game => params->{game},
                year => $meta->{'current_year'},
                active_top => 'nations'
            }
        }
    }
    else
    {
        pass;
    }
};

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
    }
    elsif($context eq 'n')
    {
        $menu = \@nation_reports_menu,
        $title = 'nation';
        $active_top = 'nations';
    }
    elsif($context eq 'p')
    {
        $menu = \@player_reports_menu,
        $title = 'player';
        $active_top = 'market';
    }
    elsif($context eq 'db')
    {
        $menu = \@player_reports_menu,
        $title = 'player';
        $active_top = 'market';
    }
    return { title => $title, 
             menu => $menu,
             template => 'report',
             custom_js => undef,
             active_top => $active_top,
             logged => 0,
           };
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
        $out{$_} = $report_configuration{$_}->{menu_name};
        push @order, $_;
    }
    return (\%out, \@order);
}

sub get_nation_codes
{
    my $nations = shift;
    my %out = ();
    foreach my $n (keys %{$nations})
    {
        $out{$n} = $nations->{$n}->{'code'};
    }
    return \%out;
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
    template 'register', {
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
    template 'login', {
        form => $form->render(),
        message => $message
    }
};

get '/users/logged' => sub {
    my $user = session->read('user');
    if($user)
    {
        my $user_db = schema->resultset("BopUser")->find({ user => $user });
        my $usergame = $user_db->usergames;
        if($usergame)
        {
            my $game = $usergame->first->game;
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

get '/users/logout' => sub {
     session 'user' => undef;
     redirect '/', 302;
     return;
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

get '/api/:game/stock-orders' => sub {
     my $game = params->{game};
     my $user = params->{player};
     my $password = params->{password};
     my $meta = get_metafile($metadata_path . '/' . params->{game} . '.meta');
     my $game_db = schema->resultset("BopGame")->find({ file => $game });
     if($game_db->admin_password ne $password)
     {
          send_error("Access denied", 403);
          return;
     }
     my @orders = schema->resultset('StockOrder')->search({
                        game => $game,
                        user => $user,
                        turn => $meta->{current_year} });
     my @out = ();
     for(@orders)
     {
         push @out, $_->as_string()
     }
     content_type('application/json');
     return serialize(\@out, undef);
};

get '/api/:game/influence-orders' => sub {
     my $game = params->{game};
     my $user = params->{player};
     my $password = params->{password};
     my $meta = get_metafile($metadata_path . '/' . params->{game} . '.meta');
     my $game_db = schema->resultset("BopGame")->find({ file => $game });
     if($game_db->admin_password ne $password)
     {
          send_error("Access denied", 403);
          return;
     }
     my @orders = schema->resultset('InfluenceOrder')->search({
                        game => $game,
                        user => $user,
                        turn => $meta->{current_year} });
     my @out = ();
     for(@orders)
     {
         push @out, { nation => $_->nation,
                      command =>  $_->as_string() };
     }
     content_type('application/json');
     return serialize(\@out, undef);
};



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

### ACTIONS

post '/interact/:game/stock-command' => sub {
    my $user = session->read('user');
    if(! $user)
    {
        send_error("Access denied", 403);
        return;
    }
    my $game = params->{game};
    my $meta = get_metafile($metadata_path . '/' . params->{game} . '.meta');
    my ($year, $turn) = split '/', $meta->{'current_year'};
    my $command = params->{command};
    my $nation = params->{nation};
    my $quantity = params->{quantity};
    if(! $command || ! $quantity || ! $nation)
    { 
        my $redirection = "/play/" . params->{game} . "/n/actual?nation=" . params->{nation} . "&stock-posted=ko";
        redirect $redirection, 302;
        return;  
    }
    my $data = {
        game => $game,
        user => $user,
        command => $command,
        nation => nation_from_code($nation, $meta->{nations}),
        quantity => $quantity,
        turn => "$year/$turn",
        exec_order => 1
    };
    my $command_already = schema->resultset('StockOrder')->find(
        { game => $game,
          user => $user,
          turn => "$year/$turn" });
    debug("$game - $user - $turn ");
    if( $command_already )
    {
        $command_already->update($data);
    }
    else
    {
        schema->resultset('StockOrder')->create($data);
    }
    my $redirection = "/play/" . params->{game} . "/n/actual?nation=" . params->{nation} . "&stock-posted=ok";
    redirect $redirection, 302;
};

post '/interact/:game/influence-command' => sub {
    my $user = session->read('user');
    if(! $user)
    {
        send_error("Access denied", 403);
        return;
    }
    my $game = params->{game};
    my $meta = get_metafile($metadata_path . '/' . params->{game} . '.meta');
    my ($year, $turn) = split '/', $meta->{'current_year'};
    my $command = params->{orders};
    my $nation = params->{nation};
    my $target = params->{target};
    my $nation_meta = get_metafile($metadata_path . '/' . params->{game} . "/n/$nation.data");
    if(! $command || ! $nation)
    { 
        my $redirection = "/play/" . params->{game} . "/n/actual?nation=" . params->{nation} . "&influence-posted=ko";
        redirect $redirection, 302;
        return;  
    }
    if($nation_meta->{commands}->{$command}->{argument})
    {
        if(! $target)
        {
            my $redirection = "/play/" . params->{game} . "/n/actual?nation=" . params->{nation} . "&influence-posted=ko";
            redirect $redirection, 302;
            return;  
        }
    }
    my $data = {
        game => $game,
        user => $user,
        command => $command,
        nation => nation_from_code($nation, $meta->{nations}),
        target => $target,
        turn => "$year/$turn",
        exec_order => 1
    };
    my $command_already = schema->resultset('InfluenceOrder')->find(
        { game => $game,
          user => $user,
          turn => "$year/$turn",
          nation => nation_from_code($nation, $meta->{nations}) });
    if( $command_already )
    {
        debug("Updating existing influence order");
        $command_already->update($data);
    }
    else
    {
        schema->resultset('InfluenceOrder')->create($data);
    }
    my $redirection = "/play/" . params->{game} . "/n/actual?nation=" . params->{nation} . "&influence-posted=ok";
    redirect $redirection, 302;
};

get '/interact/:game/delete-stock-order' => sub {
    my $user = session->read('user');
    if(! $user)
    {
        send_error("Access denied", 403);
        return;
    }
    my $game = params->{game};
    my $command = schema->resultset('StockOrder')->find({ 
                        user => $user,
                        id => params->{id}
                  });
    if($command)
    {
        $command->delete;
        my $redirection = "/play/" . params->{game} . "/db/orders?delete-stock=ok";
            redirect $redirection, 302;
            return;
    }
    else
    {
        my $redirection = "/play/" . params->{game} . "/db/orders?delete-stock=ko";
            redirect $redirection, 302;
            return;
    }

}; 
get '/interact/:game/delete-influence-order' => sub {
    my $user = session->read('user');
    if(! $user)
    {
        send_error("Access denied", 403);
        return;
    }
    my $game = params->{game};
    my $command = schema->resultset('InfluenceOrder')->find({ 
                        user => $user,
                        id => params->{id}
                  });
    if($command)
    {
        $command->delete;
        my $redirection = "/play/" . params->{game} . "/db/orders?delete-influence=ok";
            redirect $redirection, 302;
            return;
    }
    else
    {
        my $redirection = "/play/" . params->{game} . "/db/orders?delete-influence=ko";
            redirect $redirection, 302;
            return;
    }

}; 


true;
