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

    function _calculateVector(Position memory _a, Position memory _b) private pure returns(Position[2] memory) {
        Position memory steps = Position(0, 0, 0);
        Position memory cursor = Position(0, 0, 0);
        
        for(uint8 i=1; i<= 3; i++){
            int256 value;
            value = _getCoo(_a, i) - _getCoo(_b, i);
            if(value < 0)
            {
                value = value * -1;
            }
            if(_getCoo(_a, i) < _getCoo(_b, i))
            {
                cursor = _setCoo(cursor, i, 1);
            }
            else
            {
                cursor = _setCoo(cursor, i, -1);
            }
            steps = _setCoo(steps, i, value);
        }
        Position[2] memory outdata;
        outdata[0] = steps;
        outdata[1] = cursor;
        return outdata;
    }

    function _calculateCourse(Position memory _a, Position memory _b) internal pure returns(int256[2] memory) {
        Position[2] memory vector = _calculateVector(_a, _b);
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
            if(i != max && _getCoo(vector[0], i) > 0)
            {
                if(max_gap < max_value / _getCoo(vector[0], i))
                {
                    max_gap = max_value / _getCoo(vector[0], i);
                }
            }
        }
        if(max_gap == 0)
        {
            max_gap = 10; //Arbitrary
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

    function _calculateDistance(Position memory _a, Position memory _b) internal pure returns(int256) {
        Position[2] memory vector = _calculateVector(_a, _b);
        int256 x = _getCoo(vector[0], 1);
        int256 y = _getCoo(vector[0], 2);
        int256 z = _getCoo(vector[0], 3);
        int256 squaredout = (x * x) + (y * y) + (z * z);
        return sqrt(squaredout);
    }

    //Babylonian method square root
    function sqrt(int256 x) private pure returns (int256 y) {
        int256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

