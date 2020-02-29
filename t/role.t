use Mojo::Base -strict;
use Test::More;

use Mojo::UserAgent;

{
  package Mojo::UserAgent::Role::Signature::AB1;
  use Mojo::Base 'Mojo::UserAgent::Role::Signature::Base';
  has name => 'ab1';
}
my $ua = Mojo::UserAgent->new;

$ua = Mojo::UserAgent->with_roles('+Signature')->new;
$ua->add_signature('AB1');

my $tx = $ua->build_tx(GET => '/abc' => 'ab1' => {});
is $tx->req->headers->header('X-Mojo-Signature'), 'AB1', 'signed request';

done_testing;