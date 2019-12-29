package ScanMate;
use Mojo::Base 'Mojolicious';

sub startup {
  my ($app) = @_;

  $app->moniker('scanmate');

  push @{$app->commands->namespaces}, 'ScanMate::Command';
  push @{$app->static->paths}, $app->home->child('scans');

  $app->plugin('Config' => {
    default => {
      secrets   => [],
      postgres  => "postgresql://scanmate:notasecret\@localhost/scanmate",
      authorize => "scanmate:notasecret",
    }
  });

  $app->secrets($app->config('secrets'));

  $app->plugin('Minion' => {
    Pg => $app->config('postgres')
  });

  $app->plugin('ScanMate::Routes');
  $app->plugin('ScanMate::Tasks');
}

1;
