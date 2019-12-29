package ScanMate::Routes;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Util qw/secure_compare/;

sub register {
  my ($self, $app) = @_;

  $app->types->type(nmap  => "text/plain");

  my $r = $app->routes;

  my $base = $r->under->to(
    cb => sub {
      my ($c) = @_;

      $c->reply->exception("Authorization misconfigured")
        unless my $authorize = $app->config('authorize');

      my $userinfo = $c->req->url->to_abs->userinfo || "";

      return 1 if secure_compare $authorize, $userinfo;

      $c->res->headers->www_authenticate("Basic");
      $c->render(text => 'Authorization required', status => 401);

      return 0;
    }
  );

  $base->get("/")->to('site_main#index')->name('site_main');

  $base->get("/scan/*filename" => { filename => '' })->to(
    cb => sub {
      my ($c) = @_;

      my $filename = $c->stash('filename');

      $c->reply->file($app->home->child('scans', $filename));
    }
  );
}

1;
