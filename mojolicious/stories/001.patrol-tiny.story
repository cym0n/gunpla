NAME:Patroltiny
DESCRIPTION:Just an enemy patrolling on a small area
MAP:patrol-tiny.csv
CONFIGURATION:stories.yaml
DICE:1,0
COMMANDS
### Mecha launch itself against the enemy using the sword command. Firing machingun to the target is enough to destroy it
Wing;flywp;WP-blue;;;4
Wing;rifle;MEC-Leo-1;;;
Wing;sword;MEC-Leo-1;machinegun;MEC-Leo-1;6
Wing;sword;MEC-Leo-1;machinegun;MEC-Leo-1;6
Wing;sword;MEC-Leo-1;machinegun;MEC-Leo-1;6
Wing;flywp;WP-blue;;;4
#
### Mecha just uses flymec command so it can reach just the area nearby the target. To keep shooting machingun at it
# Wing;flywp;WP-blue;;;4
# Wing;rifle;MEC-Leo-1;;;
# Wing;flymec;MEC-Leo-1;machinegun;MEC-Leo-1;6
# Wing;flymec;MEC-Leo-1;machinegun;MEC-Leo-1;6
# Wing;away;MEC-Leo-1;machinegun;MEC-Leo-1;6
# Wing;away;MEC-Leo-1;machinegun;MEC-Leo-1;6
# Wing;flywp;WP-blue;;;4
TRACING
Wing;0;Wing,Leo-1
TARGETS
wolf;CONQ WP-blue
