pragma solidity >=0.4.21 <0.7.0;

contract NavigableMap {

    struct Position {
        int256 X;
        int256 Y;
        int256 Z;
    }

    struct Mecha {
        string name;
        string faction;
    }

    mapping(uint   => Mecha) public armies;
    mapping(uint => Position) public mecha_positions;
    mapping(uint => string) public commands;
    mapping(string => Position) public wps;
    mapping(uint => string) public wps_names;
    mapping(string => string) public spawn_points;
    
    uint public armyCounter = 0;
    uint public waypointCounter = 0;
    

    constructor() public {
        _buildWayPoints();
        _buildArmies();
    }

    function _buildWayPoints() private {
        wps["Center"] = Position(0, 0, 0);
        wps_names[0] = "Center";
        wps["Blue"] = Position(-100000, 0, 0);
        wps_names[1] = "Blue";
        wps["Red"] = Position(100000, 0, 0);
        wps_names[2] = "Red";
        waypointCounter = 3;
        spawn_points["Red"] = "Red";
        spawn_points["Blue"] = "Blue";
    }
    
    function _buildArmies() private {
        _createMecha("Diver", "Blue");
        _createMecha("Zaku", "Red");
    }
    

    function _createMecha(string memory _name, string memory _faction) private {
        armies[armyCounter] = Mecha(_name, _faction);
        mecha_positions[armyCounter] = wps[spawn_points[_faction]];
        armyCounter++;
    }

    function addCommand(uint _id, string calldata _command) external {
        commands[_id] = _command;
    }

}

