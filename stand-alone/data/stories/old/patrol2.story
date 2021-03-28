NAME:Patrol2
DESCRIPTION:Same story of Patrol but now enemies are more clever and can ask for support (patrolling diamon is littler, Wing and Leo have the same sight range)
MAP:arena-1.csv
CONFIGURATION:stories.yaml
DICE:1,0
TEMPLATES:v2.csv
COMMANDS
Wing;flywp;WP-blue;;;4
Wing;rifle;MEC-Leo-3;;;
Wing;flymec;MEC-Leo-3;boost;;6
Wing;flymec;MEC-Leo-3;boost;;6
Wing;flymec;MEC-Leo-3;boost;;6
Wing;sword;MEC-Leo-3;;;
Wing;sword;MEC-Leo-3;;;
Wing;flywp;WP-blue;;;4
## KO ### Wing ignores any other enemy. Leo-2 and Leo-4 attack and destory him
# Wing;flywp;WP-blue;;;4
# Wing;flywp;WP-blue;;;4
# Wing;flywp;WP-blue;;;4
# Wing;flywp;WP-blue;;;4
# Wing;flywp;WP-blue;;;4
# Wing;flywp;WP-blue;;;4
# Wing;flywp;WP-blue;;;4
# Wing;flywp;WP-blue;;;4
# Wing;flywp;WP-blue;;;4
# Wing;flywp;WP-blue;;;4
## KO ### Wing attacks Leo-2 but hasn't enough energy to use the sowrd 
# Wing;flymec;MEC-Leo-2;machinegun;MEC-Leo-2;4
# Wing;flymec;MEC-Leo-2;machinegun;MEC-Leo-2;4
# Wing;flymec;MEC-Leo-2;machinegun;MEC-Leo-2;4
# Wing;sword;MEC-Leo-2;;;
######### Wing run away from an enemy shooting the other. 
Wing;away;MEC-Leo-4;machinegun;MEC-Leo-2;4
Wing;away;MEC-Leo-4;machinegun;MEC-Leo-2;4
Wing;away;MEC-Leo-4;machinegun;MEC-Leo-2;4
Wing;away;MEC-Leo-4;machinegun;MEC-Leo-2;4
Wing;away;MEC-Leo-4;machinegun;MEC-Leo-2;4
######### Wing uses the last of the boost to put some space between him and the adversary and charge back with the machinegun (flywp, not flymec!)
Wing;flywp;WP-red;boost;;6
Wing;flywp;WP-blue;machinegun;MEC-Leo-2;4
## KO ### Leo-2 is dead but trying again to run to the goal still lead to a failure
# Wing;flywp;WP-blue;;;4
# Wing;flywp;WP-blue;;;4
# Wing;flywp;WP-blue;;;4
# Wing;flywp;WP-blue;;;4
# Wing;flywp;WP-blue;;;4
# Wing;flywp;WP-blue;;;4
## KO ### Go close and then try to run away. Places some hits but when the Leo-4 accelerates for sword attack it's the end
# Wing;flywp;WP-blue;;;4
# Wing;flymec;MEC-Leo-4;machinegun;MEC-Leo-4;4
# Wing;flymec;MEC-Leo-4;machinegun;MEC-Leo-4;4
# Wing;away;MEC-Leo-4;;;4
# Wing;away;MEC-Leo-4;;;4
#Wing;flywp;WP-red;;;4
Wing;flywp;WP-blue;;;4
#Wing;away;MEC-Leo-4;;;4
#Wing;flywp;WP-blue;;;4
#Wing;flywp;WP-blue;;;4
#Wing;flywp;WP-blue;;;4
#Wing;flywp;WP-blue;;;4
#Wing;flywp;WP-blue;;;4
TRACING
Wing;0;Wing,Leo-3,Leo-4
Wing;7;Wing,Leo-2,Leo-4
Wing;15;Wing,Leo-4,Leo-1
