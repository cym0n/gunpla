package Gunpla::World;

use v5.10;
use POSIX;
use Moo;
use MongoDB;
use Gunpla::Position;
use Gunpla::Mecha;

use constant SIGHT_TOLERANCE => 10000;
use constant MECHA_NEARBY => 1000;
use constant SWORD_DISTANCE => 10;
use constant SWORD_ATTACK_TIME_LIMIT => 4000;
use constant SWORD_WIN => 12;
use constant SWORD_BOUNCE => 200;
use constant SWORD_DAMAGE => 100;
use constant SWORD_DAMAGE_BONUS_FACTOR => 15;
use constant SWORD_GAUGE_VELOCITY_BONUS => 20;
use constant MACHINEGUN_GAUGE => 400;
use constant MACHINEGUN_SHOTS => 3;
use constant MACHINEGUN_RANGE => 1000;
use constant MACHINEGUN_WIN => 10;
use constant MACHINEGUN_DAMAGE => 20;
use constant MACHINEGUN_SWORD_GAUGE_DAMAGE => 300; 
use constant GET_AWAY_DISTANCE => 30000;

has name => (
    is => 'ro',
);

has waypoints => (
    is => 'ro',
    default => sub { {} }
);

has armies => (
    is => 'ro',
    default => sub { [] }
);

has spawn_points => (
    is => 'ro',
    default => sub { {} }
);
has sighting_matrix => (
    is => 'rw',
    default => sub { {} }
);
has generated_events => (
    is => 'rw',
    default => 0
);
has available_commands => (
    is => 'ro',
    default => sub { {} }
);

#Only for test purpose
has dice_results => (
    is => 'ro',
    default => sub { [] }
);




#Dummy implementation of mecha characteristics
has mecha_templates => (
    is => 'ro',
    default => sub {
        {
            'Diver' => { sensor_range => 140000, life => 1000, max_velocity => 6, acceleration => 100000  },
            'Zaku'  => { sensor_range => 80000,  life => 1000, max_velocity => 6, acceleration => 100000 },
            'Gelgoog'  => { sensor_range => 130000,  life => 1000, max_velocity => 6, acceleration => 100000 },
            'Dummy'  => { sensor_range => 0,  life => 1000, max_velocity => 0, acceleration => 0 },
            'RX78' => { sensor_range => 140000, life => 1000, max_velocity => 10, acceleration => 100  },
            'Hyakushiki' => { sensor_range => 80000, life => 1000, max_velocity => 10, acceleration => 100  },
        }
    }
);





sub add_mecha
{
    my $self = shift;
    my $name = shift;
    my $faction = shift;
    #TODO: check if mecha already exists
    my $template = $self->mecha_templates->{$name};
    $template->{name} = $name;
    $template->{faction} = $faction;
    my $mecha = Gunpla::Mecha->new($template);
    $mecha->position($self->waypoints->{$self->spawn_points->{$faction}}->clone());
    $mecha->set_destination($mecha->position->clone());
    push @{$self->armies}, $mecha;
}

sub get_mecha_by_name
{
    my $self = shift;
    my $name = shift;
    foreach my $m (@{$self->armies})
    {
        return $m if($m->name eq $name);
    }
    return undef;
}

sub configure_command
{
    my $self = shift;
    my $data = shift;
    my $save = shift;
    $self->available_commands->{$data->{code}} = $data;
    if($save)
    {
        my $mongo = MongoDB->connect(); 
        my $db = $mongo->get_database('gunpla_' . $self->name);
        $db->get_collection('available_commands')->insert_one($data);
    }
}


sub build_commands
{
    my $self = shift;   
    $self->configure_command( {
            code => 'flywp',
            label => 'FLY TO WAYPOINT',
            conditions => [  ],
            params_label => 'Select a Waypoint',
            params_callback => '/game/waypoints?game=%%GAME%%',
            params_masternode => 'waypoints',
            machinegun => 1,
            velocity => 1
        }, 1);
    $self->configure_command( {
            code => 'flymec',
            label => 'FLY TO MECHA',
            conditions => [ 'sighted_foe' ],
            params_label => 'Select a Mecha',
            params_callback => '/game/sighted?game=%%GAME%%&mecha=%%MECHA%%',
            params_masternode => 'mechas',
            velocity => 1,
            machinegun => 1
        }, 1);
    $self->configure_command( {
            code => 'sword',
            label => 'SWORD ATTACK',
            conditions => [ 'sighted_foe' ],
            params_label => 'Select a Mecha',
            params_callback => '/game/sighted?game=%%GAME%%&mecha=%%MECHA%%',
            params_masternode => 'mechas',
            machinegun => 0,
            velocity => 0
        }, 1);
    $self->configure_command( {
            code => 'away',
            label => 'GET AWAY',
            conditions => [ ],
            params_label => 'Select a Element',
            params_callback => '/game/visible-elements?game=%%GAME%%&mecha=%%MECHA%%',
            params_masternode => 'elements',
            machinegun => 1,
            velocity => 1
        }, 1);
    $self->configure_command( {
            code => 'rifle',
            label => 'RIFLE',
            conditions => [ 'sighted_foe' ],
            params_label => 'Select a Mecha',
            params_callback => '/game/sighted?game=%%GAME%%&mecha=%%MECHA%%',
            params_masternode => 'mechas',
            machinegun => 0,
            velocity => 0
        }, 1);
}




sub init
{
    my $self = shift;
    say "Init...\n";
    $self->build_commands();
    $self->waypoints->{'center'} = Gunpla::Position->new(x => 0, y => 0, z => 0);
    $self->waypoints->{'blue'} = Gunpla::Position->new(x => 200000, y => 0, z => 0);
    $self->waypoints->{'red'} = Gunpla::Position->new(x => -200000, y => 0, z => 0);
    $self->waypoints->{'alpha'} = Gunpla::Position->new(x => 0, y => -200000, z => 0);
    $self->spawn_points->{'wolf'} = 'blue';
    $self->spawn_points->{'eagle'} = 'red';
    $self->add_mecha("Diver", "wolf");
    $self->add_mecha("Zaku", "eagle");
}
sub init_test
{
    my $self = shift;
    my $type = shift;
    say "Init (test mode $type)...\n";
    $self->build_commands();
    if($type eq 'dummy')
    {
        $self->waypoints->{'center'} = Gunpla::Position->new(x => 0, y => 0, z => 0);
        $self->waypoints->{'blue'} = Gunpla::Position->new(x => 20000, y => 0, z => 0);
        $self->spawn_points->{'wolf'} = 'blue';
        $self->spawn_points->{'testing ground'} = 'center';
        $self->add_mecha("RX78", "wolf");
        $self->add_mecha("Dummy", "testing ground");
    }
    elsif($type eq 'duel')
    {
        $self->waypoints->{'center'} = Gunpla::Position->new(x => 0, y => 0, z => 0);
        $self->waypoints->{'blue'} = Gunpla::Position->new(x => 75000, y => 0, z => 0);
        $self->waypoints->{'red'} = Gunpla::Position->new(x => -75000, y => 0, z => 0);
        $self->waypoints->{'alpha'} = Gunpla::Position->new(x => 0, y => -200000, z => 0);
        $self->spawn_points->{'wolf'} = 'blue';
        $self->spawn_points->{'eagle'} = 'red';
        $self->add_mecha("RX78", "wolf");
        $self->add_mecha("Hyakushiki", "eagle");
    }
}


sub add_command
{
    my $self = shift;
    my $mecha = shift;
    my $command_mongo = shift;
    my $command = $command_mongo->{command};
    my $params = $command_mongo->{params};
    my $secondary_command = $command_mongo->{secondarycommand};
    my $secondary_params = $command_mongo->{secondaryparams};
    my $velocity = $command_mongo->{velocity};
    my $m = $self->get_mecha_by_name($mecha);
    my ($target_type, $target_id) = split('-', $params) if $params;
    if($command eq 'FLY TO WAYPOINT')
    {
        $m->set_destination($self->waypoints->{$target_id}->clone());
        $m->movement_target({ type => 'waypoint', 'name' => $target_id, class => 'fixed'  });
        $m->velocity_target($velocity);
    }
    elsif($command eq 'FLY TO MECHA')
    {
        my $target = $self->get_mecha_by_name($target_id);
    
        $m->set_destination($target->position->clone());
        $m->movement_target({ type => 'mecha', 'name' => $target_id, class => 'dynamic'  });
        $m->velocity_target($velocity);
    }
    elsif($command eq 'SWORD ATTACK')
    {
        my $attack = 'SWORD';
        my $target_name = $target_id;
        my $target = $self->get_mecha_by_name($target_id);

        #Event only if:
        #   command changed (avoid event on resume)
        #   attacker sighted by target
        if((($m->attack && $m->attack ne $attack) ||
           ($m->attack_target->{name} && $m->attack_target->{name} ne $target_id)) &&
            $self->sighting_matrix->{$target_name}->{$mecha} > 0)
        {
            $self->event("$mecha attacking: $attack", [ $target_name ]);
        }
        $m->attack($attack);
        $m->set_destination($target->position->clone());
        $m->movement_target({ type => 'mecha', 'name' => $target_id, class => 'dynamic'  });
        $m->attack_target({ type => 'mecha', 'name' => $target_id, class => 'dynamic'  });
        $m->attack_limit(SWORD_ATTACK_TIME_LIMIT);
        $m->gauge(SWORD_GAUGE_VELOCITY_BONUS * $m->velocity);
    }
    elsif($command eq 'GET AWAY')
    {
        my $target;
        if($target_type eq 'WP')
        {
            $target = $self->waypoints->{$target_id};
        }
        elsif($target_type eq 'MEC')
        {
            my $target_mecha = $self->get_mecha_by_name($target_id);
            $target = $target_mecha->position;
        }
        my $destination = $m->position->away_from($target, GET_AWAY_DISTANCE);
        $m->set_destination($destination);
        $m->movement_target({ type => 'void', name => 'space', class => 'fixed'  });
        $m->velocity_target($velocity);
    }
    elsif($command eq 'WAITING')
    {
        say $m->name . " on waiting status";
        $m->movement_target(undef);
    }
    if($secondary_command)
    {
        if($secondary_command eq 'machinegun')
        {
            my $target_name = $secondary_params;
            my $target = $self->get_mecha_by_name($secondary_params);
            if($m->attack && $m->attack eq 'MACHINEGUN' && $m->attack_limit > 0 && $m->attack_target->{name} eq $target_name)
            {
                #We do nothing, leaving machinegun order to exhaust the shots
            }
            else
            {
                $m->attack_limit(MACHINEGUN_SHOTS);
                $m->attack('MACHINEGUN');
                $m->attack_target({ type => 'mecha', 'name' => $secondary_params, class => 'dynamic'  });
                $m->gauge(0);
            }
        }
    }
    $m->cmd_fetched(1);
}

sub fetch_commands_from_mongo
{
    my $self = shift;
    for(@{$self->armies})
    {
        my $m = $_;
        if((! $m->waiting) && (! $m->cmd_fetched))
        {
            my $mongo = MongoDB->connect();
            my $db = $mongo->get_database('gunpla_' . $self->name);
            my ( $command ) = $db->get_collection('commands')->find({ mecha => $m->name, cmd_index => $m->cmd_index })->all();
            $self->add_command($m->name, $command);
        }
    }
}



sub all_ready
{
    my $self = shift;
    for(@{$self->armies})
    {
        return 0 if $_->waiting;
    }
    return 1;
}

sub all_ready_and_fetched
{
    my $self = shift;
    for(@{$self->armies})
    {
        return 0 if ($_->waiting || (! $_->cmd_fetched));
    }
    return 1;
}


sub action
{
    my $self = shift;
    my $steps = shift;
    my $counter = 0;
    $self->generated_events(0);
    while($self->all_ready && (! $steps || $counter < $steps))
    {
        for(@{$self->armies})
        {
            my $m = $_;
            if($m->movement_target)
            {
                if($m->movement_target->{type} eq 'mecha')
                {
                    if($m->attack && $m->attack eq 'SWORD')
                    {
                        my $target = $self->get_mecha_by_name($m->movement_target->{name});
                        $m->set_destination($target->position->clone);
                        $m->gauge($m->gauge +1);
                        if($m->position->distance($target->position) > SWORD_DISTANCE)
                        {
                            $m->plan_and_move();
                            $m->attack_limit($m->attack_limit -1);
                            if($m->attack_limit == 0)
                            {
                                $m->gauge(0);
                                $self->event($m->name . " exhausted attack charge", [$m->name]);
                            }
                        }
                        else
                        {
                            $self->manage_attack('SWORD', $m);
                        }
                    }
                    else
                    {
                        my $target = $self->get_mecha_by_name($m->movement_target->{name});
                        $m->set_destination($target->position->clone);
                        if($m->position->distance($target->position) > MECHA_NEARBY)
                        {
                            $m->plan_and_move();
                        }
                        else
                        {
                            $self->event($m->name . " reached the nearby of " . $m->movement_target->{type} . " " . $m->movement_target->{name}, [ $m->name ]);
                        }
                    }
                }
                else
                {
                    if(! $m->destination->equals($m->position))
                    {
                        $m->plan_and_move();
                    }
                    else
                    {
                        $self->event($m->name . " reached destination: " . $m->movement_target->{type} . " " . $m->movement_target->{name}, [ $m->name ]);
                    }
                }
            }
            if($m->attack && $m->attack eq 'MACHINEGUN')
            {
                $m->gauge($m->gauge+1);
                if($m->gauge >= MACHINEGUN_GAUGE)
                {
                    my $target = $self->get_mecha_by_name($m->attack_target->{name});
                    if($m->position->distance($target->position) <= MACHINEGUN_RANGE)
                    {
                        $self->manage_attack('MACHINEGUN', $m);
                    }
                }
            }
            $self->calculate_sighting_matrix($m->name);
        }
        $counter++;
    }
    $self->cmd_index_up();
    if($steps && $counter >= $steps)
    {
        $self->event("All steps executed", []);
    }
    return $self->generated_events();
}

sub cmd_index_up
{
    my $self = shift;
    foreach my $m(@{$self->armies})
    {
        if($m->waiting)
        {
            $m->cmd_index($m->cmd_index+1);
        }
    }
}

sub manage_attack
{
    my $self = shift;
    my $attack = shift;
    my $attacker = shift;
    my $defender = $self->get_mecha_by_name($attacker->attack_target->{name});
    if($attack eq 'SWORD')
    {
        #If both are attacking with sword the one with more impact gauge wins
        my $clash = 1;
        if($defender->attack && $defender->attack eq 'SWORD' && $defender->attack_target->{name} eq $attacker->name)
        {
            if($defender->gauge > $attacker->gauge)
            {
                my $switch = $attacker;
                $attacker = $defender;
                $defender = $switch;
            }
            elsif($defender->gauge == $attacker->gauge)
            {
                $attacker->gauge(0);
                $attacker->attack_limit(0);
                $attacker->attack(undef);
                $defender->gauge(0);
                $defender->attack_limit(0);
                $defender->attack(undef);
                $self->event($attacker->name . " and " . $defender->name . " attacks nullified");
                $clash = 0;
                $attacker->velocity(0);
                $defender->velocity(0);
            }
        }
        if($clash)
        {
            my $gauge_bonus = $attacker->gauge < 1200 ? 0 :
                                        $attacker->gauge < 2000 ? 1 :
                                            $attacker->gauge < 4000 ? 2 :
                                                $attacker->gauge < 5600 ? 3 : 4;
            my $roll = $self->dice(1, 20);
            if($roll + $gauge_bonus >= SWORD_WIN)
            {
                $self->event($attacker->name . " slash with sword mecha " .  $defender->name, [ $attacker->name, $defender->name ]);
                my $damage = SWORD_DAMAGE + ($gauge_bonus * SWORD_DAMAGE_BONUS_FACTOR);
                $defender->life($defender->life - $damage);
            }
            else
            {
                $self->event($defender->name . " dodged " .  $attacker->name, [ $attacker->name, $defender->name ]);
            }
            $attacker->gauge(0);
            $attacker->attack_limit(0);
        }
        my @dirs = qw(x y z);
        my $bounce_direction = $dirs[$self->dice(0, 2)];
        $attacker->attack(undef);
        $attacker->attack_limit(0);
        $attacker->velocity(0);
        $attacker->gauge(0);
        $attacker->position->$bounce_direction($attacker->position->$bounce_direction - SWORD_BOUNCE);
        $defender->attack(undef);
        $defender->attack_limit(0);
        $defender->velocity(0);
        $defender->gauge(0);
        $defender->position->$bounce_direction($defender->position->$bounce_direction + SWORD_BOUNCE);
    }
    elsif($attack eq 'MACHINEGUN')
    {
        $attacker->gauge(0);
        my $distance = $attacker->position->distance($defender->position);
        my $distance_bonus = 3 - ceil((3 * $distance) / MACHINEGUN_RANGE);
        my $roll = $self->dice(1, 20);
        if($roll + $distance_bonus >= MACHINEGUN_WIN)
        {
            $defender->life($defender->life - MACHINEGUN_DAMAGE);   
            if($defender->attack && $defender->attack eq 'SWORD')
            {
                $defender->gauge($defender->gauge - MACHINEGUN_SWORD_GAUGE_DAMAGE);
            }
            $self->event($attacker->name . " hits with machine gun " .  $defender->name, [ $defender->name ]);
        }
        else
        {
            say $attacker->name . " missed " . $defender->name . " with machine gun";
        }
        $attacker->attack_limit($attacker->attack_limit - 1);
        if($attacker->attack_limit == 0)
        {
            $self->event($attacker->name . " ended machine gun shots", [ $attacker->name ]);
        }
    }
}

sub dice
{
    my $self = shift;
    my $min = shift;
    my $max = shift;
    if(@{$self->dice_results})
    {
        return shift @{$self->dice_results};
    }
    my $random_range = $max - $min + 1;
    my $out = int(rand($random_range)) + $min;
    return $out;
}

sub event
{
    my $self = shift;
    my $message = shift;
    my $involved = shift;

    my $mongo = MongoDB->connect(); 
    my $db = $mongo->get_database('gunpla_' . $self->name);
    for(@{$involved})
    {
        my $m = $self->get_mecha_by_name($_);
        say "Adding event for " . $m->name; 
        #$m->cmd_index($m->cmd_index + 1);
        my $cmd_index = $m->cmd_index + 1;
        $db->get_collection('events')->insert_one({ message   => $message,
                                                    mecha     => $m->name,
                                                    cmd_index => $cmd_index });
        $m->waiting(1);
        $m->cmd_fetched(0);
        $self->generated_events($self->generated_events + 1);
    }
}

sub is_spawn_point
{
    my $self = shift;
    my $name = shift;
    for(keys %{$self->spawn_points})
    {
        if($self->spawn_points->{$_} eq $name)
        {
            return $_;
        }
    }
    return 0;
}


sub save
{
    my $self = shift;
    my $mongo = MongoDB->connect(); 
    my $db = $mongo->get_database('gunpla_' . $self->name);
    $db->get_collection('mechas')->drop();
    $db->get_collection('map')->drop();
    $db->get_collection('status')->drop();
    foreach my $m (@{$self->armies})
    {
        $db->get_collection('mechas')->insert_one($m->to_mongo);
    }
    foreach my $wp (keys %{$self->waypoints})
    {
        my $wp_mongo = {
            name => $wp,
            type => 'waypoint',
            position => $self->waypoints->{$wp}->to_mongo(),
            spawn_point => $self->is_spawn_point($wp)
        };
        $db->get_collection('map')->insert_one($wp_mongo);
    }
    my $sighting_matrix = $self->sighting_matrix;
    $sighting_matrix->{status_element} = 'sighting_matrix';
    $db->get_collection('status')->insert_one($sighting_matrix);
}

sub load
{
    my $self = shift;
    my $mongo = MongoDB->connect();
    my $db = $mongo->get_database('gunpla_' . $self->name);
    my @mecha = $db->get_collection('mechas')->find()->all();
    for(@mecha)
    {
        push @{$self->armies}, Gunpla::Mecha->from_mongo($_);
    }
    my @map_points = $db->get_collection('map')->find()->all();
    foreach my $mapp (@map_points)
    {
        if($mapp->{type} eq 'waypoint')
        {
            $self->waypoints->{$mapp->{name}} = Gunpla::Position->from_mongo($mapp->{position});
            if($mapp->{spawn_point})
            {
                $self->spawn_points->{$mapp->{spawn_point}} = $mapp->{name};
            }
        }
    }
    my ( $sighting_matrix ) = $db->get_collection('status')->find({ status_element => 'sighting_matrix' })->all();
    delete $sighting_matrix->{status_element};
    $self->sighting_matrix($sighting_matrix);
    
    my @commands = $db->get_collection('available_commands')->find()->all();
    for(@commands)
    {
        $self->configure_command($_);
    }
}


sub calculate_sighting_matrix
{
    my $self = shift;
    my $mecha_name = shift;
    my $m = $self->get_mecha_by_name($mecha_name);
    foreach my $other (@{$self->armies})      
    {
        if($m->faction ne $other->faction) #Mechas of the same faction are always visible each other 
        {
            if(! exists $self->sighting_matrix->{$m->name}->{$other->name})
            {
                $self->sighting_matrix->{$m->name}->{$other->name} = 0;
            }
            if($m->position->distance($other->position) < $m->sensor_range)
            {
                if($self->sighting_matrix->{$m->name}->{$other->name} == 0)
                {
                    $self->event($m->name . " sighted " . $other->name, [ $m->name ]);
                }
                $self->sighting_matrix->{$m->name}->{$other->name} = SIGHT_TOLERANCE;
            }
            else
            {
                if($self->sighting_matrix->{$m->name}->{$other->name} > 0)
                {
                    $self->sighting_matrix->{$m->name}->{$other->name} -= 1;
                    if($self->sighting_matrix->{$m->name}->{$other->name} == 0)
                    {
                        $self->event($m->name . " lost contact with " . $other->name, [ $m->name ]);
                    }
                }
            }
        }
    }
}

1;

