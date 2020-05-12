package Gunpla::Constants;

use strict;
use warnings;

use base 'Exporter';

use constant GET_AWAY_DISTANCE => 30000;
use constant MACHINEGUN_DAMAGE => 20;
use constant MACHINEGUN_GAUGE => 400;
use constant MACHINEGUN_RANGE => 1000;
use constant MACHINEGUN_SHOTS => 3;
use constant MACHINEGUN_SWORD_GAUGE_DAMAGE => 300; 
use constant MACHINEGUN_WIN => 10;
use constant NEARBY => 1000;
use constant RIFLE_ATTACK_TIME_LIMIT => 20000;
use constant RIFLE_DAMAGE => 100;
use constant RIFLE_GAUGE => 5000;
use constant RIFLE_MAX_DISTANCE => 40000;
use constant RIFLE_MIN_DISTANCE => 2000;
use constant RIFLE_SWORD_GAUGE_DAMAGE => 600; 
use constant RIFLE_WIN => 11;
use constant RIFLE_LANDED_BONUS => 1;
use constant RIFLE_ENERGY => 30000;
use constant SWORD_ATTACK_TIME_LIMIT => 4000;
use constant SWORD_BOUNCE => 200;
use constant SWORD_DAMAGE => 200;
use constant SWORD_DAMAGE_BONUS_FACTOR => 15;
use constant SWORD_DISTANCE => 10;
use constant SWORD_GAUGE_VELOCITY_BONUS => 20;
use constant SWORD_VELOCITY => 8;
use constant SWORD_WIN => 12;
use constant SWORD_ENERGY => 50000;
use constant VELOCITY_LIMIT => 11;
use constant LANDING_RANGE => 20000;
use constant LANDING_VELOCITY => 3;
use constant LANDING_DISTANCE => 10;
use constant SIGHT_TOLERANCE => 10000;
use constant SIGHT_LANDED_BONUS => 40000;
use constant SIGHT_MINIMUM => 10000;
use constant ELEMENT_TAGS => { 'asteroid' => 'AST',
                               'mecha'    => 'MEC',
                               'waypoint' => 'WP', 
                               'position' => 'POS' };
use constant FILTERS => { 'waypoints' => { 'waypoints' => ['WP'] },
                          'sighted-by-me' => { 'sighted_by_me' => ['MEC'] },
                          'sighted-by-faction' =>  { 'sighted_by_faction' => ['MEC'] },
                          'visible' => {  'sighted_by_faction' => ['MEC'],
                                          'map_elements' => ['WP', 'AST'] },
                          'hotspots' => { 'hotspots' => ['AST'] },
                          'landing' => { 'landing' => ['AST'] },
                          'last-sight' => { 'last_sight' => ['POS'] },
                        };
use constant ENERGY_STANDARD_BONUS => 1;
use constant ENERGY_HIGH_VELOCITY_MALUS => 1;
use constant ENERGY_MAX_VELOCITY_MALUS => 2;
use constant ENERGY_SWORD_VELOCITY_MALUS => 4;
use constant ENERGY_AVAILABLE_FOR_HIGH_SPEED => 1000;

our @EXPORT_OK = (
    'GET_AWAY_DISTANCE',
    'MACHINEGUN_DAMAGE',
    'MACHINEGUN_GAUGE',
    'MACHINEGUN_RANGE',
    'MACHINEGUN_SHOTS',
    'MACHINEGUN_SWORD_GAUGE_DAMAGE',
    'MACHINEGUN_WIN',
    'NEARBY',
    'RIFLE_ATTACK_TIME_LIMIT',
    'RIFLE_DAMAGE',
    'RIFLE_GAUGE',
    'RIFLE_MAX_DISTANCE',
    'RIFLE_MIN_DISTANCE',
    'RIFLE_SWORD_GAUGE_DAMAGE',
    'RIFLE_WIN',
    'RIFLE_LANDED_BONUS',
    'RIFLE_ENERGY',
    'SWORD_ATTACK_TIME_LIMIT',
    'SWORD_BOUNCE',
    'SWORD_DAMAGE',
    'SWORD_DAMAGE_BONUS_FACTOR',
    'SWORD_DISTANCE',
    'SWORD_GAUGE_VELOCITY_BONUS',
    'SWORD_VELOCITY',
    'SWORD_WIN',
    'SWORD_ENERGY',
    'VELOCITY_LIMIT',
    'LANDING_RANGE',
    'LANDING_VELOCITY',
    'LANDING_DISTANCE',
    'SIGHT_TOLERANCE',
    'SIGHT_LANDED_BONUS',
    'SIGHT_MINIMUM',
    'ELEMENT_TAGS',
    'FILTERS',
    'ENERGY_STANDARD_BONUS',
    'ENERGY_HIGH_VELOCITY_MALUS',
    'ENERGY_MAX_VELOCITY_MALUS',
    'ENERGY_SWORD_VELOCITY_MALUS',
    'ENERGY_AVAILABLE_FOR_HIGH_SPEED', 
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );


 
