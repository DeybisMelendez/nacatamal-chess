local Board = require "board"
local Eval = require "evaluation"
Board:parseFEN("8/3pkp2/8/4PP2/4K3/8/8/8 w - - 0 1")

Eval:eval(Board,1,true)