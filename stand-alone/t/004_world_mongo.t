use strict;
use v5.10;
use lib 'lib';

use MongoDB;
use Test::More;
use Gunpla::Test;
use Gunpla::World;

diag("Drop gunpla_autotest db on local mongodb");
my $mongo = MongoDB->connect(); 
my $db = $mongo->get_database('gunpla_autotest');
$db->drop();


diag("Generate a world and save it on db");
my $world = Gunpla::World->new(name => 'autotest');
$world->init();
$world->sighting_matrix->matrix->{'Gelgoog'}->{'Guncannon'} = 500;
$world->save();

diag("Load the generated world");
my $loaded_world = Gunpla::World->new(name => 'autotest');
$loaded_world->load();

diag("Checking waypoints created on load");
is(keys %{$loaded_world->waypoints}, 4);

diag("Checking mechas created on load");
is(@{$loaded_world->armies}, 2);

diag("Checking dummy entry on sighting matrix");
is($loaded_world->sighting_matrix->matrix->{'Gelgoog'}->{'Guncannon'}, 500);

Gunpla::Test::clean_db('autotest', 1);

done_testing();
