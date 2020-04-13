package Mojo::UserAgent::Role::Signature;
use Mojo::Base -role;

use Mojo::Loader qw(load_class);
use Mojo::Util qw(camelize);
use Mojo::UserAgent::Signature::Base;

has namespaces => sub { ['Mojo::UserAgent::Signature'] };
has 'signature';

around build_tx => sub {
  my ($orig, $self) = (shift, shift);
  return $orig->($self, @_) unless $self->signature;
  $self->signature->apply_signature($orig->($self, @_));
};

sub load_signature {
  my ($self, $name) = @_;

  # Try all namespaces and full module name
  my $suffix  = $name =~ /^[a-z]/ ? camelize $name : $name;
  my @classes = map {"${_}::$suffix"} @{$self->namespaces};
  for my $class (@classes, $name) { return $class->new if _load($class) }
  my $class = __PACKAGE__ . "::None";
  return $class->new if _load($class);

  # Not found
  die qq{Signature "$name" missing, maybe you need to install it?\n};
}

sub initialize_signature {
  my $self = shift;
  $self->load_signature(shift)->init($self, ref $_[0] ? $_[0] : {@_});
}

sub _load {
  my $module = shift;
  return $module->isa('Mojo::UserAgent::Signature::Base')
    unless my $e = load_class $module;
  ref $e ? die $e : return undef;
}

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
