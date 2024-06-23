local Board = require "board.Board"

--Board:parseFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
Board:parseFEN("8/2p5/3p4/KP5r/1R2Pp1k/8/6P1/8 b - e3 0 1")

Board:print()
print(Board:perft(1))