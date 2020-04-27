use Mojo::Base -strict;

use v5.12;

use Test::More;
use Test::Mojo;

use lib 'lib';
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

diag("NO LANDING scenario");
my $world = Gunpla::Test::test_bootstrap('t011.csv', [10]);
my $t = Test::Mojo->new('GunplaServer');
my $commands = { 'Deathscythe' => { command =>'FLY TO WAYPOINT', params => 'WP-center', velocity => 10},
                 'Sandrock' => {command => 'WAITING'}};
is(Gunpla::Test::emulate_commands($world, $commands), 1);

diag("Deathscythe sight event");
$t->get_ok('/game/event?game=autotest&mecha=Deathscythe')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'Deathscythe',
                message => 'Deathscythe sighted Sandrock'
            }
        ]
    }
);

is(Gunpla::Test::emulate_commands($world, $commands), 1);

diag("Sandrock sight event");
$t->get_ok('/game/event?game=autotest&mecha=Sandrock')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'Sandrock',
                message => 'Sandrock sighted Deathscythe'
            }
        ]
    }
);

is(Gunpla::Test::emulate_commands($world, { 'Sandrock' => { command =>'RIFLE', params => 'MEC-Deathscythe'} }), 1);

diag("Sandrock rifle shot miss");
$t->get_ok('/game/event?game=autotest&mecha=Sandrock')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'Sandrock',
                message => 'Sandrock missed Deathscythe with rifle'
            }
        ]
    }
);

diag("LANDING scenario");
$world = Gunpla::Test::test_bootstrap('t011.csv', [10]);
my $t2 = Test::Mojo->new('GunplaServer');
$commands = { 'Deathscythe' => { command =>'FLY TO WAYPOINT', params => 'WP-center', velocity => 10},
                 'Sandrock' => {command => 'LAND', params => 'AST-0'}};

is(Gunpla::Test::emulate_commands($world, $commands), 1);

diag("Sandrock landed");
$t2->get_ok('/game/event?game=autotest&mecha=Sandrock')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'Sandrock',
                message => 'Sandrock landed on asteroid 0'
            }
        ]
    }
);

diag("Sandrock status values");
is($world->armies->[1]->position->x, 20);
is($world->armies->[1]->position->y, 20);
is($world->armies->[1]->position->z, 20);
is($world->armies->[1]->velocity, 0);
is($world->armies->[1]->is_status('landed'), 1);

is(Gunpla::Test::emulate_commands($world, { 'Sandrock' => {command => 'WAITING'} }), 1);

diag("Sandrock sights Deathscythe");
$t2->get_ok('/game/event?game=autotest&mecha=Sandrock')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'Sandrock',
                message => 'Sandrock sighted Deathscythe'
            }
        ]
    }
);

is(Gunpla::Test::emulate_commands($world, { 'Sandrock' => {command => 'RIFLE', params => 'MEC-Deathscythe'} }), 1);

diag("Deathscythe sights Sandrock");
$t2->get_ok('/game/event?game=autotest&mecha=Deathscythe')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'Deathscythe',
                message => 'Deathscythe sighted Sandrock'
            }
        ]
    }
);

is(Gunpla::Test::emulate_commands($world, { 'Deathscythe' => { command =>'FLY TO WAYPOINT', params => 'WP-center', velocity => 10} }), 2);

diag("Sandrock rifle shoot");
$t2->get_ok('/game/event?game=autotest&mecha=Deathscythe')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'Deathscythe',
                message => 'Sandrock hits with rifle Deathscythe'
            }
        ]
    }
);
$t2->get_ok('/game/event?game=autotest&mecha=Sandrock')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'Sandrock',
                message => 'Sandrock hits with rifle Deathscythe'
            }
        ]
    }
);

Gunpla::Test::dump_api($t2);

Gunpla::Test::clean_db('autotest', 1);

done_testing();
