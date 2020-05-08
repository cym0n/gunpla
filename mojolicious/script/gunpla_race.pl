#!/usr/bin/perl

use strict;
use v5.10;
use lib 'lib';
use MongoDB;
use Gunpla::Mechadrome;
use Getopt::Long;
use Data::Dumper;

my $usage     = "Usage: $0 WP1 WP2... --velocity=x --max-velocity=X --acceleration=X --report=X --steps\n\n";
my $max_velocity  = 6;
my $velocity  = undef;
my $acceleration = 100000;
my $report = undef;
my $steps = undef;
my $full = undef;
GetOptions( 'full' => \$full, 'velocity' => \$velocity, 'max-velocity=s' => \$max_velocity, "acceleration=s" => \$acceleration, "report=s" => \$report, "steps=s" => \$steps );
$velocity = $max_velocity if ! $velocity;


my @wps = ();

for(@ARGV)
{
    push @wps, 'WP-' . $_;    

}

my $world = Gunpla::Mechadrome->new(name => 'mechadrome', full_record => $full);
$world->init_drome();
$world->armies->[0]->acceleration($acceleration);
$world->armies->[0]->max_velocity($max_velocity);
$world->report($report);
$world->race(\@wps, $velocity, $steps);
