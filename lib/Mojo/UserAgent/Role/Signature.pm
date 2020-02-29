package Mojo::UserAgent::Role::Signature;
use Mojo::Base -role;

use Mojo::Loader qw(find_modules find_packages load_class);
use Mojo::Util qw(camelize decamelize);

use Mojo::UserAgent::Role::Signature::Base;

has namespaces => sub { [__PACKAGE__] };
has 'signature';

around build_tx => sub {
  my ($orig, $self) = (shift, shift);
  $self->apply_signature(undef, $orig->($self, @_));
};

sub add_signature {
  my ($self, $Name, $config) = @_;
  $self = $self->new unless ref $self;
  my $name = decamelize($Name);
  my @classes = (
    (grep { /$Name$/ } map { find_packages $_ } $self->namespaces->@*),
    (grep { /$Name$/ } map { find_modules $_ } $self->namespaces->@*),
  );
  @classes or @classes = ('Mojo::UserAgent::Role::Signature::Base');
  for my $module ( @classes ) {
    my $e = load_class $module;
    warn qq{Loading "$module" failed: $e} and next if ref $e;
    my $role = $module->new($config || {});
    $name = $role->name || $name;
    $self->signatures($name => $role);
    $self->transactor->add_generator($name => sub {
      my ($t, $tx) = (shift, shift);

      # Apply Signature
      my $args = shift if ref $_[0];
      $self->apply_signature($name => $tx, $args);

      # Next Generator
      if ( @_ > 1 ) {
        my $cb = $t->generators->{shift()};
        $t->$cb($tx, @_);
      }

      # Body
      elsif ( @_ ) { $tx->req->body(shift) }
    });
    last;
  }
  return $self->signatures($name);
}

sub apply_signature {
  my ($self, $name, $tx, $args) = @_;
  $name ||= $self->signature or return $tx;
  return $tx if _is_signed($tx);
  return $tx unless $self->signatures($name);
  my ($Name) = reverse split /::/, ref $self->signatures($name);
  $Name = camelize($name) if $Name eq 'Base';
  $tx->req->headers->add('X-Mojo-Signature' => $Name);
  $self->signatures($name)->tx($tx)
                          ->tap(sub { $_[0]->cb->($_[0], $self) })
                          ->sign_tx($args);
}

sub signatures { Mojo::Util::_stash(signatures => @_) }

sub _is_signed { shift->req->headers->header('X-Mojo-Signature') }

1;

=encoding utf8

=head1 NAME

Mojo::UserAgent::Role::AWSSignature4 - Automatically sign transactions with AWS
Signature version 4

=head1 SYNOPSIS

  use Mojo::UserAgent;

  my $ua = Mojo::UserAgent->with_roles('+AWSSignature4')->new;
  my $tx = $ua->get('https://us-east-1.ec2.amazonaws.com?Action=DescribeVolumes');
  say $tx->req->headers->authorization;
  say $ua->awssig4->signature;

=head1 DESCRIPTION

L<Mojo::UserAgent::Role::AWSSignature4> modifies the L<Mojo::UserAgent/"build_tx">
method by wrapping around it with a L<role|Role::Tiny> and signing the
transaction using the AWS Signature version 4 by either adding an authorization
header or modifying the request URL query.

=head1 ATTRIBUTES

=head2 awssig4

  $awssig4 = $ua->awssig4;
  $ua      = $ua->awssig4(Mojo::AWS::Signature4->new);

Defaults to a new L<Mojo::AWS::Signature4> instance, but if this attribute is
not defined, the method modifier provider by this L<role|Role::Tiny> will have
no effect.

  # Sign the request transaction
  $ua->get($url);

  # Don't sign the request transaction
  $ua->awssig4(undef)->get($url);

  # Sign the request transaction using the URL query
  $ua->awssig4->authorization(0)->expires(60);
  $ua->get($url);

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019, Stefan Adams and others.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.
 
=head1 SEE ALSO

L<https://github.com/s1037989/mojo-aws-signature4>, L<Mojo::UserAgent>.

=cut
