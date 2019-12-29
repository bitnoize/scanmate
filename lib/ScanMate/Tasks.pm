package ScanMate::Tasks;
use Mojo::Base "Mojolicious::Plugin";

use IPC::Run3;
use Mojo::IOLoop::Subprocess;

sub _sudo ($) {
  my ($opts) = @_;

  $opts->{sudo_bin} //= "/usr/bin/sudo";

  $opts->{sudo_bin};
}

sub _proxychains ($) {
  my ($opts) = @_;

  $opts->{proxychains_bin}    //= "/usr/bin/proxychains";
  $opts->{proxychains_config} //= 'default';

  my $config = Mojo::File->new('proxychains')->child(
    sprintf "%s.conf", $opts->{proxychains_config});

  $opts->{proxychains_bin}, '-f', $config->to_abs;
}

sub _nmap_common ($) {
  my ($opts) = @_;

  $opts->{nmap_bin}       //= "/usr/bin/nmap";
  $opts->{nmap_timing}    //= 'normal';
  $opts->{nmap_basename}  //= time;

  my $scans = Mojo::File->new('scans')->child($opts->{nmap_basename});

  $opts->{nmap_bin}, '-n', '-iL', '-',
    '-T', $opts->{nmap_timing}, '-oA', $scans->to_abs;
}

sub _nmap_fastscan ($) {
  my ($opts) = @_;

  '-sN';
}

sub _nmap_connscan ($) {
  my ($opts) = @_;

  '-sT', '-sV', '-P0';
}

sub _nmap_synscan ($) {
  my ($opts) = @_;

  '-sS', '-sU', '-sV'
}

sub _nmap_ports ($) {
  my ($opts) = @_;

  $opts->{nmap_ports} //= 1000;

  ref $opts->{ports}
    ? ('-p', join ',', @{$opts->{nmap_ports}})
    : ('--top-ports', $opts->{nmap_ports});
}

sub _nmap_scripts ($) {
  my ($opts) = @_;

  return;
}

sub assembly {
  my ($self, $preset, $opts) = @_;

  my %dispatch = (
    scan_fast => sub {
      $opts->{nmap_timing}  //= 'aggressive';

      [
        _sudo           $opts,
        _nmap_common    $opts,
        _nmap_fastscan  $opts,
      ]
    },

    scan_proxy => sub {

      [
        _sudo           $opts,
        _proxychains    $opts,
        _nmap_common    $opts,
        _nmap_connscan  $opts,
        _nmap_ports     $opts,
      ];
    },

    scan_stealth => sub {

      [
        _sudo           $opts,
        _nmap_common    $opts,
        _nmap_synscan   $opts,
        _nmap_ports     $opts
      ];
    }
  );

  $dispatch{$preset}->() if $dispatch{$preset};
}

sub register {
  my ($self, $app) = @_;

  $app->minion->add_task(subprocess => sub {
    my ($job, $preset, $opts, @targets) = @_;

    return $job->retry({ delay => 300 })
      unless $app->minion->lock('global', 300, { limit => 100 });

    my $cmd = eval { $self->assembly($preset => $opts) };

    return $job->fail("Assembly failed: $@") if $@;
    return $job->fail("Wrong assembly preset") unless $cmd;

    my $subprocess = Mojo::IOLoop::Subprocess->new;

    $subprocess->run(
      sub {
        my ($subprocess) = @_;

        my $output;

        run3 $cmd, \@targets, \$output, \$output, {
          return_if_system_error => 1
        };

        return $output unless $?;
        die "$output\nstatus: $? message: $!\n";
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
