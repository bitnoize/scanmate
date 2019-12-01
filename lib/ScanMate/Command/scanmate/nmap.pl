package Minion::Command::scanmate::nmap;
use Mojo::Base "Mojolicious::Command";

use Mojo::JSON qw/encode_json decode_json/;
use Mojo::Util qw(dumper getopt tablify);

has description => 'Manage ScanMate jobs';
has usage       => sub { shift->extract_usage };

sub run {
  my ($self, @args) = @_;

  my ($args, $opts) = ([], {});

  getopt \@args,
    'A|attempts=i'  => \$opts->{attempts},

  $self->app->minion->enqueue(nmap_simple => []);
}

1;
