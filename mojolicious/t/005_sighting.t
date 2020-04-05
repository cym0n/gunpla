use strict;
use v5.10;
use lib 'lib';

use Test::More;
use Test::Mojo;
use Gunpla::Position;
use MongoDB;

diag("Main library load");
require_ok('Gunpla::World');

my $mongo = MongoDB->connect(); 

diag("Drop gunpla_autotest db on local mongodb");
my $db = $mongo->get_database('gunpla_autotest');
$db->drop();

my $world = Gunpla::World->new(name => 'autotest');
$world->init();

diag("Simulation of order received");
$world->armies->[0]->destination(Gunpla::Position->new(x => 0, y => 0, z => 0));
$world->armies->[1]->destination(Gunpla::Position->new(x => 0, y => 0, z => 0));
$world->armies->[0]->waiting(0);
$world->armies->[1]->waiting(0);

diag("Action until sighing event");
is($world->action(), 1);

diag("Checking game status after the event");
is($world->sighting_matrix->{'Diver'}->{'Zaku'}, 10000);
is($world->armies->[0]->waiting, 1);
is($world->armies->[0]->cmd_index, 1);
is($world->armies->[0]->position->x, 69999);
is($world->armies->[1]->waiting, 0);
is($world->armies->[1]->cmd_index, 0);
is($world->armies->[1]->position->x, -69999);

diag("Checking event generation (using API)");
$world->save;
my $t = Test::Mojo->new('GunplaServer');
$t->get_ok('/game/event?game=autotest&mecha=Diver')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'Diver',
                message => 'Diver sighted Zaku'
            }
        ]
    }
);

diag("MongoDB cleanup");
$db->drop();



done_testing();

