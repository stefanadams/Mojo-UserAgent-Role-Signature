package Mojo::UserAgent::Role::Signature;
use Mojo::Base -role;

use Mojo::Loader qw(find_modules load_class);
use Mojo::Util qw(camelize decamelize);

use Mojo::UserAgent::Role::Signature::Base;

has namespaces => sub { [__PACKAGE__] };
has 'signature';

around build_tx => sub {
  my ($orig, $self) = (shift, shift);
  my $tx = $orig->($self, @_);
  my $name = delete $self->{signature};
  return $tx unless $name
                 && $self->{$name}
                 && ref $self->{$name}
                 && $self->{$name}->can('sign_tx');
  $self->apply_signature($name => $tx);
};

sub add_signature {
  my ($self, $Name, $config) = @_;
  $self = $self->new unless ref $self;
  my $name = decamelize($Name);
  for my $module ( grep { /$Name$/ } map { find_modules $_ } $self->namespaces->@* ) {
    my $e = load_class $module;
    warn qq{Loading "$module" failed: $e} and next if ref $e;
    $self->{$name} = $module->new($config);
    last;
  }
  $self->{$name} ||= Mojo::UserAgent::Role::Signature::Base->new;
  return $self;
}

sub apply_signature {
  my ($self, $name, $tx) = @_;
  return $tx if _is_signed($tx);
  $tx->req->headers->add('X-Mojo-Signature' => camelize($name));
  $self->{$name}->tx($tx)->sign_tx;
}

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