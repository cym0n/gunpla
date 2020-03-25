pragma solidity >=0.4.21 <0.7.0;
import "contracts/Positions.sol";
import "ext/BytesLib.sol";

contract NavigableMap is Positions {

    using BytesLib for bytes;

    uint constant X_UP = 6;
    uint constant X_DOWN = 11;
    uint constant Y_UP = 7;
    uint constant Y_DOWN = 12;
    uint constant Z_UP = 8;
    uint constant Z_DOWN = 13;

    struct Mecha {
        string name;
        string faction;
        bool waiting;
        uint course;
        uint steps;
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
        armies[armyCounter] = Mecha(_name, _faction, true, 0, 0);
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
        if(_actionReady())
        {
            //_doAction();
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

/*    function _doAction() private
    {
        for(uint8 i=0; i<= armyCounter; i++){
            if(armies[i].steps > 0)
            {
                _moveMecha(i);
            }
            else
            {
            }
            if(mecha_destinations[i])
            {
                if(! _comparePosition(mecha_destinations[i], mecha_positions[i])
            }
        } 
    }

    function _setCourseMecha(uint i) private
    {
        
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

    function _comparePositions(Position memory _a, Position memory _b) private pure returns(bool) {
        return _a.X == _b.X && _a.Y == _b.Y && _a.Z == _b.Z;
    }

    function _calculateVector(Position memory _a, Position memory _b) private pure returns(Position[] memory) {
        Position memory out;
        Position memory cursor;
        out.X = _a.X - _b.X;
        out.Y = _a.Y - _b.Y;
        out.Z = _a.Z - _b.Z;
        if(out.X < 0)
        {
            out.X = out.X * -1;
            cursor.X = -1;
        }
        else
        {
            cursor.X = 1;
        }
        if(out.Y < 0)
        {
            out.Y = out.Y * -1;
            cursor.Y = -1;
        }
        else
        {
            cursor.Y = 1;
        }
        if(out.Z < 0)
        {
            out.Z = out.Z * -1;
            cursor.Z = -1;
        }
        else
        {
            cursor.Z = 1;
        }
        Position[] memory outdata;
        outdata[0] = out;
        outdata[1] = cursor;
        return outdata;
    }

    function _calculateCourse(Position memory _a, Position memory _b) private pure returns(uint) {
        Position[] memory calc = _calculateVector(_a, _b);

        //Longest direction
        if(calc[0].X >= calc[0].Y)
        {
            if(calc[0].X >= calc[0].Z)
            {
                int256 rap1 = calc[0].X / calc[0].Z;
                int256 rap2 = calc[0].X / calc[0].Y;
                
                



                return X;
            }
            else
            {
                return Z;
            }
        }
        else
        {
            if(calc[0].Y >= calc[0].Z)
            {
                return Y;
            }
            else
            {
                return Z;
            }
        }
        


    }
    function _projectionProportion(Position memory _a) private pure returns(uint) {
        uint longest = _longestProjection(_a);
        if(longest == X)
        {
            uint first = int(abs(a.X) / abs(_a.Y));
            uint second = int(abs(a.X) / abs(_a.Z));
        }


    } */
}

