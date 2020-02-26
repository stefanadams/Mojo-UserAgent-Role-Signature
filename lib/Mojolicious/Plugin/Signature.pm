package Mojolicious::Plugin::Signature;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Util 'decamelize';

sub register {
  my ($self, $app, $config) = @_;
  $app->ua($app->ua->with_roles('+Signature'));
  foreach my $Name ( keys %$config ) {
    my $name = decamelize($Name);
    $app->ua->add_signature($Name => $config->{$Name});
    $app->ua->transactor->add_generator($name => sub {
      my ($t, $tx, @args) = @_;
      $app->ua->signature($name);
    });
  }
}

1;