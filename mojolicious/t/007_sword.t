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
my $world = Gunpla::World->new(name => 'autotest', dice_results => [20, 0]);
$world->init_test('dummy');

my $t = Test::Mojo->new('GunplaServer');

$world->armies->[0]->position->x(1000);
resume(1);
diag("=== Diver sees dummy at start");
diag("Checking event generation (using API)");
$t->get_ok('/game/event?game=autotest&mecha=Diver')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'Diver',
                message => 'Diver sighted Dummy'
            }
        ]
    }
);
resume(2);
diag("=== Diver slash");
diag("Checking event generation (using API)");
$t->get_ok('/game/event?game=autotest&mecha=Diver')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'Diver',
                message => 'Diver slash with sword mecha Dummy'
            }
        ]
    }
);
$t->get_ok('/game/event?game=autotest&mecha=Dummy')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'Dummy',
                message => 'Diver slash with sword mecha Dummy'
            }
        ]
    }
);
diag("Checking mechas stats");
is($world->armies->[0]->position->x, -190);
is($world->armies->[0]->attack_limit, 0);
is($world->armies->[0]->gauge, 0);
is($world->armies->[1]->life, 870); #Damage 130 = 100 + (15 * 2)
is($world->armies->[1]->position->x, 200); #Damage 130 = 100 + (15 * 2)

diag("MongoDB cleanup");
$db->drop();



done_testing();

sub resume
{
    my $events = shift;
    if($world->armies->[0]->waiting)
    {
        diag("Resuming Diver action");
        $world->armies->[0]->waiting(0);
        $world->add_command('Diver', 'SWORD ATTACK', 'Dummy');
    }
    if($world->armies->[1]->waiting)
    {
        diag("Resuming Dummy action");
        $world->armies->[1]->waiting(0);
        $world->add_command('Dummy', 'WAITING');
    }
    is($world->action(), $events);
    $world->save;
}
