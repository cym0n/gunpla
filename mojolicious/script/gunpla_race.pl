#!/usr/bin/perl

use strict;
use v5.10;
use lib 'lib';
use MongoDB;
use Gunpla::Mechadrome;
use Getopt::Long;
use Data::Dumper;



my $world = Gunpla::Mechadrome->new(name => 'mechadrome');
$world->init_drome();
$world->race([ 'WP-center' ]);
