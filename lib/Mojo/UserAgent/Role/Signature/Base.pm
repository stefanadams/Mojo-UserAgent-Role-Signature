package Mojo::UserAgent::Role::Signature::Base;
use Mojo::Base -base;

use Mojo::Transaction::HTTP;

has tx => sub { Mojo::Transaction::HTTP->new };

sub sign_tx { shift->tx }

1;