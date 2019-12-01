package ScanMate::Nmap;
use Mojo::Base "Mojolicious::Plugin";

use Mojo::IOLoop::Subprocess;

our @nmap = ("nmap", "-sV", "-sT", "-oX", "/tmp/test.xml", "-oN", "/tmp/test.txt", "--top-ports", 10);

sub register {
  my ($self, $app) = @_;

  $app->minion->add_task(nmap_script => sub {
    my ($job, $output, $port, $target) = @_;

    return $job->retry({ delay => 300 })
      unless $app->minion->lock('default', 300, { limit => 10 });

    my $subprocess = Mojo::IOLoop::Subprocess->new;

    $subprocess->run(
      sub {
        my ($subprocess) = @_;

        my @command = $app->config('nmap_bin');

        my $out = Mojo::File->new($app->config('nmap_output'));

        $out_xml->child(sprintf "%s.xml", $output)->to_abs;
        $out_txt->child(sprintf "%s.xml", $output)->to_abs;

        push @command, "-oN", $output->child(sprintf "%s.xml", $output);
        push @command, @nmap_basic;

        my $output = `@command`;
      },

      sub {
        my ($subprocess, $error, @results) = @_;
        $error ? $job->fail($error) : $job->finish(\@results);
      }
    );

    $subprocess->ioloop->start unless $subprocess->ioloop->is_running;
  });
}

1;
