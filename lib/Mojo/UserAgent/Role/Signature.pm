package Mojo::UserAgent::Role::Signature;
use Mojo::Base -role;

use Mojo::Loader qw(find_modules find_packages load_class);
use Mojo::Util qw(camelize decamelize);

use Mojo::UserAgent::Role::Signature::Base;

has namespaces => sub { [__PACKAGE__] };
has 'signature';

around build_tx => sub {
  my ($orig, $self) = (shift, shift);
  $self->apply_signature($orig->($self, @_));
};

sub add_signature {
  my ($self, $name, $config) = @_;
  $self = $self->new unless ref $self;
  my @classes = (
    (grep { /$name$/ } map { find_packages $_ } $self->namespaces->@*),
    (grep { /$name$/ } map { find_modules $_ } $self->namespaces->@*),
  );
  @classes or @classes = ('Mojo::UserAgent::Role::Signature::Base');
  for my $module ( @classes ) {
    my $e = load_class $module;
    warn qq{Loading "$module" failed: $e} and next if ref $e;
    $self->signature($module->new($config || {}));
    last;
  }
  return $self->add_signature_generator;
}

sub add_signature_generator {
  my $self = shift;
  $self->transactor->add_generator(sign => sub {
    my ($t, $tx) = (shift, shift);

    # Apply Signature
    my $args = shift if ref $_[0];
    $self->apply_signature($tx, $args);

    # Next Generator
    if ( @_ > 1 ) {
      my $cb = $t->generators->{shift()};
      $t->$cb($tx, @_);
    }

    # Body
    elsif ( @_ ) { $tx->req->body(shift) }

    return $tx;
  });
  return $self;
}

sub apply_signature {
  my ($self, $tx, $args) = @_;
  return $tx if _is_signed($tx);
  return $tx unless my $sig = $self->signature;
  my ($name) = reverse split /::/, ref $sig;
  $tx->req->headers->add('X-Mojo-Signature' => $name || 'Yes');
  $sig->tx($tx)
      ->tap(sub { $_[0]->cb->($_[0], $self) })
      ->sign_tx($args);
}

sub _is_signed { shift->req->headers->header('X-Mojo-Signature') }

1;

=encoding utf8

=head1 NAME

Mojo::UserAgent::Role::Signature - Automatically sign request transactions

=head1 SYNOPSIS

  use Mojo::UserAgent;

  my $ua = Mojo::UserAgent->with_roles('+Signature')->new;
  $ua->add_signature(SomeService => {%args});
  my $tx = $ua->get('/api/for/some/service');
  say $tx->req->headers->authorization;

=head1 DESCRIPTION

L<Mojo::UserAgent::Role::Signature> modifies the L<Mojo::UserAgent/"build_tx">
method by wrapping around it with a L<role|Role::Tiny> and signing the
transaction using signature added to the UserAgent object.

=head1 ATTRIBUTES

=head2 namespaces

  $namespaces = $ua->namespaces;
  $ua         = $ua->namespaces([]);

Set the namespaces to search for the module specified in add_signature.
Defaults to C<Mojo::UserAgent::Role::Siganture>.

=head2 signature

  $signature = $ua->signature;
  $ua        = $ua->signature(SomeService->new);

If this attribute is not defined, the method modifier provider by this
L<role|Role::Tiny> will have no effect.

=head1 METHODS

=head2 add_signature

  $ua = $ua->add_signature(SomeService => {%args});

Add the signature handling module to the UserAgent instance. The
specified module will searched by looking in the namespaces.

=head2 add_signature_generator

  $ua = $ua->add_signature_generator;

Adds a transactor generator named C<sign> for applying a signature
to a transaction. Useful for overriding the signature details added
to the instance by add_signature.

  $ua->get($url => sign => {%args});

=head2 apply_signature

  $signed_tx = $ua->apply_signature($tx, $args);

Adds the signature produced by the C<sign_tx> method of the
SomeService module. Also adds a header to the transaction,
C<X-Mojo-Signature>, to indicate that this transaction has been
signed -- this prevents the automatic signature handling from
applying the signature a second time after the generator.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019, Stefan Adams and others.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<https://github.com/s1037989/mojo-aws-signature4>, L<Mojo::UserAgent>.

=cut
