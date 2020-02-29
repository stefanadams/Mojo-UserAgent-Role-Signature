package Mojolicious::Plugin::Signature;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($self, $app, $config) = @_;
  $app->ua($app->ua->with_roles('+Signature'));
  foreach my $Name ( keys %$config ) {
    $app->ua->add_signature($Name => $config->{$Name})->app($app);
  }

  $app->helper(sign => sub {
    my ($c, $service) = (shift, shift);
    my $args = @_ > 1 ? \@_ : ref $_[0] ? $_[0] : \$_[0];
    return ($service => $args);
  });
}

1;
