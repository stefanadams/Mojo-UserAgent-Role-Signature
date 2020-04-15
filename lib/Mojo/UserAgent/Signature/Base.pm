package Mojo::UserAgent::Signature::Base;
use Mojo::Base -base;

use Mojo::UserAgent::Proxy;
use Mojo::Transaction::HTTP;

has
  app =>
  sub { $_[0]{app_ref} = Mojo::Server->new->build_app('Mojo::HelloWorld') },
  weak => 1;
has cb => sub { sub { shift } };
has proxy => sub { Mojo::UserAgent::Proxy->new };
has tx => sub { Mojo::Transaction::HTTP->new };

sub apply_signature {
  my ($self, $tx, $args) = @_;
  return $tx if _is_signed($tx);
  $tx->req->headers->add('X-Mojo-Signature' => _pkg_name $self);
  $self->tx($tx)
       ->tap(sub { $_[0]->cb->($_[0], $self) })
       ->sign_tx($args);
}

sub init {
  my ($self, $ua) = (shift, shift);

  $self = $self->new(@_);
  $ua->signature($self)->transactor->add_generator(sign => sub {
    my ($t, $tx) = (shift, shift);

    # Apply Signature
    my $args = shift if ref $_[0];
    $self->apply_signature($tx, $args);

    # Next Generator
    if (@_ > 1) {
      my $cb = $t->generators->{shift()};
      $t->$cb($tx, @_);
    }

    # Body
    elsif (@_) { $tx->req->body(shift) }

    return $tx;
  });
  return $self;
}

sub _pkg_name ($) { ((split /::/, ref $_[0] || $_[0])[-1]) }

sub set_header {
  my ($self, $header, $value) = @_;
  return unless $value;
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

sub _is_signed { shift->req->headers->header('X-Mojo-Signature') }

package Mojo::UserAgent::Signature::None;
use Mojo::Base 'Mojo::UserAgent::Signature::Base';

1;