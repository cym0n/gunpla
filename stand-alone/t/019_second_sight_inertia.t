use strict;
use v5.10;
use lib 'lib';

use Test::More;
use Gunpla::Position;
use Gunpla::Test;
use Gunpla::World;

my $world = Gunpla::Test::test_bootstrap('t019.csv');
$world->log_tracing(['Tallgeese-1', 'Tallgeese-2', 'Aries-1']);
is(Gunpla::Test::emulate_commands($world, {
    'Tallgeese-1'  => { command => 'flywp', params => 'WP-center',    velocity => 6 },
    'Tallgeese-2'  => { command => 'flywp', params => 'WP-center',   velocity => 6 },
    'Aries-1'   => { command => 'flywp', params => 'WP-center',   velocity => 6 },
}), 3, "Tallgeese-1 and Tallgeese-2 get contact contemporary and there is no intertia");
is_deeply($world->get_events('Tallgeese-1'), [ 'Tallgeese-1 sighted Tallgeese-2', 'Tallgeese-1 sighted Aries-1' ]);
is_deeply($world->get_events('Tallgeese-2'), [ 'Tallgeese-2 sighted Tallgeese-1' ]);
is($world->armies->[0]->inertia, 0, "No inertia for Tallgeese-1");
is($world->armies->[1]->inertia, 0, "No inertia for Tallgeese-2");
is(Gunpla::Test::emulate_commands($world, {
    'Tallgeese-1'  => { command => 'flywp', params => 'WP-center',    velocity => 6 },
    'Tallgeese-2'  => { command => 'flywp', params => 'WP-center',   velocity => 6 },
}), 1, "The fly of the mechas go on");
is_deeply($world->get_events('Aries-1'), [ 'Aries-1 sighted Tallgeese-1' ]);
is($world->armies->[0]->inertia, 0, "No inertia for Tallgeese-1");
is($world->armies->[2]->inertia, 300, "No inertia for Aries-1");
Gunpla::Test::clean_db('autotest', 1);
done_testing();

