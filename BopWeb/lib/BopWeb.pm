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
use DateTime;
use List::Util qw(shuffle);

use BalanceOfPower::Utils qw (prev_turn);
use BalanceOfPower::Constants ':all';;

our $VERSION = '0.1';

get '/keepalive' => sub {
    return 'OK';
};



### GAME

my $module_file_path = __FILE__;
my $root_path = abs_path($module_file_path);
$root_path =~ s/lib\/BopWeb\.pm//;

my $metadata_path = $root_path . "metadata";
my @reports_menu = ('r/situation', 'r/newspaper', 'r/hotspots', 'r/alliances', 'r/influences', 'r/supports', 'r/rebel-supports', 'r/combo-history', 'r/prices' );
my @nation_reports_menu = ('n/actual', 'n/borders', 'n/near', 'n/diplomacy', 'n/events', 'n/graphs', 'n/prices' );
my @player_reports_menu = ('r/market', 'p/stocks', 'p/targets', 'p/events', 'db/orders', 'p/ranking', 'p/graphs' );

my @products = ( 'goods', 'luxury', 'arms', 'tech', 'culture' );


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
            'r/civil-war-history' => {
               menu_name => 'Civil War History',
            },
            'r/combo-history' => {
                menu_name => 'War History',
                template => 'combo_history.tt'
            },
            'r/events' => {
               menu_name => 'Events',
            },
            'r/newspaper' => {
               menu_name => 'Newspaper',
               template => 'newspaper',
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
            'n/graphs' => {
                menu_name => 'Graphs'
            },
            'n/prices' => {
                menu_name => 'Shop Prices'
            },
            'r/market' => {
                menu_name => 'Market',
                menu => \@player_reports_menu,
                active_top => 'market',
                logged => 1
            },
            'r/prices' => {
               menu_name => 'Shop Prices',
               custom_js => 'blocks/alldata.tt'
            },
            'p/stocks' => {
                menu_name => 'My Stocks',
                logged => 1,
               custom_js => 'blocks/stockdata.tt'
            },
            'p/targets' => {
                menu_name => 'Targets',
            },
            'p/events' => {
                menu_name => 'Events',
                logged => 1
            },
            'p/ranking' => {
                menu_name => 'Players',
                logged => 1,
                title => 'year',
                custom_js => 'blocks/players.tt',
            },
            'p/graphs' => {
                menu_name => 'Graphs'
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
    
    for(keys %{$standards})
    {
        if(! exists $report_conf->{$_})
        {
            $report_conf->{$_} = $standards->{$_}
        }
    }
    if($report_conf->{logged} == 1)
    {
        if(! player_of_game(params->{game}, $user))
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
       'interactive' => player_of_game(params->{game}, $user),
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
    for(keys %{$standards})
    {
        if(! exists $report_conf->{$_})
        {
            $report_conf->{$_} = $standards->{$_}
        }
    }
    if($report_conf->{logged} == 1)
    {
        if(! player_of_game(params->{game}, $user))
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
       'page_title' => $page_title,
       'stock_orders' => \@stock_orders,
       'influence_orders' => \@influence_orders,
       'context' => params->{context},
       'nation_codes' => get_nation_codes($meta->{nations}),
       'deletestock' => params->{'delete-stock'},
       'deleteinfluence' => params->{'delete-influence'},
    }; 
};

get '/play/:game/i/travel' => sub {
    my $user = session->read('user');
    my $usergame = player_of_game(params->{game}, $user);
    if(! $usergame)
    {
        send_error("Access denied", 403);
        return;
    }    
    my $shop_posted = params->{'shop-posted'};
    my $travel_posted = params->{'travel-posted'};
    my $err = params->{'err'};
    my $meta = get_metafile($metadata_path . '/' . params->{game} . '.meta');
    my ($year, $turn) = split '/', $meta->{'current_year'};
    my $codes = get_nation_codes($meta->{nations});
    my $player = schema->resultset('BopPlayer')->find($usergame->player);
    my $present_position = $codes->{$player->position};
    my $nation_meta = get_metafile($metadata_path . '/' . params->{game} . "/n/$present_position.data");

    my $travel_enabled;
    my $travel_enabled_time;
    my $print_travel_enabled;
    if(enable_to_travel($player->disembark_time))
    {
        $travel_enabled = 1;
    }
    else
    {
        $travel_enabled = 0;
        $travel_enabled_time = $player->disembark_time;    
        $travel_enabled_time->add( hours => 2 );
        $travel_enabled_time->set_time_zone('Europe/Rome');
        $print_travel_enabled = $travel_enabled_time->dmy . " " . $travel_enabled_time->hms;
    }

    my $template_data = {
        'player' => $user,
        'money' => $player->money,
        'nation_codes' => get_nation_codes($meta->{nations}),
        'position' => $player->position,
        'position_code' => $present_position,
        'game' => params->{game},
        'year' => $year,
        'turn' => $turn,
        'active_top' => 'travel',
        'custom_js' => undef,
        'context' => 'i',
        'products' => \@products,
        'travels' => $nation_meta->{'travels'},
        'prices' => $nation_meta->{'prices'},
        'travel_enabled' => $travel_enabled,
        'travel_enabled_time' => $print_travel_enabled,
        'shop_posted' => $shop_posted,
        'travel_posted' => $travel_posted,
        'err' => $err
    };
    if($player->destination)
    {
        my $arrival = $player->arrival_time;
        my $arrived = 0;
        if(DateTime->compare(DateTime->now, $arrival) == 1)
        {
            $arrived = 1;
        }
        $arrival->set_time_zone('Europe/Rome');
        my $print_arrival = $arrival->dmy . " " . $arrival->hms;
        $template_data->{'destination'} = $player->destination;
        $template_data->{'arrival_time'} = $print_arrival;
        $template_data->{'arrived'} = $arrived;

        template 'ongoing_travel', $template_data;
    }
    else
    {
        my %hold = get_hold($player->id);
        $template_data->{'hold'} = \%hold;
        template 'travel', $template_data;
    }
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
    my $user = session->read('user');
    my $meta = get_metafile($metadata_path . '/' . params->{game} . '.meta');
    my ($year, $turn) = split '/', $meta->{'current_year'};
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
                year => $year,
                turn => $turn,
                active_top => 'nations',
                player => $user
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

sub get_hold
{
    my $player = shift;
    my $tot_q = 0;
    my %hold = ();
    foreach my $p (@products)
    {
        my $hold_element =  schema->resultset('Hold')->find({
                                player => $player, type => $p
                            });
        if($hold_element)
        {
            $hold{$p} = $hold_element->quantity;
            $tot_q += $hold_element->quantity;
        }
        else
        {
            $hold{$p} = 0;
        }
    }
    $hold{'free'} = CARGO_TOTAL_SPACE - $tot_q; 
    return %hold;
     
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
            redirect '/', 302;
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
        my @usergames = $user_db->usergames;
        if(@usergames == 1)
        {
            my $ugame = $usergames[0];
            redirect '/play/' . $ugame->game->file;
            return;
        }
        elsif(@usergames == 0)
        {
            redirect '/users/choose-game';
            return;
        }
        else
        {
            my @games = ();
            debug("More than one game!");
            for(@usergames)
            {
                push @games, $_->game;
            }
            return template 'my_games', { games => \@games };
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
    my @games = schema->resultset("BopGame")->search({ active => 1,
                                                       open => 1});
    my @available_games = grep { ! player_of_game($_->file, $user) } @games;
    template 'choose_game', {
        games => \@available_games,
        not_invited => params->{'not-invited'}
    }
};

get '/users/play-game' => sub {
    my $user = session->read('user');
    if($user)
    {
        my $user_db = schema->resultset("BopUser")->find({ user => $user });
        my $game = params->{game};
        my $game_db = schema->resultset("BopGame")->find($game);
        redirect '/play/' . $game_db->file;
    }
    else
    {
        redirect '/users/login', 302;
    }
};

get '/users/select-game' => sub {
    my $user = session->read('user');
    if($user)
    {
        my $user_db = schema->resultset("BopUser")->find({ user => $user });
        my $game_db = schema->resultset("BopGame")->find(params->{game});
        my @user_games = schema->resultset("UserGame")->search({ user => $user_db->id, game => $game_db->id });
        if(@user_games)
        {
            redirect '/users/logged', 302;
            return;
        }
        else
        {
            if(! $game_db->active || ! $game_db->open)
            {
                send_error("Access denied", 403);
                return;
            }
            if($game_db->invite_password && $game_db->invite_password ne params->{password})
            {
                redirect '/users/choose-game?not-invited=1';
                return;
            }
            my $meta = get_metafile($metadata_path . '/' . $game_db->name . '.meta');
            my @nations = keys %{$meta->{'nations'}};
            @nations = shuffle @nations;
            my $player = schema->resultset("BopPlayer")->create({ money =>  START_PLAYER_MONEY, position => $nations[0] });
            schema->resultset("UserGame")->create({ user => $user_db->id, game => $game_db->id, player => $player->id });
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
        my $player = schema->resultset('BopPlayer')->find($_->player);
        push @out, { username => $_->user->user, position => $player->position, money => $player->money };
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

post '/api/:game/user-data' => sub {
    my $game = params->{game};
    my $user = params->{player};
    my $password = params->{password};
    my $money = params->{money};
    my $game_db = schema->resultset("BopGame")->find({ file => $game });
    if($game_db->admin_password ne $password)
    {
         send_error("Access denied", 403);
         return;
    }
    my $usergame = player_of_game($game, $user);
    if(! $usergame)
    {
         send_error("Bad request", 400);
         return;
    }
    my $player_db = schema->resultset("BopPlayer")->find($usergame->player);
    $player_db->money($money);
    $player_db->update();
    return 'OK';
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

post '/interact/:game/shop-command' => sub {
    my $user = session->read('user');
    my $usergame = player_of_game(params->{game}, $user);
    if(! $usergame)
    {
        send_error("Access denied", 403);
        return;
    }
    my $game = params->{game};
    my $meta = get_metafile($metadata_path . '/' . params->{game} . '.meta');
    my ($year, $turn) = split '/', $meta->{'current_year'};
    my $command = lc(params->{command});
    my $type = params->{type};
    my $quantity = params->{quantity};
    if(! $command || ! $type || ! $quantity)
    { 
        my $redirection = "/play/" . params->{game} . "/i/travel?shop-posted=ko&err=no-input";
        redirect $redirection, 302;
        return;  
    }
    my $codes = get_nation_codes($meta->{nations});
    my $player = schema->resultset('BopPlayer')->find($usergame->player);
    my $present_position = $codes->{$player->position};
    my $nation_meta = get_metafile($metadata_path . '/' . params->{game} . "/n/$present_position.data");
    my %hold = get_hold($player->id);
    my $money = $player->money;
    my $price_label = $type . "_price";
    my $price = $nation_meta->{prices}->{$price_label};
    my $cost = $price * $quantity; 
    if($command eq 'buy')
    {
        if($cost > $money)
        {
            my $redirection = "/play/" . params->{game} . "/i/travel?shop-posted=ko&err=no-money";
            redirect $redirection, 302;
            return;  
        }
        if($quantity > $hold{'free'})
        {
            my $redirection = "/play/" . params->{game} . "/i/travel?shop-posted=ko&err=no-space";
            redirect $redirection, 302;
            return;  
        }
        add_money(schema, $player->id, -1 * $cost);
        add_cargo(schema, $player->id, $type, $quantity);
        my $redirection = "/play/" . params->{game} . "/i/ravel?shop-posted=ok";
        redirect $redirection, 302;
        return;  
    }
    elsif($command eq 'sell')
    {
        if($quantity > $hold{$type})
        {
            my $redirection = "/play/" . params->{game} . "/i/travel?shop-posted=ko&err=not-owned";
            redirect $redirection, 302;
            return;  
        }
        add_money(schema, $player->id, $cost);
        add_cargo(schema, $player->id, $type, -1 * $quantity);
        my $redirection = "/play/" . params->{game} . "/i/travel?shop-posted=ok";
        redirect $redirection, 302;
        return;  
    }
    else
    {
        my $redirection = "/play/" . params->{game} . "/i/travel?shop-posted=ko&err=no-input";
        redirect $redirection, 302;
        return;  
    }
};

post '/interact/:game/go' => sub {
    my $user = session->read('user');
    my $usergame = player_of_game(params->{game}, $user);
    if(! $usergame)
    {
        send_error("Access denied", 403);
        return;
    }
    my $game = params->{game};
    my $meta = get_metafile($metadata_path . '/' . params->{game} . '.meta');
    my ($year, $turn) = split '/', $meta->{'current_year'};
    my $destination = params->{destination};
    if(! $destination)
    {
        my $redirection = "/play/" . params->{game} . "/i/travel?travel-posted=ko&err=no-destination";
        redirect $redirection, 302;
        return;  
    }

    my $codes = get_nation_codes($meta->{nations});
    my $player = schema->resultset('BopPlayer')->find($usergame->player);
    if(! enable_to_travel($player->disembark_time))
    {
        my $redirection = "/play/" . params->{game} . "/i/travel?travel-posted=ko&err=not-ready-to-travel";
        redirect $redirection, 302;
        return;  
    }
    my $present_position = $codes->{$player->position};
    my $nation_meta = get_metafile($metadata_path . '/' . params->{game} . "/n/$present_position.data");
    my $data;
    $data = exists $nation_meta->{'travels'}->{'air'}->{$destination} &&  $nation_meta->{'travels'}->{'air'}->{$destination}->{'status'} eq 'OK' ? 
                $nation_meta->{'travels'}->{'air'}->{$destination} :
                    exists $nation_meta->{'travels'}->{'ground'}->{$destination} &&  $nation_meta->{'travels'}->{'ground'}->{$destination}->{'status'} eq 'OK' ?
                        $nation_meta->{'travels'}->{'ground'}->{$destination} :
                            undef;
    if(! $data)
    {
        my $redirection = "/play/" . params->{game} . "/i/travel?travel-posted=ko&err=bad-destination";
        redirect $redirection, 302;
        return;  
    }
    my $time = DateTime->now();
    $time->add( hours => $data->{cost});
    $player->destination($destination);
    $player->arrival_time($time);
    $player->update;
    my $redirection = "/play/" . params->{game} . "/i/travel?travel-posted=ok&err=posted";
    redirect $redirection, 302;
    return;  
};

get '/interact/:game/arrive' => sub {
    my $user = session->read('user');
    my $usergame = player_of_game(params->{game}, $user);
    if(! $usergame)
    {
        send_error("Access denied", 403);
        return;
    }
    my $game = params->{game};
    my $player = schema->resultset('BopPlayer')->find($usergame->player);
    my $arrival = $player->arrival_time;
    if(DateTime->compare(DateTime->now, $arrival) == 1)
    {
        $player->position($player->destination);
        $player->destination(undef);
        $player->arrival_time(undef);
        $player->disembark_time(DateTime->now);
        $player->update();
        my $redirection = "/play/" . params->{game} . "/i/travel?travel-posted=ok&err=arrived";
        redirect $redirection, 302;
        return;  
    }
    else
    {
        my $redirection = "/play/" . params->{game} . "/i/travel?travel-posted=ko&err=not-arrived";
        redirect $redirection, 302;
        return;  
    }
};

sub add_money
{
    my $schema = shift;
    my $player = shift;
    my $money = shift;
    my $player_obj = $schema->resultset('BopPlayer')->find($player);
    my $new_money = $player_obj->money + $money;
    $player_obj->money($new_money);
    $player_obj->update();
}
sub add_cargo
{
    my $schema = shift;
    my $player = shift;
    my $type = shift;
    my $q = shift;
    my $cargo_obj = $schema->resultset('Hold')->find({ player => $player,
                                                       type => $type });
    if(! $cargo_obj)
    {
        $schema->resultset('Hold')->create({ player => $player,
                                           type => $type,
                                           quantity => $q });
    }
    else
    {
        my $new_q = $cargo_obj->quantity + $q;
        $cargo_obj->quantity($new_q);
        $cargo_obj->update;
    }
}

sub enable_to_travel
{
    my $disembark_time = shift;
    return 1 if ! $disembark_time;
    
    my $enable_to_travel = $disembark_time->clone;
    $enable_to_travel->add( hours => 2);
    return DateTime->compare(DateTime->now, $enable_to_travel) == 1
}



post '/interact/:game/stock-command' => sub {
    my $user = session->read('user');
    if(! player_of_game(params->{game}, $user))
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
          nation => $data->{nation},
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
    if(! player_of_game(params->{game}, $user))
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
    if(! player_of_game(params->{game}, $user))
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
    if(! player_of_game(params->{game}, $user))
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

sub player_of_game
{
    my $game = shift;
    my $user = shift;
    return undef if ! defined $user;
    my $game_db = schema->resultset("BopGame")->find({ file => $game });
    my $user_db = schema->resultset("BopUser")->find({ user => $user });
    return undef if(! $game_db || ! $user_db);
    my $usergame = schema->resultset("UserGame")->find({ user => $user_db->id, game => $game_db->id });
    if($usergame)
    {
        return $usergame;
    }
    else
    {
        return undef;    
    }
}



true;
