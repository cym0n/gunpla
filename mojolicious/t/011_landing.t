use Mojo::Base -strict;

use v5.12;

use Test::More;
use Test::Mojo;

use lib 'lib';
use Data::Dumper;
use Gunpla::World;
use Gunpla::Position;

diag("Drop gunpla_autotest db on local mongodb");
my $mongo = MongoDB->connect(); 
my $db = $mongo->get_database('gunpla_autotest');
$db->drop();



diag("NO LANDING scenario");
diag("Generate a world and save it on db");
my $world = Gunpla::World->new(name => 'autotest', dice_results => [10]);
$world->init_scenario('t011.csv');


$world->armies->[0]->waiting(0);
$world->add_command('Deathscythe', { command =>'FLY TO WAYPOINT', params => 'WP-center', velocity => 10});
$world->armies->[1]->waiting(0);
$world->add_command('Sandrock', {command => 'WAITING'});
is($world->action(), 1);
$world->save;

my $t = Test::Mojo->new('GunplaServer');
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
$world->armies->[0]->waiting(0);
$world->add_command('Deathscythe', { command =>'FLY TO WAYPOINT', params => 'WP-center', velocity => 10});
is($world->action(), 1);
$world->save;

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
$world->armies->[1]->waiting(0);
$world->add_command('Sandrock', { command =>'RIFLE', params => 'MEC-Deathscythe'});
is($world->action(), 1);
$world->save;
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

diag("MongoDB cleanup");
$db->drop();

diag("LANDING scenario");

$world = Gunpla::World->new(name => 'autotest', dice_results => [10]);
$world->init_scenario('t011.csv');

$world->armies->[0]->waiting(0);
$world->add_command('Deathscythe', { command =>'FLY TO WAYPOINT', params => 'WP-center', velocity => 10});
$world->armies->[1]->waiting(0);
$world->add_command('Sandrock', {command => 'LAND', params => 'AST-0'});
is($world->action(), 1, "Sandrock landing");
$world->save;
diag("Sandrock landed");
my $t2 = Test::Mojo->new('GunplaServer');
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
is($world->armies->[1]->position->x, 20);
is($world->armies->[1]->position->y, 20);
is($world->armies->[1]->position->z, 20);
is($world->armies->[1]->velocity, 0);
is($world->armies->[1]->is_status('landed'), 1);
$world->armies->[1]->waiting(0);
$world->add_command('Sandrock', {command => 'WAITING'});
is($world->action(), 1, "Sandrock sees Deathscythe");
$world->save;
diag("Sandrock see Deathscythe");
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
#$t2->get_ok('/game/event?game=autotest&mecha=Deathscythe')->status_is(200)->json_is(
#    {
#        events => [
#            {
#                mecha => 'Sandrock',
#                message => 'Sandrock sighted Deathscythe'
#            }
#        ]
#    }
#);
$world->armies->[1]->waiting(0);
$world->add_command('Sandrock', {command => 'RIFLE', params => 'MEC-Deathscythe'});
is($world->action(), 1, 'Deathscythe sees Sandrock');
$world->save;
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
$world->armies->[0]->waiting(0);
$world->add_command('Deathscythe', { command =>'FLY TO WAYPOINT', params => 'WP-center', velocity => 10});
is($world->action(), 2, 'Rifle shoot');
$world->save;
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


open(my $log, "> /tmp/out1.log");
print {$log} Dumper($t2->tx->res->json) . "\n";
close($log);
diag("MongoDB cleanup");
$db->drop();

done_testing();
