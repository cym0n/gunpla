NAME:Patrol
DESCRIPTION:Wing approaches the surveillance perimeter and encounter Leo-3. Leo-3 fly toward him with machingun. Wing first shoots with the RIFLE then turn on the BOOST to short the distance with the enemy and slash with the blade. Having the boost as bonus he wins the sword fight. One more hit finishes Leo-3
MAP:arena-0.csv
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
Wing;flywp;WP-blue;;;4
Wing;flywp;WP-blue;;;4
Wing;flywp;WP-blue;;;4
Wing;flywp;WP-blue;;;4
TRACING
Wing;0;Wing,Leo-3
Wing;7;Wing,Leo-1,Leo-2,Leo-4
