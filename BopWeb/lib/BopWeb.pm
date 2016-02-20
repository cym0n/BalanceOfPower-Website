package BopWeb;
use lib "/home/cymon/works/nations/repo/src/lib";
use Dancer2;
use Cwd 'abs_path';
use Data::Dumper;
use BalanceOfPower::Utils qw (prev_turn);

our $VERSION = '0.1';

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
        redirect $redirection, 301;
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

get '/play/:game/:year/:turn/r/:report' => sub {
    my $report_to_show = 'generated/' . 
                         params->{game} . '/' .
                         params->{year} . '/' .
                         params->{turn} . '/' .
                         params->{report} . '.tt'; 
    template 'report', {
       'report' => $report_to_show,
       'reports' => \@reports,
       'report_names' => \%report_names,
       'active' => params->{report},
       'game' => params->{game},
       'year' => params->{year},
       'turn' => params->{turn},
       active_top => 'year'
    }; 
};
get '/play/:game/:year/:turn/n/:nation' => sub {
        my $redirection = "/play/" . params->{game} . "/" . params->{year} . "/" . params->{turn} . "/n/" . params->{nation} . "/actual";
        redirect $redirection, 301;
};


get '/play/:game/:year/:turn/n/:nation/:report' => sub {
    my $report_to_show = 'generated/' . 
                         params->{game} . '/' .
                         params->{year} . '/' .
                         params->{turn} . '/' .
                         params->{nation} . '/'.
                         params->{report} . '.tt'; 
    template 'nation_report', {
       'report' => $report_to_show,
       'reports' => \@nation_reports,
       'report_names' => \%nation_report_names,
       'active' => params->{report},
       'game' => params->{game},
       'year' => params->{year},
       'nation' => params->{nation},
       'turn' => params->{turn},
       active_top => 'nations'
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
true;
