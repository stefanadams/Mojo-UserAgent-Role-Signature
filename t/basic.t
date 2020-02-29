use Mojo::Base -strict;
use Test::More;

use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new;

my $tx = $ua->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), undef, 'unsigned request';
is $tx->req->url, '/abc', 'right unsigned url';

$ua = Mojo::UserAgent->with_roles('+Signature')->new;
$ua->add_signature('Whatev');
$ua->add_signature('Another');

$tx = $ua->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), undef, 'unsigned request';

$tx = $ua->build_tx(GET => '/abc' => whatev => {});
is $tx->req->headers->header('X-Mojo-Signature'), 'Whatev', 'signed request';

$tx = $ua->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), undef, 'unsigned request';

$tx = $ua->build_tx(GET => '/abc' => another => {});
is $tx->req->headers->header('X-Mojo-Signature'), 'Another', 'signed request';

$tx = $ua->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), undef, 'unsigned request';

done_testing;