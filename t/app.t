use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

{
  package Mojo::UserAgent::Role::Signature::AbcService;
  use Mojo::Base 'Mojo::UserAgent::Role::Signature::Base';
  sub sign_tx {
    my ($self, $api_key) = @_;
    $self->tx->req->headers->authorization("Bearer $$api_key");
    $self->tx->req->headers->add('X-Mojo-Special' => ref $self->app);
  }
}

get '/login/:user' => sub {
  my $c = shift;
  my $ua = $c->app->ua;
  my $api_key = uc($c->param('user'));
  my $tx = $ua->build_tx(GET => '/abc' => $c->sign(abc_service => "$api_key-API-KEY") => json => {abc => 'cba'});
  $c->render(json => $tx->req->headers->to_hash);
};

get '/*w' => sub { shift->render(status => 200) };

my $t = Test::Mojo->new;
$t->app->plugin('Signature' => {Whatev => {}, Another => {}, AbcService => {}});

$t->get_ok('/login/user1')->status_is(200)
  ->json_is('/Authorization', 'Bearer USER1-API-KEY')
  ->json_is('/X-Mojo-Signature', 'AbcService')
  ->json_is('/X-Mojo-Special', 'Mojolicious::Lite');
$t->get_ok('/login/user2')->status_is(200)
  ->json_is('/Authorization', 'Bearer USER2-API-KEY')
  ->json_is('/X-Mojo-Signature', 'AbcService')
  ->json_is('/X-Mojo-Special', 'Mojolicious::Lite');

my $tx = $t->app->ua->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), undef, 'unsigned request';
is $tx->req->headers->header('X-Mojo-Special'), undef, 'not special';
$tx = $t->app->ua->build_tx(GET => '/abc' => $t->app->sign(abc_service => 'USER-API-KEY'));
is $tx->req->headers->header('X-Mojo-Signature'), 'AbcService', 'signed request';
is $tx->req->headers->header('X-Mojo-Special'), 'Mojolicious::Lite', 'special';
is $tx->req->headers->authorization, 'Bearer USER-API-KEY', 'authz user api';
$tx = $t->app->ua->build_tx(GET => '/abc' => abc_service => \'USER-API-KEY');
is $tx->req->headers->header('X-Mojo-Signature'), 'AbcService', 'signed request';
is $tx->req->headers->header('X-Mojo-Special'), 'Mojolicious::Lite', 'special';
is $tx->req->headers->authorization, 'Bearer USER-API-KEY', 'authz user api';
$tx = $t->app->ua->build_tx(GET => '/abc' => whatev => 'body');
is $tx->req->headers->header('X-Mojo-Signature'), 'Whatev', 'signed request';
is $tx->req->headers->header('X-Mojo-Special'), undef, 'not special';
is $tx->req->body, 'body', 'signed content';
$tx = $t->app->ua->build_tx(GET => '/abc' => whatev => json => {abc => 'cba'});
is $tx->req->headers->header('X-Mojo-Signature'), 'Whatev', 'signed request';
is $tx->req->headers->header('X-Mojo-Special'), undef, 'not special';
is $tx->req->json('/abc'), 'cba', 'signed json content';
$tx = $t->app->ua->build_tx(GET => '/abc' => whatev => [123] => json => {abc => 'cba'});
is $tx->req->headers->header('X-Mojo-Signature'), 'Whatev', 'signed request';
is $tx->req->headers->header('X-Mojo-Special'), undef, 'not special';
is $tx->req->json('/abc'), 'cba', 'signed json content';
$tx = $t->app->ua->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), undef, 'unsigned request';
is $tx->req->headers->header('X-Mojo-Special'), undef, 'not special';

done_testing;
