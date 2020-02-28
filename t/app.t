use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Mojo::HelloWorld');
$t->app->plugin('Signature' => {Whatev => {}, Another => {}});
$t->app->ua->signatures('whatev')->cb(sub{shift->tx->req->headers->add('X-Mojo-Special' => ref $t->app)});

my $tx = $t->app->ua->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), undef, 'unsigned request';
is $tx->req->headers->header('X-Mojo-Special'), undef, 'not special';

$tx = $t->app->ua->build_tx(GET => '/abc' => whatev => 'body');
is $tx->req->headers->header('X-Mojo-Signature'), 'Whatev', 'signed request';
is $tx->req->headers->header('X-Mojo-Special'), 'Mojo::HelloWorld', 'special';
is $tx->req->body, 'body', 'signed content';
$tx = $t->app->ua->build_tx(GET => '/abc' => whatev => json => {abc => 'cba'});
is $tx->req->headers->header('X-Mojo-Signature'), 'Whatev', 'signed request';
is $tx->req->headers->header('X-Mojo-Special'), 'Mojo::HelloWorld', 'special';
is $tx->req->json('/abc'), 'cba', 'signed json content';
$tx = $t->app->ua->build_tx(GET => '/abc' => whatev => [123] => json => {abc => 'cba'});
is $tx->req->headers->header('X-Mojo-Signature'), 'Whatev', 'signed request';
is $tx->req->headers->header('X-Mojo-Special'), 'Mojo::HelloWorld', 'special';
is $tx->req->json('/abc'), 'cba', 'signed json content';

$tx = $t->app->ua->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), undef, 'unsigned request';
is $tx->req->headers->header('X-Mojo-Special'), undef, 'unsigned request';

$tx = $t->app->ua->signature('another')->args([321])->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), 'Another', 'signed request';
is $tx->req->headers->header('X-Mojo-Special'), undef, 'not special';

$tx = $t->app->ua->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), undef, 'unsigned request';
is $tx->req->headers->header('X-Mojo-Special'), undef, 'not special';

done_testing;
