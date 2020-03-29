use strict;
use v5.10;
use lib 'lib';

use MongoDB;
use Test::More;
use Gunpla::World;

diag("Drop gunpla_autotest db on local mongodb");
my $mongo = MongoDB->connect(); 
my $db = $mongo->get_database('gunpla_autotest');
$db->drop();


diag("Generate a world and save it on db");
my $world = Gunpla::World->new(name => 'autotest');
$world->init();
$world->save();

diag("Load the generated world");
my $loaded_world = Gunpla::World->new(name => 'autotest');
$loaded_world->load();

diag("Checking waypoints created on load");
is(keys %{$loaded_world->waypoints}, 3);

diag("Checking mechas created on load");
is(@{$loaded_world->armies}, 2);

diag("Drop gunpla_autotest db on local mongodb for final cleanup");
$db = $mongo->get_database('gunpla_autotest');
$db->drop();

done_testing();
