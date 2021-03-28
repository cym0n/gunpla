package Gunpla::Constants;

use strict;
use warnings;

use base 'Exporter';

use constant ELEMENT_TAGS => { 'AST' => 'asteroid', 
                                'MEC' => 'mecha',
                              'WP' => 'waypoint', 
                              'POS' => 'position', 
                              'SAR' => 'sensor array',
                              'VOID' => 'void',
                              'LMEC' => 'last position of mecha' };
use constant FILTERS => { 'waypoints' => [ 'waypoints' ],
                          'sighted-by-me' => [ 'sighted_by_me' ],
                          'sighted-by-faction' =>  [ 'sighted_by_faction' ],
                          'visible' => [ 'sighted_by_faction',
                                         'map_elements' ],
                          'hotspots' => [ 'hotspots' ],
                          'landing' => [ 'landing' ],
                          'last-sight' => [ 'last_sight' ],
                          'friends-no-wait' => [ 'friends_no_wait' ],
                        };
use constant SUBFILTERS => { 'waypoints' => ['WP'],
                             'sighted_by_me' => ['MEC'],
                             'sighted_by_faction' => ['MEC'],
                             'map_elements' => ['WP', 'AST', 'SAR'],
                             'hotspots' => ['AST', 'SAR'],
                             'landing' => ['AST', 'SAR',],
                             'last_sight' => ['MEC'],
                             'friends_no_wait' => ['MEC'] };

       
our @EXPORT_OK = (
    'ELEMENT_TAGS',
    'FILTERS',
    'SUBFILTERS',
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );


 
