package Gunpla::World;

use v5.10;
use POSIX;
use Moo;
use DateTime;
use MongoDB;
use Cwd 'abs_path';
use JSON::XS;
use Gunpla::Constants ':all';
use Gunpla::Utils qw(get_game_events);
use Gunpla::Position;
use Gunpla::Mecha;
use Gunpla::Sight;
use Data::Dumper;
use Config::Any;


has name => (
    is => 'ro',
);
has config => (
    is => 'rw',
    default => sub { {} }
);

has waypoints => (
    is => 'ro',
    default => sub { {} }
);

has armies => (
    is => 'rw',
    default => sub { [] }
);
has map_elements => (
    is => 'ro',
    default => sub { [] }
);

has spawn_points => (
    is => 'ro',
    default => sub { {} }
);
has sighting_matrix => (
    is => 'rw',
);
has generated_events => (
    is => 'rw',
    default => 0
);
has available_commands => (
    is => 'ro',
    default => sub { {} }
);
has no_events => (
    is => 'rw',
    default => 0
);
has save_every => (
    is => 'rw',
    default => 0
);
has timestamp => (
    is => 'rw',
    default => 0
);
has control => (
    is => 'rw',
    default => sub { {} }
);
has inertia => (
    is => 'rw',
    default => 1
);
has cemetery => (
    is => 'rw',
    default => sub { [] }
);

#Only for test purpose
has dice_results => (
    is => 'ro',
    default => sub { [] }
);

has log_file => (
    is => 'rw',
);
has log_tracing => (
    is => 'rw',
    default => sub { [] }
);
has log_stderr => (
    is => 'rw',
    default => 0
);

#Dummy implementation of mecha characteristics
has mecha_templates => (
    is => 'ro',
    default => sub { {} }
);

sub load_config
{
    my $self = shift;
    my $cfg_file = shift;
    my $module_file_path = __FILE__;
    my $root_path = abs_path($module_file_path);
    $root_path =~ s/World\.pm//;
    my $data_directory = $root_path . "../../config";

    my @files = ( "$data_directory/default.yaml" );
    push @files, "$data_directory/$cfg_file" if($cfg_file);
    my $cfg = Config::Any->load_files({files => \@files, use_ext => 1, flatten_to_hash => 1 }); 
    my $game_config = {};
    foreach my $f (@files)
    {
        $self->log("Loading config file $f");
        foreach my $k (keys %{$cfg->{$f}})
        {
            $game_config->{$k} = $cfg->{$f}->{$k}
        }
    }
    $self->config($game_config);
}

sub add_mecha
{
    my $self = shift;
    my $name = shift;
    my $faction = shift;
    my $ia = shift;
    my $ia_configuration = shift;
    my $template;
    if($name =~ /^(.*?)\-(\d+)$/)
    {
        $template = $self->mecha_templates->{$1};
    }
    else
    {
        $template = $self->mecha_templates->{$name};
    }
    die "NO TEMPLATE for $name" if ! $template;
    $template->{name} = $name;
    $template->{faction} = $faction;
    $template->{log_file} = $self->log_file;
    $template->{config} = $self->config;
    die "Mecha with name $name already present" if($self->get_mecha_by_name($name));
    my $mecha = Gunpla::Mecha->new($template);
    
    $mecha->position($self->waypoints->{$self->spawn_points->{$faction}}->clone());
    $mecha->set_destination($mecha->position->clone());
    $mecha->start_gauges();

    push @{$self->armies}, $mecha;
    return $mecha;
}



sub get_mecha_by_name
{
    my $self = shift;
    my $name = shift;
    my $dead_or_alive = shift;
    foreach my $m (@{$self->armies})
    {
        return $m if($m->name eq $name);
    }
    foreach my $m (@{$self->cemetery})
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
            filter => 'waypoints',
            params_label => 'Select a Waypoint',
            machinegun => 1,
            velocity => 1,
            min_distance => 0,
        }, 1);
    $self->configure_command( {
            code => 'flymec',
            label => 'FLY TO MECHA',
            filter => 'sighted-by-faction',
            params_label => 'Select a Mecha',
            velocity => 1,
            machinegun => 1,
            min_distance => $self->config->{NEARBY},
        }, 1);
    $self->configure_command( {
            code => 'flyhot',
            label => 'FLY TO HOTSPOT',
            filter => 'hotspots',
            params_label => 'Select a Hotspot',
            velocity => 1,
            machinegun => 1,
            min_distance => $self->config->{NEARBY},
        }, 1);
    $self->configure_command( {
            code => 'sword',
            label => 'SWORD ATTACK',
            filter => 'sighted-by-faction',
            params_label => 'Select a Mecha',
            machinegun => 0,
            velocity => 0,
            energy_needed => $self->config->{SWORD_ENERGY_NEEDED},
        }, 1);
    $self->configure_command( {
            code => 'away',
            label => 'GET AWAY',
            filter => 'visible',
            params_label => 'Select a Element',
            machinegun => 1,
            velocity => 1
        }, 1);
    $self->configure_command( {
            code => 'rifle',
            label => 'RIFLE',
            filter => 'sighted-by-faction',
            params_label => 'Select a Mecha',
            machinegun => 0,
            velocity => 0,
            energy_needed => $self->config->{RIFLE_ENERGY_NEEDED},
        }, 1);
    $self->configure_command( {
            code => 'land',
            label => 'LAND',
            filter => 'landing',
            params_label => 'Select a Hotspot',
            machinegun => 0,
            velocity => 0,
            min_distance => 0,
            max_distance => $self->config->{LANDING_RANGE},
        }, 1);
    $self->configure_command( {
            code => 'last',
            label => 'FLY TO LAST KNOWN POSITION',
            filter => 'last-sight',
            params_label => 'Select a Mecha',
            machinegun => 1,
            velocity => 1,
            min_distance => 0,
        }, 1);
    $self->configure_command( {
            code => 'guard',
            label => 'GUARD',
            filter => undef,
            values => {'20000' => '20000', '50000' => '50000', '70000' => '70000'},
            params_label => 'Select time interval',
            machinegun => 0,
            velocity => 0,
            min_distance => 0,
        }, 1);
    $self->configure_command( {
            code => 'support',
            label => 'ASK SUPPORT',
            filter => 'friends-no-wait',
            params_label => 'Select friendly Mecha',
            machinegun => 0,
            velocity => 0,
        }, 1);
}




sub init
{
    my $self = shift;
    $self->init_scenario('basic.csv');
}
sub init_test
{
    my $self = shift;
    my $type = shift;
    if($type eq 'dummy')
    {
        $self->init_scenario('dummy.csv');
    }
    elsif($type eq 'duel')
    {
        $self->init_scenario('duel.csv');
    } 
}

sub init_mecha_templates
{
    my $self = shift;
    my $file = shift || 'standard.csv';
    my $module_file_path = __FILE__;
    my $root_path = abs_path($module_file_path);
    $root_path =~ s/World\.pm//;
    my $data_directory = $root_path . "../../scenarios/mechas";
    open(my $fh, "< $data_directory/$file") || die "Impossible to open $data_directory/$file";
    my $header = <$fh>;
    $self->log("Mecha templates: " . $file);
    for(<$fh>)
    {
        chomp;
        my @values = split ";", $_;
        $self->mecha_templates->{$values[0]} = {
            life => $values[1],
            sensor_range => $values[2],
            acceleration => $values[3],
            max_velocity => $values[4],
            energy => $values[5],
            max_energy => $values[6]
        }
    }
}


sub init_scenario
{
    my $self = shift;
    my $file = shift;
    my $config = shift;
    my $templates = shift;
    $self->load_config($config);
    my $module_file_path = __FILE__;
    my $root_path = abs_path($module_file_path);
    $root_path =~ s/World\.pm//;
    my $data_directory = $root_path . "../../scenarios";
    $self->build_commands();
    $self->init_mecha_templates($templates);
    my %counters = ( "MEC" => 0,
                     "MEC-IA" => 0,
                     "AST" => 0,
                     "SAR" => 0 );
    open(my $fh, "< $data_directory/$file") || die "Impossible to open $data_directory/$file";
    for(<$fh>)
    {
        chomp;
        my @values = split ";", $_;
        if($values[0] eq 'WP')
        {
            $self->waypoints->{$values[1]} = Gunpla::Position->new(x => $values[2], y => $values[3], z => $values[4]);
            if( $values[5] )
            {
                $self->spawn_points->{$values[5]} = $values[1];
            }
        }
        elsif($values[0] eq 'MEC')
        {
            my $m = $self->add_mecha($values[1], $values[2]);#, $values[3], $values[4]);
            if($values[3])
            {
                my $ia_conf = undef;
                if($values[4])
                {
                    my $ia_conf_text = do {
                        open(my $json_fh, "<:encoding(UTF-8)", $data_directory . '/ia/' . $values[4])
                            or die("Can't open $values[4]: $!\n");
                        local $/;
                        <$json_fh>
                    };
                    $ia_conf = JSON::XS->new->utf8->decode($ia_conf_text);
                }
                $m->install_ia($self->name, $counters{'MEC-IA'}, $values[3], $ia_conf);
                $counters{'MEC-IA'} = $counters{'MEC-IA'} + 1;
            }
            $counters{'MEC'} = $counters{'MEC'} + 1;
        }
        elsif($values[0] eq 'AST' || $values[0] eq 'SAR')
        {
            my $tag = $values[0];
            push @{$self->map_elements}, { id => $counters{$tag}, type => $values[0],
                                           position =>  Gunpla::Position->new(x => $values[1], y => $values[2], z => $values[3]) };
            $counters{$tag} = $counters{$tag} + 1;
        }
        elsif($values[0] eq 'PLY')
        {
            $self->control->{$values[1]} = $values[2];
        }
    }
    my $sight = Gunpla::Sight->new({config => $self->config});
    $sight->init($self->armies);
    $self->sighting_matrix($sight);
    $self->sighting_matrix->calculate(undef, $self->armies); #Trashing away events
    $self->ia();
}

sub get_map_element
{
    my $self = shift;
    my $type = shift;
    my $id = shift;
    for(@{$self->map_elements})
    {
        if($_->{type} eq $type && $_->{id} == $id)
        {
            return $_;
        }
    }
    return undef;
}


sub get_target_from_world_id
{
    my $self = shift;
    my $target_id = shift;
    return undef if ! $target_id;
    my $dead_or_alive = shift;
    my $target_type;
    my $target_name;
    if($target_id =~ /(\d+),(\d+),(\d+)/)
    {
        my $position = Gunpla::Position->new( x => $1, y => $2, z => $3);
        return { name => 'space' , position => $position };
    }
    elsif($target_id =~ /^(.*?)\-(.*)$/)
    {
        $target_type = $1;
        $target_name = $2;
    }
    return undef if ((! defined $target_type) || (! defined $target_name));
    #my ($target_type, $target_name) = split('-', $target_id);

    if($target_type eq 'WP')
    {
        return { name => $target_name, position => $self->waypoints->{$target_name}};
    }
    elsif($target_type eq 'MEC')
    {
        return $self->get_mecha_by_name($target_name, $dead_or_alive, $dead_or_alive);
    }
    else
    {
        return $self->get_map_element($target_type, $target_name);
    }
}
sub get_position_from_movement_target
{
    my $self = shift;
    my $movement_target = shift;
    if($movement_target->{type} eq 'MEC')
    {
        my $m = $self->get_mecha_by_name($movement_target->{name});
        return $m->position->clone();
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
    eval {
        if($m->inertia == 0 || ! $self->inertia)
        {
            $self->log("ADD COMMAND to $mecha" . "[" . $m->cmd_index . "]: " . $self->command_string($command_mongo));
            my $params_elaborated;
            if($self->available_commands->{$command_mongo->{command}}->{filter})
            {
                my $dead_or_alive = 0;
                $dead_or_alive = 1 if ($command_mongo->{command} eq 'last');
                $params_elaborated = $self->get_target_from_world_id($params, $dead_or_alive);
            }
            elsif($self->available_commands->{$command_mongo->{command}}->{values})
            {
                $params_elaborated = $params;
            }
            else
            {
                $params_elaborated = undef;
            }
            $m->command($command, $params_elaborated, $velocity);
            if($command eq 'sword')
            {
                $self->log($m->name. " starting attack gauge: " . $m->get_gauge_level('sword'));
            }
            if($command eq 'support')
            {
                #Allow mecha to keep direction. If destination is reached just make it drift.
                #Support command does not change movement target
                if($self->arrived($m))
                {
                    $m->movement_target({ type => 'drifting' });
                }
            }
            if($secondary_command)
            {
                if($secondary_command eq 'machinegun')
                {
                    $m->command('machinegun', $self->get_target_from_world_id($secondary_params), undef);
                }
                elsif($secondary_command eq 'boost')
                {
                    $m->command('boost', undef, undef);
                }
            }
        }
        else
        {
            $self->log("SUSPENDED COMMAND for $mecha: " . $self->command_string($command_mongo));
            $m->suspended_command($command_mongo);
            if($m->is_status('stuck'))
            {
                $self->log("$mecha is stuck");
            }
        }
    };
    if($@)
    {
        $self->log("ERROR: $@");
        $m->waiting(1);
        $self->cmd_index_up();
    }
    else
    {
        $m->cmd_fetched(1);
    }
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

sub arrived
{
    my $self = shift;
    my $m = shift;
    return 'NOMOVEMENT' if ! %{$m->movement_target};
    return 0 if $m->movement_target->{type} eq 'drifting';
    if($m->movement_target->{class} eq 'dynamic')
    {
        $m->destination($self->get_position_from_movement_target($m->movement_target));
    }              
    if($m->attack && $m->attack eq 'SWORD')
    {
        my $target = $self->get_mecha_by_name($m->movement_target->{name});
        return $m->position->distance($target->position) <= $self->config->{SWORD_DISTANCE} ? 'SWORD' : 0;
    }
    elsif($m->action && $m->action eq 'LAND')
    {
        return $m->position->distance($m->destination) <= $self->config->{LANDING_DISTANCE} ? 'LAND' : 0;
    }
    elsif($m->destination->equals($m->position))
    {
        return 'ARRIVED';
    }
    elsif($m->movement_target->{nearby} && $m->position->distance($m->destination) < $self->config->{NEARBY})
    {
        return 'NEARBY';
    }
    else
    {
        return 0;
    }
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
            next if ! $self->get_mecha_by_name($m->name); #check needed for dead mechas
            $m->mod_inertia(-1);
            if($m->inertia == 0 && $m->suspended_command)
            {
                $self->add_command($m->name, $m->suspended_command);
                $m->suspended_command(undef);
            }
            if($m->is_status('stuck'))
            {
                $m->drift_and_move($self->dice(0, 2, "drift direction"));
            }
            else
            {
                if(%{$m->movement_target})
                {
                    if(my $is_arrived = $self->arrived($m))
                    {
                        if($is_arrived eq 'SWORD')
                        {
                            $self->manage_attack('SWORD', $m);
                        }
                        elsif($is_arrived eq 'LAND')
                        {
                            $self->manage_action('LAND', $m);
                        } 
                        elsif($is_arrived eq 'ARRIVED')
                        {
                            $self->event($m->name . " reached destination: " . ELEMENT_TAGS->{$m->movement_target->{type}} . " " . $m->movement_target->{name}, [ $m->name ], [ $m->name ]);
                        }
                        elsif($is_arrived eq 'NEARBY')
                        {
                            $self->event($m->name . " reached the nearby of " . ELEMENT_TAGS->{$m->movement_target->{type}} . " " . $m->movement_target->{name}, [ $m->name ], [ $m->name ]);
                        }
                    }
                    else
                    {
                        if($m->attack && $m->attack eq 'SWORD')
                        {
                            $m->run_gauge('sword');
                            $m->attack_limit($m->attack_limit -1);
                            if($m->attack_limit == 0)
                            {
                                $m->stop_attack();
                                $self->event($m->name . " exhausted attack charge", [$m->name], [$m->name]);
                            }
                        }
                        if($m->action && $m->action eq 'BOOST')
                        {
                            if($m->run_gauge('boost'))
                            {
                                $self->event($m->name . " exhausted boost", [ $m->name ]);
                            }
                        }
                        if($m->action && $m->action eq 'SUPPORT')
                        {
                            if($m->run_gauge('support'))
                            {
                                $m->reset_gauge('support'); #We reset this because another support action would be misrecognized as resume
                                $self->event($m->name . " ask for support to " . $m->action_target->{name}, [$m->name, $m->action_target->{name}], [$m->name]);
                            }
                        }
                        if($m->movement_target->{type} eq 'drifting')
                        {
                            $m->drift_and_move($self->dice(0, 2, "drift direction"));
                        }
                        else
                        {
                            $m->plan_and_move();
                        }
                    }
                }
                elsif($m->attack_target->{class} && $m->attack_target->{class} eq 'dynamic')
                {
                    #We record the position of the target to track him (this is only on RIFLE)
                    $m->destination($self->get_position_from_movement_target($m->attack_target));
                }
                if($m->action)
                {
                    if($m->action eq 'GUARD')
                    {
                        if($m->run_gauge('guard'))
                        {
                            $self->event($m->name . " ended the guard", [ $m->name ], [ $m->name ]);
                        }
                    }
                }
                if($m->attack)
                {
                    if($m->attack eq 'MACHINEGUN')
                    {
                        if($m->run_gauge('machinegun'))
                        {
                            my $target = $self->get_mecha_by_name($m->attack_target->{name});
                            if($m->position->distance($target->position) <= $self->config->{MACHINEGUN_RANGE})
                            {
                                $self->manage_attack('MACHINEGUN', $m);
                            }
                        }
                    }
                    elsif($m->attack eq 'RIFLE')
                    {
                        my $target = $self->get_mecha_by_name($m->attack_target->{name});
                        if($m->position->distance($target->position) < $self->config->{RIFLE_MIN_DISTANCE})
                        {
                            $self->event($m->name . ": rifle target " . $target->name . " too close", [ $m->name ], [ $m->name ]);
                        }
                        else
                        {
                            if($m->run_gauge('rifle'))
                            {
                                if($m->position->distance($target->position) <= $self->config->{RIFLE_MAX_DISTANCE})
                                {
                                    $self->manage_attack('RIFLE', $m);
                                }
                            }
                        }
                        $m->attack_limit($m->attack_limit -1);
                        if($m->attack_limit == 0)
                        {
                            $m->stop_attack();
                            $m->mod_inertia($self->config->{INERTIA_RIFLE_TOO_CLOSE});
                            $self->event($m->name . " time for rifle shot exhausted", [$m->name], [ $m->name ]);
                        }
                    }
                }
            }
            $m->energy_routine();
            if($m->energy == 0)
            {
                $self->event($m->name . " exhausted energy", [$m->name]);
            }
            my @out_events = $self->sighting_matrix->calculate($m->name, $self->armies);
            $self->process_sight_events(@out_events);
        }
        $counter++;
        $self->timestamp($self->timestamp+1);
        if($self->save_every && $counter % $self->save_every == 0)
        {
            $self->save_light();
        }
    }
    return 0 if($self->ia_only);
    $self->cmd_index_up();
    $self->ia(1) unless $steps && $counter == $steps;
    return $self->generated_events();
}

sub ia_only
{
    my $self = shift;
    for(@{$self->armies})
    {
        return 0 if ! $_->ia;
    }
    return 1;
}

sub process_sight_events
{
    my $self = shift;
    my @events = @_;
    my @already = ();
    foreach my $e (@events)
    {
        if($e->[2] == 1)
        {
            $self->event($e->[0] . " sighted " . $e->[1], [ $e->[0] ]);
        }
        elsif($e->[2] == -1)
        {
            my $m = $self->get_mecha_by_name($e->[0]);
            my $other = $self->get_mecha_by_name($e->[1]);
            next if ! $m || ! $other;
            my $check_faction = $m->faction;
            my $check_name = $other->name;
            if(! $self->sighting_matrix->see_faction($check_faction, $check_name) && 
               ! grep { $_ eq "$check_faction $check_name"} @already)
            {
                my $involved = {};
                my $stuck = [];
                foreach my $sighting (@{$self->armies})
                {
                    if($sighting->faction eq $check_faction)
                    {
                        if($sighting->relevant_target('MEC', $check_name))
                        {
                            if($sighting->attack && $sighting->attack eq 'MACHINEGUN')
                            {
                                $sighting->stop_attack();
                                if($sighting->relevant_target('MEC', $check_name))
                                {
                                    $involved->{$sighting->name} = 1;
                                    push @{$stuck}, $sighting->name;
                                }
                                else
                                {
                                    $involved->{$sighting->name} = 0;
                                }
                            }
                            else
                            {
                                $involved->{$sighting->name} = 1;
                                push @{$stuck}, $sighting->name;
                            }
                        }
                        else
                        {
                            $involved->{$sighting->name} = 0;
                        }
                    }
                }                            
                push @already, "$check_faction $check_name";
                $self->event("contact lost: " . $other->name, $involved, $stuck);
            }
        }
    }

}



sub ia
{
    my $self = shift;
    my $run = shift;
    $self->save_light();
    foreach my $m(@{$self->armies})
    {
        if($m->waiting)
        {
            if($m->ia)
            {
                my $command = $m->decide();        
                if($command)
                {
                    $command->{IA} = 1;
                    $m->waiting(0);
                    $self->add_command($m->name, $command);
                    $m->cmd_fetched(1) if ! $m->waiting;
                }
            }
        }
    }
    $self->action() if $self->all_ready() && $run;
}

sub command_string
{
    my $self = shift;
    my $command = shift;
    my $out = $command->{command};
    if($command->{params})
    {
        $out .= " " . $command->{params};
    }
    if($command->{velocity})
    {
        $out .= " [v" . $command->{velocity} . "]";
    }
    if($command->{secondarycommand})
    {
        $out .= " " . $command->{secondarycommand};
    }
    if($command->{secondaryparams})
    {
        $out .= " " . $command->{secondaryparams};
    }
    if($command->{IA})
    {
        $out .= " <<IA>>";
    }
    return $out;


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
    $self->save_light();
}

sub manage_attack
{
    my $self = shift;
    my $attack = shift;
    my $attacker = shift;
    my $defender = $self->get_mecha_by_name($attacker->attack_target->{name});
    if($attack eq 'SWORD')
    {
        if($attacker->energy < $self->config->{SWORD_ENERGY})
        {
            $self->event($attacker->name . ": not enough energy for sword", [$attacker->name], [ $attacker->name ]);
            return;
        }
        #If both are attacking with sword the one with more impact gauge wins
        my $clash = 1;
        if($defender->attack && $defender->attack eq 'SWORD' && $defender->attack_target->{name} eq $attacker->name)
        {
            $self->log($attacker->name . " gauge: ". $attacker->get_gauge_level('sword') . " VS " . $defender->name . " gauge: ". $defender->get_gauge_level('sword'));
            if($defender->get_gauge_level('sword') > $attacker->get_gauge_level('sword') || $defender->energy < $self->config->{SWORD_ENERGY})
            {
                my $switch = $attacker;
                $attacker = $defender;
                $defender = $switch;
            }
            elsif($defender->get_gauge_level('sword') == $attacker->get_gauge_level('sword'))
            {
                $self->event($attacker->name . " and " . $defender->name . " attacks nullified",  [ $attacker->name, $defender->name ],  [ $attacker->name, $defender->name ] );
                $clash = 0;
                $attacker->stop_attack();
                $attacker->stop_action();
                $attacker->stop_movement();
                $attacker->add_energy(-1 * $self->config->{SWORD_ENERGY});
                $attacker->mod_inertia($self->config->{INERTIA_SWORD_NULLIFIED});
                $defender->stop_action();
                $defender->stop_attack();
                $defender->stop_movement();
                $defender->add_energy(-1 * $self->config->{SWORD_ENERGY});
                $defender->mod_inertia($self->config->{INERTIA_SWORD_NULLIFIED});
                $self->sighting_matrix->force_sighting($attacker, $defender, 1);
            }
        }
        if($clash)
        {
            my $gauge = $attacker->get_gauge_level('sword');
            my $gauge_bonus = $gauge < 1200 ? 0 :
                                $gauge < 2000 ? 1 :
                                    $gauge < 4000 ? 2 :
                                        $gauge < 5600 ? 3 : 4;

            if($self->hitting("sword clash", $gauge_bonus, $self->config->{SWORD_WIN}))
            {
                my $damage = $self->config->{SWORD_DAMAGE} + ($gauge_bonus * $self->config->{SWORD_DAMAGE_BONUS_FACTOR});
                $defender->mod_life(-1 * $damage);
                $defender->mod_inertia($self->config->{INERTIA_SWORD_SLASH});
                $self->event($attacker->name . " slash with sword mecha " .  $defender->name, [ $attacker->name, $defender->name ],  [ $attacker->name, $defender->name ]);
            }
            else
            {
                $attacker->mod_inertia($self->config->{INERTIA_SWORD_DODGE});
                $self->event($defender->name . " dodged " .  $attacker->name, [ $attacker->name, $defender->name ], [ $attacker->name]);
            }
        }
        my @dirs = qw(x y z);
        my $bounce_direction = $dirs[$self->dice(0, 2, "sword bounce direction")];
        $attacker->position->$bounce_direction($attacker->position->$bounce_direction - $self->config->{SWORD_BOUNCE});
        $attacker->stop_attack();
        $attacker->stop_action();
        $attacker->stop_movement();
        $attacker->add_energy(-1 * $self->config->{SWORD_ENERGY});
        $defender->position->$bounce_direction($defender->position->$bounce_direction + $self->config->{SWORD_BOUNCE});
        $defender->stop_attack();
        $defender->stop_action();
        $defender->stop_movement();
        $self->sighting_matrix->force_sighting($attacker, $defender, 1);
        $self->collect_dead();
    }
    elsif($attack eq 'MACHINEGUN')
    {
        $attacker->reset_gauge('machinegun');
        my $distance = $attacker->position->distance($defender->position);
        my $distance_bonus = 3 - ceil((3 * $distance) / $self->config->{MACHINEGUN_RANGE});
        if($self->hitting("machinegun hit", $distance_bonus, $self->config->{MACHINEGUN_WIN}))
        {
            $defender->mod_life(-1 * $self->config->{MACHINEGUN_DAMAGE});   
            if($defender->attack && $defender->attack eq 'SWORD')
            {
                $defender->mod_gauge('sword', -1 * $self->config->{MACHINEGUN_SWORD_GAUGE_DAMAGE});
            }
            $self->event($attacker->name . " hits with machine gun " .  $defender->name, { $attacker->name => 0, $defender->name => 1});
        }
        else
        {
            $self->event($attacker->name . " missed " . $defender->name . " with machine gun", { $attacker->name => 0, $defender->name => 0});
        }
        $self->sighting_matrix->force_sighting($attacker, $defender, 1);
        $attacker->attack_limit($attacker->attack_limit - 1);
        if($attacker->attack_limit == 0)
        {
            $self->event($attacker->name . " ended machine gun shots", [ $attacker->name ]);
            $attacker->stop_attack();
        }
        $self->collect_dead();
    }
    elsif($attack eq 'RIFLE')
    {
        if($attacker->energy < $self->config->{RIFLE_ENERGY})
        {
            $self->event($attacker->name . ": not enough energy for rifle", [$attacker->name], [$attacker->name]);
            return;
        }
        my $distance = $attacker->position->distance($defender->position);
        my $bonus = 3 - ceil((3 * $distance) / $self->config->{RIFLE_MAX_DISTANCE});
        $bonus += $self->config->{RIFLE_LANDED_BONUS} if($attacker->is_status('landed'));
        if($self->hitting("rifle hit", $bonus, $self->config->{RIFLE_WIN}))
        {
            $defender->mod_life(-1 * $self->config->{RIFLE_DAMAGE});   
            if($defender->attack && $defender->attack eq 'SWORD')
            {
                $defender->mod_gauge('sword', -1 * $self->config->{RIFLE_SWORD_GAUGE_DAMAGE});
            }
            $defender->mod_inertia($self->config->{INERTIA_RIFLE_SHOT});
            $self->event($attacker->name . " hits with rifle " .  $defender->name, [ $attacker->name, $defender->name ], [$attacker->name]);
        }
        else
        {
            $self->event($attacker->name . " missed " . $defender->name . " with rifle", [$attacker->name], [$attacker->name]);
        }
        $self->sighting_matrix->force_sighting($attacker, $defender, 1);
        $attacker->attack_limit(0); #Avoid a new rifle order is misinterpreted as resume
        $attacker->add_energy(-1 * $self->config->{RIFLE_ENERGY});
        $attacker->delete_gauge('rifle');
        $self->collect_dead();
    }
}

sub hitting
{
    my $self = shift;
    my $label = shift;
    my $bonus = shift;
    my $threshold = shift;
    if($self->config->{NO_HITTING_LUCK})
    {
        return 1;
    }
    else
    {
        my $roll = $self->dice(1, 20, $label);
        return $roll + $bonus >= $threshold;
    }
}

sub manage_action
{
    my $self = shift;
    my $action = shift;
    my $mecha = shift;
    if($action eq 'LAND')
    {
        $mecha->stop_action();
        $mecha->add_status('landed');
        $mecha->velocity(0);
        $mecha->position($mecha->destination);
        if($mecha->movement_target->{type} eq 'SAR')
        {
            $mecha->add_status('sensor-array-linked');
        }
        $self->event($mecha->name . " landed on " . ELEMENT_TAGS->{$mecha->movement_target->{type}} . " " . $mecha->movement_target->{name} , [$mecha->name], [$mecha->name]);
    }
    
}

sub collect_dead
{
    my $self = shift;
    my @new_alive = ();
    foreach my $m (@{$self->armies})
    {
        if($m->life <= 0)
        {
            my @out_events = $self->sighting_matrix->remove_from_matrix($m, $self->armies);
            $self->process_sight_events(@out_events);
            push @{$self->cemetery}, $m;
            $self->log($m->name . " removed from game");
        }
        else
        {
            push @new_alive, $m;
        }
    }
    $self->armies(\@new_alive);
    my @out_events = $self->sighting_matrix->calculate(undef, $self->armies);
    $self->process_sight_events(@out_events);
}


sub dice
{
    my $self = shift;
    my $min = shift;
    my $max = shift;
    my $reason = shift;
    my $out;
    my $dice_type;
    if(exists $self->config->{DICE_RESULTS}->{$reason})
    {
        $out = $self->config->{DICE_RESULTS}->{$reason};
        $dice_type = 'Configured';
    }
    elsif(@{$self->dice_results})
    {
        $out = shift @{$self->dice_results};
        $dice_type = 'Loaded';
        $self->log("WARNING! Dice value $out out of range for $reason") if($out < $min || $out > $max);
    }
    else
    {
        my $random_range = $max - $min + 1;
        $out = int(rand($random_range)) + $min;
        $dice_type = 'Regular';
    }
    $self->log("$dice_type dice: $out for $reason") if $reason ne "drift direction";
    return $out;
}

sub event
{
    my $self = shift;
    my $message = shift;
    my $involved_input = shift;
    my $stuck_input = shift;
    return if $self->no_events;

    my $involved = {};
    if(ref $involved_input eq 'ARRAY')
    {
        for(@{$involved_input})
        {
            $involved->{$_} = 1;
        }
    }
    elsif(ref $involved_input eq 'HASH')
    {
        $involved = $involved_input;
    }
    else
    {
        $involved = { $involved_input => 1 };
    }
    $self->log($message . " [" . join(",", map { "$_(" . $involved->{$_} . ")" } keys %{$involved}) . "]");
    $self->log_tracer();


    my $mongo = MongoDB->connect(); 
    my $db = $mongo->get_database('gunpla_' . $self->name);
    for(keys %{$involved})
    {
        my $m_id = $_;
        my $m = $self->get_mecha_by_name($m_id);
        my $cmd_index = $m->cmd_index + 1;
        $db->get_collection('events')->insert_one({ timestamp => $self->timestamp,
                                                    time_index => $self->generated_events,
                                                    message   => $message,
                                                    mecha     => $m->name,
                                                    cmd_index => $cmd_index,
                                                    blocking => $involved->{$m_id} });
        if($involved->{$m_id})
        {
            $m->waiting(1);
            $m->cmd_fetched(0);
        }
        $self->generated_events($self->generated_events + 1) if $message !~ /^IA command issued/;
    }
    for(@{$stuck_input})
    {
        my $m = $self->get_mecha_by_name($_);
        $m->add_status('stuck');
    }
}

sub get_events
{
    my $self = shift;
    my $mecha = shift;
    my $cmd_index = shift;
    return get_game_events($self->name, $mecha, $cmd_index);
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

    my $masterdb = $mongo->get_database('gunpla__core');
    my $now = DateTime->now();
    $now->set_time_zone("Europe/Rome");
    $masterdb->get_collection('games')->replace_one({ name => $self->name}, { name => $self->name, update_time => $now, timestamp => $self->timestamp }, { upsert => 1 } ); 

    foreach my $m (@{$self->armies})
    {
        $db->get_collection('mechas')->insert_one($m->to_mongo);
    }
    foreach my $m (@{$self->cemetery})
    {
        $db->get_collection('mechas')->insert_one($m->to_mongo);
    }
    foreach my $wp (keys %{$self->waypoints})
    {
        my $wp_mongo = {
            id => $wp,
            name => $wp,
            type => 'WP',
            position => $self->waypoints->{$wp}->to_mongo(),
            spawn_point => $self->is_spawn_point($wp)
        };
        $db->get_collection('map')->insert_one($wp_mongo);
    }
    foreach my $hot (@{$self->map_elements})
    {
        my $hotspot = {
            id => $hot->{id},
            type => $hot->{type},
            position => $hot->{position}->to_mongo
        };
        $db->get_collection('map')->insert_one($hotspot);
    }

    my $sighting_matrix = $self->sighting_matrix->to_mongo();;
    $sighting_matrix->{status_element} = 'sighting_matrix';
    $db->get_collection('status')->insert_one($sighting_matrix);
    $db->get_collection('status')->insert_one({status_element => 'timestamp', timestamp => $self->timestamp});
    $db->get_collection('status')->insert_one({status_element => 'log_file', log_file => $self->log_file});
    for(keys %{$self->control})
    {
        $db->get_collection('control')->insert_one({ mecha => $_, player => $self->control->{$_} });
    }


}

sub save_light
{
    my $self = shift;
    $self->save_mecha_status();
    $self->save_sighting_matrix();
}


sub save_mecha_status
{
    my $self = shift;
    my $mongo = MongoDB->connect(); 
    my $db = $mongo->get_database('gunpla_' . $self->name);
    foreach my $m (@{$self->armies})
    {
        $db->get_collection('mechas')->update_one( { 'name' => $m->name }, { '$set' => $m->to_mongo });
    }
}
sub save_sighting_matrix
{
    my $self = shift;
    my $mongo = MongoDB->connect(); 
    my $matrix = $self->sighting_matrix->to_mongo();
    $matrix->{status_element} = 'sighting_matrix';
    my $db = $mongo->get_database('gunpla_' . $self->name);
    $db->get_collection('status')->update_one({ status_element => 'sighting_matrix' }, { '$set' => $matrix });
}


sub load
{
    my $self = shift;
    my $cfg_file = shift;
    $self->load_config($cfg_file);
    my $mongo = MongoDB->connect();
    my $db = $mongo->get_database('gunpla_' . $self->name);
    my @mecha = $db->get_collection('mechas')->find()->all();
    foreach my $m (@mecha)
    {
        $m->{config} = $self->config;
        if($m->{life} > 0)
        {
            push @{$self->armies}, Gunpla::Mecha->from_mongo($m);
        }
        else
        {
            push @{$self->cemetery}, Gunpla::Mecha->from_mongo($m);
        }
    }
    my @map_points = $db->get_collection('map')->find()->all();
    foreach my $mapp (@map_points)
    {
        if($mapp->{type} eq 'WP')
        {
            $self->waypoints->{$mapp->{name}} = Gunpla::Position->from_mongo($mapp->{position});
            if($mapp->{spawn_point})
            {
                $self->spawn_points->{$mapp->{spawn_point}} = $mapp->{name};
            }
        }
        else
        {
            $mapp->{position} = Gunpla::Position->from_mongo($mapp->{position});
            push @{$self->map_elements}, $mapp;
        }
    }
    my ( $sighting_matrix ) = $db->get_collection('status')->find({ status_element => 'sighting_matrix' })->all();
    delete $sighting_matrix->{status_element};
    delete $sighting_matrix->{_id};
    my $sight = Gunpla::Sight->new({config => $self->config});
    $sight->load($sighting_matrix);
    $self->sighting_matrix($sight);
    my ( $timestamp ) = $db->get_collection('status')->find({ status_element => 'timestamp' })->all();
    $self->timestamp($timestamp->{timestamp});
    my ( $log_file ) = $db->get_collection('status')->find({ status_element => 'log_file' })->all();
    $self->log_file($log_file->{log_file});
    
    my @commands = $db->get_collection('available_commands')->find()->all();
    for(@commands)
    {
        $self->configure_command($_);
    }
    my @control = $db->get_collection('control')->find()->all();
    for(@control)
    {
        $self->control->{$_->{mecha}} = $_->{player};
    }
}

sub log
{
    my $self = shift;
    return if ! $self->log_file;
    my $message = shift;
    open(my $fh, '>> ' . $self->log_file);
    my $final_message = "[G:" . $self->name . "] [T" . $self->timestamp . "] " .$message . "\n";
    print {$fh} $final_message;
    close($fh);
}

sub log_tracer
{
    my $self = shift;
    my %positions = ();
    return if ! @{$self->log_tracing};
    $self->log("|----");
    foreach my $mname (@{$self->log_tracing})
    {
        my $m = $self->get_mecha_by_name($mname);
        if($m)
        {
            $self->log("| " . $m->name . " " . $m->position->as_string . " I:" . $m->inertia . " E:" . $m->energy . " L:" . $m->life);
            $positions{$m->name} = $m->position;
        }
    }
    my $distances;
    foreach my $mname (@{$self->log_tracing})
    {
        my $m = $self->get_mecha_by_name($mname);
        if($m)
        {
            foreach my $t (keys %positions)
            {
                if($t ne $m->name)
                {
                    if(! exists $distances->{$t}->{$m->name})
                    {
                        $self->log("| Distance " . $m->name . " - " . $t . ": " . $positions{$t}->distance($m->position));
                        $distances->{$m->name}->{$t} = 1;
                    }
                }
            }
        }
    }
    $self->log("|----");
}

sub log_sighting_matrix
{
    my $self = shift;
    $self->log("### SIGHTING MATRIX");
    $self->log("\n" . $self->sighting_matrix->to_string());
}

1;

