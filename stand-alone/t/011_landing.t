use Mojo::Base -strict;

use v5.12;
use lib 'lib';

use Test::More;
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

diag("NO LANDING scenario");
my $world = Gunpla::Test::test_bootstrap('t011.csv', [10]);
my $commands = { 'Deathscythe' => { command =>'flywp', params => 'WP-center', velocity => 10},
                 'Sandrock' => {command => 'wait'}};
is(Gunpla::Test::emulate_commands($world, $commands), 1);
diag("Sight events");
is_deeply($world->get_events('Deathscythe'), [ 'Deathscythe sighted Sandrock' ]);
is(Gunpla::Test::emulate_commands($world, $commands), 1);
is_deeply($world->get_events('Sandrock'), [ 'Sandrock sighted Deathscythe' ]);
diag("Sandrock rifle shot miss");
is(Gunpla::Test::emulate_commands($world, { 'Sandrock' => { command =>'rifle', params => 'MEC-Deathscythe'} }), 1);
is_deeply($world->get_events('Sandrock'), [ 'Sandrock missed Deathscythe with rifle' ]);

diag("LANDING scenario");
$world = Gunpla::Test::test_bootstrap('t011.csv', [10]);
$commands = { 'Deathscythe' => { command =>'flywp', params => 'WP-center', velocity => 10},
                 'Sandrock' => {command => 'land', params => 'AST-0'}};
is(Gunpla::Test::emulate_commands($world, $commands), 1);
diag("Sandrock landed");
is_deeply($world->get_events('Sandrock'), [ 'Sandrock landed on asteroid 0' ]);
is($world->armies->[1]->position->x, 20);
is($world->armies->[1]->position->y, 20);
is($world->armies->[1]->position->z, 20);
is($world->armies->[1]->velocity, 0);
is($world->armies->[1]->is_status('landed'), 1);
is(Gunpla::Test::emulate_commands($world, { 'Sandrock' => {command => 'wait'} }), 1);
diag("Sandrock sights Deathscythe");
is_deeply($world->get_events('Sandrock'), [ 'Sandrock sighted Deathscythe' ]);
is(Gunpla::Test::emulate_commands($world, { 'Sandrock' => {command => 'rifle', params => 'MEC-Deathscythe'} }), 1);
diag("Deathscythe sights Sandrock");
is_deeply($world->get_events('Deathscythe'), [ 'Deathscythe sighted Sandrock' ]);
is(Gunpla::Test::emulate_commands($world, { 'Deathscythe' => { command =>'flywp', params => 'WP-center', velocity => 10} }), 2);
diag("Sandrock rifle shoot");
is_deeply($world->get_events('Deathscythe'), [ 'Sandrock hits with rifle Deathscythe' ]);
is_deeply($world->get_events('Sandrock'), [ 'Sandrock hits with rifle Deathscythe' ]);

Gunpla::Test::clean_db('autotest', 1);

done_testing();
