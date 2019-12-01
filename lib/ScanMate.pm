package ScanMate;
use Mojo::Base "Mojolicious";

sub startup {
  my ($app) = @_;

  $app->moniker("scanmate");

  push @{$app->commands->namespaces}, "ScanMate::Command";

  $app->plugin("Config" => {
    default => {
      secrets   => [],
      postgres  => "postgresql://scanmate:notasecret\@localhost/scanmate",

      nmap_bin  => "/usr/bin/nmap",
      nmap_top_ports  => 1024,
    }
  });

  $app->secrets($app->config('secrets'));

  $app->plugin("Minion" => {
    Pg => $app->config('postgres')
  });

  $app->plugin("Minion::Admin");
  $app->plugin("ScanMate::Nmap");
}

1;
