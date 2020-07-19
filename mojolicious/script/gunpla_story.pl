#!/usr/bin/perl

use strict;
use v5.10;
use lib 'lib';
use Gunpla::Test::Autoplay;

my $story = shift;
my $title_message = shift;
my $game = Gunpla::Test::Autoplay->new();
$game->load('stories/' . $story, $title_message);
$game->run();

