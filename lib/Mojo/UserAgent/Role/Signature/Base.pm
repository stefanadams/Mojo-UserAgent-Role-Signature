package Mojo::UserAgent::Role::Signature::Base;
use Mojo::Base -base;

use Mojo::UserAgent::Proxy;
use Mojo::Transaction::HTTP;

has
  app =>
  sub { $_[0]{app_ref} = Mojo::Server->new->build_app('Mojo::HelloWorld') },
  weak => 1;
has cb => sub { sub { shift } };
has 'name';
has proxy => sub { Mojo::UserAgent::Proxy->new };
has tx => sub { Mojo::Transaction::HTTP->new };
has '_args';

sub cleanup { shift->_args(undef) }

sub set_header {
  my ($self, $header) = (shift, shift);
  return unless my $value = shift || $self->_args->{$header};
  $self->tx->req->headers->$header($value);
}

sub sign_tx { shift->tx }

sub use_proxy {
  my $self = shift;
  return $self->tx unless $self->proxy;
  local $ENV{MOJO_PROXY} = 1;
  local $ENV{NO_PROXY} = 'localhost,127.0.0.1';
  $self->proxy->prepare($self->tx);
  return $self->tx;
}

1;
