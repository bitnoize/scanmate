package ScanMate::Nmap;
use Mojo::Base "Mojolicious::Plugin";

use IPC::Run3;
use Mojo::IOLoop::Subprocess;

sub register {
  my ($self, $app) = @_;

  $app->minion->add_task(scan => sub {
    my ($job, $spec, $base, @targets) = @_;

    return $job->fail("Required params missing")
      unless $spec and $base and @targets;

    my %cmd = (
      fast => [
        'nmap', '-sT', '-sU', '-oA', $base, '--top-ports', 100, '-iL', '-' 
      ],


    );

    return $job->fail("Wrong spec '$spec' param")
      unless my $cmd = $cmd{$spec};

    return $job->retry({ delay => 300 })
      unless $app->minion->lock('concurrent', 300, { limit => 10 });

    my $subprocess = Mojo::IOLoop::Subprocess->new;

    $subprocess->run(
      sub {
        my ($subprocess) = @_;

        my $output;

        run3 $cmd, \@targets, \$output, \$output, {
          return_if_system_error => 1
        };

        return $output unless $?;
        die "Failed status: $? message: $!\n";
      },

      sub {
        my ($subprocess, $error, @result) = @_;
        $error ? $job->fail($error) : $job->finish(\@result);
      }
    );

    $subprocess->ioloop->start unless $subprocess->ioloop->is_running;
  });
}

1;
