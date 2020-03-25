pragma solidity >=0.4.21 <0.7.0;

contract Positions {

    uint constant X = 1;
    uint constant Y = 2;
    uint constant Z = 3;

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
            pos.Z == value;
        }
        return pos;
    }

    function _calculateVector(Position memory _a, Position memory _b) private pure returns(Position[] memory) {
        Position memory out = Position(0, 0, 0);
        Position memory cursor = Position(0, 0, 0);
        
        for(uint8 i=1; i<= 3; i++){
            int256 value = _getCoo(_a, i) - _getCoo(_b, i);
            if(value < 0)
            {
                value = value * -1;
                _setCoo(cursor, i, -1);
            }
            else
            {
                _setCoo(cursor, i, 1);
            }
            _setCoo(out, i, value);
        }
        Position[] memory outdata;
        outdata[0] = out;
        outdata[1] = cursor;
        return outdata;
    }
    





}

