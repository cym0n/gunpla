pragma solidity >=0.4.21 <0.7.0;
import "contracts/Positions.sol";

contract NavigableMap is Positions {

    struct Mecha {
        string name;
        string faction;
        bool waiting;
        int256 course;
        int256 steps;
    }

    mapping(uint   => Mecha) public armies;
    mapping(uint => Position) public mecha_positions;
    mapping(uint => string) public commands;
    mapping(uint => Position) public mecha_destinations;
    
    mapping(string => Position) public wps;
    mapping(uint => string) public wps_names;
    mapping(string => string) public spawn_points;

    mapping(string => uint) public available_commands;

    
    uint public armyCounter = 0;
    uint public waypointCounter = 0;

    event CommandReceived(uint mecha);
    event BlockingEvent(string description);
    event Distance(int256 distance);


    constructor() public {
        _buildWayPoints();
        _buildArmies();
        
        available_commands["FLY TO WAYPOINT"] = 1;
    }

    function _buildWayPoints() private {
        _addWayPoint("Center", Position(0, 0, 0));
        _addWayPoint("Blue", Position(-500000, 0, 0));
        _addWayPoint("Red", Position(500000, 0, 0));

        spawn_points["Red"] = "Red";
        spawn_points["Blue"] = "Blue";
    }
    
    function _buildArmies() private {
        _createMecha("Diver", "Blue");
        _createMecha("Zaku", "Red");
    }
    

    function _createMecha(string memory _name, string memory _faction) private {
        armies[armyCounter] = Mecha(_name, _faction, true, 0, 0);
        mecha_positions[armyCounter] = wps[spawn_points[_faction]];
        mecha_destinations[armyCounter] = wps[spawn_points[_faction]];
        armyCounter++;
    }

    function _addWayPoint(string memory _name, Position memory _pos) private {
        wps[_name] = _pos;
        wps_names[waypointCounter] = _name;
        waypointCounter++;
    }

    function addCommand(uint _id, string calldata _command, string calldata _target) external {
        if(available_commands[_command] == 1)
        {
            mecha_destinations[_id] = wps[_target];
            armies[_id].waiting = false;
            emit CommandReceived(_id);
            commands[_id] = _command; 
        }
        if(_actionReady())
        {
            _doAction();
        }
    }

    function _actionReady() private view returns(bool)
    {
        for(uint8 i=0; i<= armyCounter; i++){
            if(armies[i].waiting)
            {
                return false;
            }
        }
        return true;
    }

    function _doAction() private
    {
        //mapping(uint => Position) memory temp_mecha_positions;
        //mapping(uint => int256) memory steps;
        //mapping(uint => int256) memory course;
        
        Position[2] memory temp_mecha_positions;
        int256[2] memory steps;
        int256[2] memory course;

        for(uint8 i=0; i< armyCounter; i++){
            temp_mecha_positions[i] = mecha_positions[i];
        }

        uint counter = 0;
        while(_actionReady() && counter < 100)
        {
            for(uint8 i=0; i< armyCounter; i++) {
                if(! _comparePositions(mecha_destinations[i], temp_mecha_positions[i]))
                {
                    if(steps[i] == 0)
                    {
                        int256[2] memory course_data = _calculateCourse(temp_mecha_positions[i], mecha_destinations[i]);
                        steps[i] = course_data[0];
                        course[i] = course_data[1];
                    }  
                    Position memory new_position = _moveMecha(temp_mecha_positions[i], course[i]);
                    temp_mecha_positions[i] = new_position;
                    steps[i] = steps[i] - 1;
                }
                else
                {
                    emit BlockingEvent("Mecha arrived");
                    armies[i].waiting = true;
                }
            }
            int256 distance = _calculateDistance(temp_mecha_positions[0], temp_mecha_positions[1]);
            if(distance < 999900)
            {
                armies[0].waiting = true;
                armies[1].waiting = true;
                emit BlockingEvent("Enemy sighted");
            }
            else
            {
                //emit Distance(distance);
            }
            counter++;
        }
        for(uint8 i=0; i< armyCounter; i++){
            mecha_positions[i] = temp_mecha_positions[i];
        }
        
    }

    function _moveMecha(Position memory pos_in, int256 course) private pure returns(Position memory)
    {
        if(course == X_UP)
        {
            pos_in.X += 1;
        }
        else if(course == X_DOWN)
        {
            pos_in.X -= 1;
        }
        else if(course == Y_UP)
        {
            pos_in.Y += 1;
        }
        else if(course == Y_DOWN)
        { 
            pos_in.Y -= 1;
        }
        else if(course == Z_UP)
        {
            pos_in.Z += 1;
        }
        else if(course == Z_DOWN)
        {
            pos_in.Z -= 1;
        }
        return pos_in;
    }

}

