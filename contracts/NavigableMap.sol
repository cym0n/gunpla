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
    mapping(string => Position) public wps;
    mapping(string => Position) public mecha_positions;
    mapping(string => string) public spawn_points;
    
    uint armyCounter = 0;
    

    constructor() public {
        buildWayPoints();
    }

    function buildWayPoints() private {
        wps["Center"] = Position(0, 0, 0);
        wps["Blue"] = Position(-100000, 0, 0);
        wps["Red"] = Position(100000, 0, 0);
        spawn_points["Red"] = "Red";
        spawn_points["Blue"] = "Blue";
        _createMecha("Diver", "Blue");
        _createMecha("Zaku", "Red");
    }

    function _createMecha(string memory _name, string memory _faction) private {
        armies[armyCounter] = Mecha(_name, _faction);
        armyCounter++;
        mecha_positions[_name] = wps[spawn_points[_faction]];
    }
}

