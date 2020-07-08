#!/usr/bin/perl

use strict;
use v5.10;
use lib 'lib';
use MongoDB;
use Gunpla::Test::Autoplay;

my $game = Gunpla::Test::Autoplay->new();
$game->load('stories/patrol.story');
$game->run();

