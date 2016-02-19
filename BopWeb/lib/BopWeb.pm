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

my @reports = ('situation', 'hotspots');
my %report_names = ('situation' => 'situation',
                    'hotspots' => 'hotspots');

get '/' => sub {
    template 'home';
};

get '/:game' => sub {
    my $meta = $metadata_path . '/' . params->{game} . '.meta';
    debug "Game found";
    if(-e $meta)
    {
        open my $metafile, '<', $meta || die $!;
        debug "Opening $meta";
        my $data;
        {
            local $/;    # slurp mode
            my $metafile_data = <$metafile>;
            debug "In the file: $metafile_data";
            my $VAR1;
            eval $metafile_data;
            debug Dumper($data);
            my $redirection = "/" . params->{game} . "/" . $VAR1->{'current_year'} . "/situation";
            redirect $redirection, 301;
        }
    }
    else
    {
        pass;
    }
};

get '/:game/:year/:turn/:report' => sub {
    my $report_to_show = 'generated/' . 
                         params->{game} . '/' .
                         params->{year} . '/' .
                         params->{turn} . '/' .
                         params->{report} . '.tt'; 
    template 'general', {
       'report' => $report_to_show,
       'reports' => \@reports,
       'report_names' => \%report_names,
       'active' => params->{report},
       'game' => params->{game},
       'year' => params->{year},
       'turn' => params->{turn}
    }; 
};


true;
