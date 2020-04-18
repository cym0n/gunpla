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


diag("Generate a world and save it on db");
my $world = Gunpla::World->new(name => 'autotest', dice_results => [20]);
$world->init_scenario('t009.csv');

#Dummy flies toward RX78 waiting to shoot
$world->armies->[0]->waiting(0);
$world->add_command("RX78", { command => 'RIFLE', params => 'MEC-Dummy' });
$world->armies->[1]->waiting(0);
$world->armies->[1]->velocity(6);
$world->add_command("Dummy", { command => 'FLY TO WAYPOINT', params => 'WP-blue', velocity => 6 });
is($world->action(), 2);
$world->save();
my $t = Test::Mojo->new('GunplaServer');
$t->get_ok('/game/event?game=autotest&mecha=RX78')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'RX78',
                message => 'RX78 hits with rifle Dummy'
            }
        ]
    }
);
$t->get_ok('/game/event?game=autotest&mecha=Dummy')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'Dummy',
                message => 'RX78 hits with rifle Dummy'
            }
        ]
    }
);

is($world->armies->[1]->position->x, 2000);


diag("MongoDB cleanup");
$db->drop();



done_testing();

