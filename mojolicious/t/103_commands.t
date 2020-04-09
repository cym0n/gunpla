use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use lib 'lib';
use Data::Dumper;
use Gunpla::World;

diag("Drop gunpla_autotest db on local mongodb");
my $mongo = MongoDB->connect(); 
my $db = $mongo->get_database('gunpla_autotest');
$db->drop();


diag("Generate a world and save it on db");
my $world = Gunpla::World->new(name => 'autotest');
$world->init();
$world->save();

my $t = Test::Mojo->new('GunplaServer');

diag("Adding a command to Diver");
$t->post_ok('/game/command' => {Accept => '*/*'} => json => { game => 'autotest',
                                                              mecha => 'Diver', 
                                                              command => 'FLY TO WAYPOINT',
                                                              params => 'center' })
    ->status_is(200)
    ->json_is({ result => 'OK',
                'command' => {
                    'params' => 'center',
                    'command' => 'FLY TO WAYPOINT',
                    'mecha' => 'Diver'
                } });

diag("Veriying waiting mecha flag");
$t->get_ok('/game/mechas?game=autotest&mecha=Diver')->status_is(200)->json_is("/mecha/waiting" => 0);

diag("Getting the command");
$t->get_ok('/game/command?game=autotest&mecha=Diver')->status_is(200)->json_is(
    {
        'command' => {
            'params' => 'center',
            'command' => 'FLY TO WAYPOINT',
            'mecha' => 'Diver'
        }
    }
);

diag("Adding a command to Zaku");
$t->post_ok('/game/command' => {Accept => '*/*'} => json => { game => 'autotest',
                                                              mecha => 'Zaku', 
                                                              command => 'FLY TO WAYPOINT',
                                                              params => 'center',
                                                              secondarycommand => 'MACHINEGUN',
                                                              secondaryparams => 'Diver' })
    ->status_is(200)
    ->json_is({ result => 'OK',
                'command' => {
                    'params' => 'center',
                    'command' => 'FLY TO WAYPOINT',
                    'mecha' => 'Zaku'
                } });

diag("Veriying waiting mecha flag");
$t->get_ok('/game/mechas?game=autotest&mecha=Zaku')->status_is(200)->json_is("/mecha/waiting" => 0);

diag("Getting the command");
$t->get_ok('/game/command?game=autotest&mecha=Zaku')->status_is(200)->json_is(
    {
        'command' => {
            'params' => 'center',
            'command' => 'FLY TO WAYPOINT',
            'mecha' => 'Zaku'
        }
    }
);








open(my $log, "> /tmp/out1.log");
print {$log} Dumper($t->tx->res->json) . "\n";
close($log);
diag("Drop gunpla_autotest db on local mongodb for final cleanup");
$db = $mongo->get_database('gunpla_autotest');
$db->drop();


done_testing();


