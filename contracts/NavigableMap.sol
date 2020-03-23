pragma solidity >=0.4.21 <0.7.0;
import "ext/BytesLib.sol";

contract NavigableMap {

    using BytesLib for bytes;

    struct Position {
        int256 X;
        int256 Y;
        int256 Z;
    }

    struct Mecha {
        string name;
        string faction;
        bool waiting;
    }

    mapping(uint   => Mecha) public armies;
    mapping(uint => Position) public mecha_positions;
    mapping(uint => string) public commands;
    mapping(uint => Position) public mecha_destinations;
    
    mapping(string => Position) public wps;
    mapping(uint => string) public wps_names;
    mapping(string => string) public spawn_points;
    
    uint public armyCounter = 0;
    uint public waypointCounter = 0;

    event CommandReceived(uint mecha);

    constructor() public {
        _buildWayPoints();
        _buildArmies();
    }

    function _buildWayPoints() private {
        _addWayPoint("Center", Position(0, 0, 0));
        _addWayPoint("Blue", Position(-100000, 0, 0));
        _addWayPoint("Red", Position(100000, 0, 0));

        spawn_points["Red"] = "Red";
        spawn_points["Blue"] = "Blue";
    }
    
    function _buildArmies() private {
        _createMecha("Diver", "Blue");
        _createMecha("Zaku", "Red");
    }
    

    function _createMecha(string memory _name, string memory _faction) private {
        armies[armyCounter] = Mecha(_name, _faction, true);
        mecha_positions[armyCounter] = wps[spawn_points[_faction]];
        armyCounter++;
    }

    function _addWayPoint(string memory _name, Position memory _pos) private {
        wps[_name] = _pos;
        wps_names[waypointCounter] = _name;
        waypointCounter++;
    }

    function addCommand(uint _id, string calldata _command, string calldata _target) external {
        bytes memory result = bytes(_command).concat(bytes(" "));
        result = result.concat(bytes(_target));
        commands[_id] = string(result); 
        if(bytes(_command).equal(bytes("FLY TO WAYPOINT")))
        {
            mecha_destinations[_id] = wps[_target];
        }
        emit CommandReceived(_id);
        //if(_actionReady())
        //{
        //    _doAction();
        //}
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

//    function _doAction() private
//    {
//        for(uint8 i=0; i<= armyCounter; i++){
//        } 
//    }

    function _comparePositions(Position memory _a, Position memory _b) private pure returns(bool) {
        return _a.X == _b.X && _a.Y == _b.Y && _a.Z == _b.Z;
    }


}

