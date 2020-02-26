use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Mojo::HelloWorld');
$t->app->plugin('Signature' => {Whatev => {}, Another => {}});

my $tx = $t->app->ua->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), undef, 'unsigned request';

$tx = $t->app->ua->build_tx(GET => '/abc' => whatev => {});
is $tx->req->headers->header('X-Mojo-Signature'), 'Whatev', 'signed request';

$tx = $t->app->ua->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), undef, 'unsigned request';

$tx = $t->app->ua->signature('another')->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), 'Another', 'signed request';

$tx = $t->app->ua->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), undef, 'unsigned request';

done_testing;