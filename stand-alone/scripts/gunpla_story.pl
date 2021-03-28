#!/usr/bin/perl

use strict;
use v5.10;
use lib 'lib';
use Gunpla::Test::Autoplay;
use Getopt::Long;
use Data::Dumper;

my $usage     = "Usage: $0 STORY --snapshot=x --title=X\n\n";
my $snapshot = undef;
my $title_message = undef;
GetOptions( "snapshot=s" => \$snapshot, "title=s" => \$title_message);

my $story = shift;
my $game = Gunpla::Test::Autoplay->new();
$game->load('data/stories/' . $story, $title_message);
$game->run($snapshot);

