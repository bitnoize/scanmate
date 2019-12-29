package ScanMate::Controller::SiteMain;
use Mojo::Base 'Mojolicious::Controller';

sub index {
  my ($c) = @_;

  $c->stash(minion_stats => $c->app->minion->stats);
  $c->render(template => "main/index", format => 'txt');
}

1;
