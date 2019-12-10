package ScanMate::Command::nmap;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util qw(dumper getopt tablify);

has description => 'Manage ScanMate jobs';
has usage       => sub { shift->extract_usage };

sub run {
  my ($self, @args) = @_;

  my ($args, $opts) = ([], {});

  getopt \@args,
    'A|attempts=i'  => \$opts->{attempts},
    'p|prefix=s'    => \$opts->{prefix};

  $self->app->minion->enqueue(scan => [
    'fast' => "whoer/leetka",
    ["leetka.whteam.net"]
  ]);
}

1;
