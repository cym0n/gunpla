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
        for(uint8 i=0; i< armyCounter; i++){
            if(armies[i].steps > 0)
            {
                _moveMecha(i);
            }
            else
            {
                if(! _comparePositions(mecha_destinations[i], mecha_positions[i]))
                {
                    _setCourseMecha(i);
                    _moveMecha(i);
                }
            }
        }
    }

    function _setCourseMecha(uint i) private
    {
        int256[2] memory course_data = _calculateCourse(mecha_positions[i], mecha_destinations[i]);
        armies[i].course = course_data[1];
        armies[i].steps = course_data[0];   
    }


    function _moveMecha(uint i) private
    {
        assert(armies[i].steps > 0);
        if(armies[i].course == X_UP)
        {
            mecha_positions[i].X += 1;
        }
        else if(armies[i].course == X_DOWN)
        {
            mecha_positions[i].X -= 1;
        }
        else if(armies[i].course == Y_UP)
        {
            mecha_positions[i].Y += 1;
        }
        else if(armies[i].course == Y_DOWN)
        {
            mecha_positions[i].Y -= 1;
        }
        else if(armies[i].course == Z_UP)
        {
            mecha_positions[i].Z += 1;
        }
        else if(armies[i].course == Z_DOWN)
        {
            mecha_positions[i].Z -= 1;
        }
        armies[i].steps -= 1;
    }

}

