pragma solidity >=0.4.21 <0.7.0;

contract Positions {

    uint constant X = 1;
    uint constant Y = 2;
    uint constant Z = 3;

 
    int256 constant X_UP = 6;
    int256 constant X_DOWN = 11;
    int256 constant Y_UP = 7;
    int256 constant Y_DOWN = 12;
    int256 constant Z_UP = 8;
    int256 constant Z_DOWN = 13;


    struct Position {
        int256 X;
        int256 Y;
        int256 Z;
    }

    event SettingCoo(uint coo, int256 value);

    function _getCoo(Position memory pos, uint coo) private pure returns(int256)
    {
        if(coo == X)
        {
            return pos.X;
        }
        else if(coo == Y)
        {
            return pos.Y;
        }
        else if(coo == Z)
        {
            return pos.Z;
        }
    }

    function _setCoo(Position memory pos, uint coo, int256 value) private pure returns(Position memory)
    {
        if(coo == X)
        {
            pos.X = value;
        }
        else if(coo == Y)
        {
            pos.Y = value;
        }
        else if(coo == Z)
        {
            pos.Z = value;
        }
        return pos;
    }

    function _comparePositions(Position memory _a, Position memory _b) internal pure returns(bool) {
        return _a.X == _b.X && _a.Y == _b.Y && _a.Z == _b.Z;
    }

    function _calculateVector(Position memory _a, Position memory _b) private returns(Position[2] memory) {
        Position memory steps = Position(0, 0, 0);
        Position memory cursor = Position(0, 0, 0);
        
        for(uint8 i=1; i<= 3; i++){
            int256 value;
            if( _getCoo(_a, i) == _getCoo(_b, i))
            {
                value = 0;
            }
            else
            {
                value = _getCoo(_a, i) - _getCoo(_b, i);
            }
            if(value < 0)
            {
                value = value * -1;
                cursor = _setCoo(cursor, i, -1);
            }
            else
            {
                cursor = _setCoo(cursor, i, 1);
            }
            emit SettingCoo(i, value);
            //if(value == 0)
            //{
            //    value = 1;
            //}
            if(value > 0)
            {
                steps = _setCoo(steps, i, value);
            }
        }
        Position[2] memory outdata;
        outdata[0] = steps;
        outdata[1] = cursor;
        return outdata;
    }

    function _calculateCourse(Position memory _a, Position memory _b) internal returns(int256[2] memory) {
        Position[2] memory vector = _calculateVector(_a, _b);
        //Position[2] memory vector; 
        //vector[0] = Position(5, 3, 2);
        //vector[1] = Position(1, 1, 1);
        uint8 max = 0;
        int256 max_value = 0;
        for(uint8 i=1; i<= 3; i++){
            if(_getCoo(vector[0], i) > max_value)
            {
                max = i;
                max_value = _getCoo(vector[0], i);
            }
        }
        int256 max_gap = 0;
        for(uint8 i=1; i<= 3; i++){
            if(i != max)
            {
                if(max_gap < max_value / _getCoo(vector[0], i))
                {
                    max_gap = max_value / _getCoo(vector[0], i);
                }
            }
        }
        int256[2] memory out;
        out[0] = max_gap;
        if(_getCoo(vector[1], max) == 1)
        {
            out[1] = 5 + max;
        }
        else if(_getCoo(vector[1], max) == -1)
        {
            out[1] = (5 * 2) + max;
        }
        return out;
    }
}

