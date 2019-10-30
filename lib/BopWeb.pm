package BopWeb;
use Mojo::Base 'Mojolicious';


# This method will run once at server start
sub startup {
    my $self = shift;

    $self->plugin('TemplateToolkit');
    $self->renderer->default_handler('tt2');
    $self->defaults(layout => 'bop');

    # Load configuration from hash returned by config file
    my $config = $self->plugin('Config');

    # Configure the application
    $self->secrets($config->{secrets});

    # Router
    my $r = $self->routes;
     
    # Normal route to controller
    $r->get('/:game/:year/:quarter/news' => sub {
        my $c = shift;
        $c->render(template => 'bop/newspaper');
    });
#    $r->get('/ch/:game/:year/:quarter' => sub {
#        my $c = shift;
#        $c->render(template => 'bop/combo_history');
#    });
    $r->get('/:game/:year/:quarter/hs' => sub {
        my $c = shift;
        $c->stash(document => "hotspots.tt");
        $c->render(template => 'bop/report');
    });
    $r->get('/:game/:year/:quarter/al' => sub {
        my $c = shift;
        $c->stash(document => "alliances.tt");
        $c->render(template => 'bop/report');
    });
    $r->get('/:game/:year/:quarter/inf' => sub {
        my $c = shift;
        $c->stash(document => "influences.tt");
        $c->render(template => 'bop/report');
    });
    $r->get('/:game/:year/:quarter/sup' => sub {
        my $c = shift;
        $c->stash(document => "supports.tt");
        $c->render(template => 'bop/report');
    });
    $r->get('/:game/:year/:quarter/rsup' => sub {
        my $c = shift;
        $c->stash(document => "rebel-supports.tt");
        $c->render(template => 'bop/report');
    });



}

1;
