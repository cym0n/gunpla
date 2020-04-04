use strict;
use v5.10;
use lib 'lib';

use Test::More;

diag("Main library load");
require_ok('Gunpla::World');

my $world = Gunpla::World->new();
$world->init();

diag("Checking waypoints created on init");
is(keys %{$world->waypoints}, 4);

diag("Checking mechas created on init");
is(@{$world->armies}, 2);


done_testing;
