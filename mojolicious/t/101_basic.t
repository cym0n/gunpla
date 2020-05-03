use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use lib 'lib';

my $t = Test::Mojo->new('GunplaServer');
$t->get_ok('/')->status_is(302);

done_testing();
