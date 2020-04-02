#!/usr/bin/perl

use strict;
use v5.10;
use lib 'lib';
use MongoDB;
use Gunpla::World;

my $name = shift;

my $mongo = MongoDB->connect(); 
my $db = $mongo->get_database('gunpla_' . $name);
$db->drop();
my $world = Gunpla::World->new(name => $name);
$world->init();
$world->save();


