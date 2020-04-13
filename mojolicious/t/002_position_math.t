use strict;
use v5.10;
use lib 'lib';

use Test::More;
diag("Position library load");
require_ok('Gunpla::Position');

my $p1 = Gunpla::Position->new(x => 500000, y => 0, z => 0);
my $p2 = Gunpla::Position->new(x => 0, y => 0, z => 0);

diag("Vector elaboration - simple case");
my ($cursor, $vector) = $p1->vector($p2);
is($vector->x, 500000); 
is($vector->y, 0); 
is($vector->z, 0); 
is($cursor->x, -1); 
is($cursor->y, 0); 
is($cursor->z, 0); 

diag("Normal vector elaboration - simple case");
my ($cursor_n, $vector_n) = $p1->vector($p2, 1);
is($vector_n->x, '1.000'); 
is($vector_n->y, '0.000'); 
is($vector_n->z, '0.000'); 
is($cursor_n->x, -1); 
is($cursor_n->y, 0); 
is($cursor_n->z, 0); 

diag("Course elaboration - simple case");
my $course = $p1->course($p2);
is($course->{'direction'}, -1);
is($course->{'axis'}, 'x');
is($course->{'steps'}, 500000);

my $p3 = Gunpla::Position->new(x => 10, y => 10, z => 10);
my $p4 = Gunpla::Position->new(x => 310, y => 410, z => 810);

diag("Vector elaboration - complex case");
my ($cursor2, $vector2) = $p3->vector($p4);
is($vector2->x, 300); 
is($vector2->y, 400); 
is($vector2->z, 800); 
is($cursor2->x, 1); 
is($cursor2->y, 1); 
is($cursor2->z, 1); 

diag("Normal Vector elaboration - complex case");
my ($cursor2_n, $vector2_n) = $p3->vector($p4, 1);
is($vector2_n->x, .318); 
is($vector2_n->y, .424); 
is($vector2_n->z, .847); 
is($cursor2_n->x, 1); 
is($cursor2_n->y, 1); 
is($cursor2_n->z, 1);

diag("Course elaboration - complex case");
my $course2 = $p3->course($p4);
is($course2->{'direction'}, 1);
is($course2->{'axis'}, 'z');
is($course2->{'steps'}, 2);

diag("Distance calculation - simple case");
is($p1->distance($p2), 500000);


diag("Distance calculation - complex case");
is($p3->distance($p4), 944);

diag("Destination along direction (get away) calculation - simple case");
my $away1 = $p1->away_from($p2, 1000);
is($away1->x, 501000);
is($away1->y, 0);
is($away1->z, 0);

diag("Destination along direction (get away) calculation - complex case");
my $away2 = $p3->away_from($p4, 1000);
is($away2->x, -308);
is($away2->y, -414);
is($away2->z, -837);



done_testing();


