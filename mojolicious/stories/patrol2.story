NAME:Patrol2
DESCRIPTION:Same story of Patrol but now enemies are more clever and can ask for support
MAP:arena-1.csv
CONFIGURATION:stories.yaml
DICE:1,0
COMMANDS
Wing;flywp;WP-blue;;;4
Wing;rifle;MEC-Leo-3;;;
Wing;flymec;MEC-Leo-3;boost;;6
Wing;flymec;MEC-Leo-3;boost;;6
Wing;flymec;MEC-Leo-3;boost;;6
Wing;sword;MEC-Leo-3;;;
Wing;sword;MEC-Leo-3;;;
#If Wing ignores Leo-4 dies
#Wing;flywp;WP-blue;;;4
#Wing;flywp;WP-blue;;;4
#Wing;flywp;WP-blue;;;4
#Wing;flywp;WP-blue;;;4
TRACING
Wing;0;Wing,Leo-3
Wing;7;Wing,Leo-1,Leo-2,Leo-4
