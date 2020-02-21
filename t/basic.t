use Mojo::Base -strict;
use Test::More;

use Mojo::File 'curfile';
use Mojo::UserAgent;

use lib curfile->dirname->sibling('lib')->to_string;

my $ua = Mojo::UserAgent->new;

my $tx = $ua->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), undef, 'unsigned request';
is $tx->req->url, '/abc', 'right unsigned url';

$ua = Mojo::UserAgent->with_roles('+Signature')->new;

$ua->add_signature('whatev');
$tx = $ua->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), 'Whatev', 'signed whatev request';
is $tx->req->url, '/abc', 'right whatev url';

$ua->add_signature('another');
$tx = $ua->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), 'Another', 'signed another request';
is $tx->req->url, '/abc', 'right another url';

$ua->signature('whatev');
$tx = $ua->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), 'Whatev', 'signed whatev request again';
is $tx->req->url, '/abc', 'right whatev url again';

$ua->signature('another');
$tx = $ua->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), 'Another', 'signed another request again';
is $tx->req->url, '/abc', 'right another url again';

$tx = $ua->signature('whatev')->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), 'Whatev', 'signed whatev request again';
is $tx->req->url, '/abc', 'right whatev url again';

$tx = $ua->signature('another')->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), 'Another', 'signed another request again';
is $tx->req->url, '/abc', 'right another url again';

$tx = $ua->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), 'Another', 'signed another request again';
is $tx->req->url, '/abc', 'right another url again';

my $whatev = $ua->signature('whatev');
$tx = $whatev->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), 'Whatev', 'signed whatev request again';
is $tx->req->url, '/abc', 'right whatev url again';

my $another = $ua->signature('another');
$tx = $another->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), 'Another', 'signed another request again';
is $tx->req->url, '/abc', 'right another url again';

$tx = $whatev->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), 'Whatev', 'signed whatev request again';
is $tx->req->url, '/abc', 'right whatev url again';

done_testing;