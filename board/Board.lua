local Board = {
    -- Constantes de Board
    WHITE_TO_MOVE = true,
    BLACK_TO_MOVE = false,
    -- Piezas
    EMPTY = 0,
    W_PAWN = 1,
    W_KNIGHT = 2,
    W_BISHOP = 3,
    W_ROOK = 4,
    W_QUEEN = 5,
    W_KING = 6,
    B_PAWN = -1,
    B_KNIGHT = -2,
    B_BISHOP = -3,
    B_ROOK = -4,
    B_QUEEN = -5,
    B_KING = -6,
    OUT = 7,
    -- Filas y Columnas
    FILE_A = 3,
    FILE_B = 4,
    FILE_C = 5,
    FILE_D = 6,
    FILE_E = 7,
    FILE_F = 8,
    FILE_G = 9,
    FILE_H = 10,
    RANK_1 = 3,
    RANK_2 = 4,
    RANK_3 = 5,
    RANK_4 = 6,
    RANK_5 = 7,
    RANK_6 = 8,
    RANK_7 = 9,
    RANK_8 = 10,
    -- Patrones
    KNIGHT_MOVES = {
        {2, 1}, {2, -1}, {-2, 1}, {-2, -1},
        {1, 2}, {1, -2}, {-1, 2}, {-1, -2}
    },
    KING_MOVES = {
        {0, 1}, {0, -1}, {1, 0}, {-1, 0},
        {1, 1}, {1, -1}, {-1, 1}, {-1, -1}
    },
    -- Flags
    FLAG_QUIET_MOVE = 0,
    FLAG_DOUBLE_PAWN_PUSH = 1,
    FLAG_KING_CASTLE = 2,
    FLAG_QUEEN_CASTLE = 3,
    FLAG_CAPTURE = 4,
    FLAG_EP_CAPTURE = 5,
    FLAG_KNIGHT_PROMOTION = 6,
    FLAG_BISHOP_PROMOTION = 7,
    FLAG_ROOK_PROMOTION = 8,
    FLAG_QUEEN_PROMOTION = 9,
    FLAG_KNIGHT_PROMOTION_CAPTURE = 10,
    FLAG_BISHOP_PROMOTION_CAPTURE = 11,
    FLAG_ROOK_PROMOTION_CAPTURE = 12,
    FLAG_QUEEN_PROMOTION_CAPTURE = 13,
    -- Atributos
    mailbox = {},
    sideToMove = true,
    castlingRights = "-",
    enPassantSquare = {0,0},
    halfMoveClock = 0,
    fullMoveNumber = 0
}

Board.PROMOTION_FLAGS = {Board.FLAG_QUEEN_PROMOTION, Board.FLAG_ROOK_PROMOTION, Board.FLAG_BISHOP_PROMOTION, Board.FLAG_KNIGHT_PROMOTION}
Board.CAPTURE_PROMOTION_FLAGS = {Board.FLAG_QUEEN_PROMOTION_CAPTURE, Board.FLAG_ROOK_PROMOTION_CAPTURE, Board.FLAG_BISHOP_PROMOTION_CAPTURE, Board.FLAG_KNIGHT_PROMOTION_CAPTURE}

function Board:initializeMailbox()
    for rank = 1, 12 do
        self.mailbox[rank] = {}
        for file = 1, 12 do
            if rank == 1 or rank == 2 or rank == 11 or rank == 12 or
               file == 1 or file == 2 or file == 11 or file == 12 then
                self.mailbox[rank][file] = self.OUT
            else
                self.mailbox[rank][file] = self.EMPTY
            end
        end
    end
end

function Board:convertSquareToCoords(square)
    if square ~= "-" then
        local file = square:byte() - string.byte("a") + self.FILE_A
        local rank = tonumber(square:sub(2, 2)) + self.RANK_1 - 1
        return {rank, file}
    end
    return {0,0}
end

function Board:print()
    local PIECE_SYMBOLS = {
        [self.W_PAWN] = "P",
        [self.W_KNIGHT] = "N",
        [self.W_BISHOP] = "B",
        [self.W_ROOK] = "R",
        [self.W_QUEEN] = "Q",
        [self.W_KING] = "K",
        [self.B_PAWN] = "p",
        [self.B_KNIGHT] = "n",
        [self.B_BISHOP] = "b",
        [self.B_ROOK] = "r",
        [self.B_QUEEN] = "q",
        [self.B_KING] = "k",
        [self.EMPTY] = "."  -- Assuming you have a value for empty squares
    }

    for rank = self.RANK_8, self.RANK_1, -1 do
        for file = self.FILE_A, self.FILE_H do
            local piece = self.mailbox[rank][file]
            io.write(PIECE_SYMBOLS[piece] or ".", " ")  -- Print the piece symbol or "." for empty squares
        end
        io.write("\n")
    end
end

function Board:parseFEN(fen)
    local PIECES = {
        ["P"] = self.W_PAWN,  -- White Pawn
        ["N"] = self.W_KNIGHT,  -- White Knight
        ["B"] = self.W_BISHOP,  -- White Bishop
        ["R"] = self.W_ROOK,  -- White Rook
        ["Q"] = self.W_QUEEN,  -- White Queen
        ["K"] = self.W_KING,  -- White King
        ["p"] = self.B_PAWN, -- Black Pawn
        ["n"] = self.B_KNIGHT, -- Black Knight
        ["b"] = self.B_BISHOP, -- Black Bishop
        ["r"] = self.B_ROOK, -- Black Rook
        ["q"] = self.B_QUEEN, -- Black Queen
        ["k"] = self.B_KING  -- Black King
    }
    local rank = self.RANK_8  -- Adjust file to start from 8
    local file = self.FILE_A  -- Adjust rank to start from A

    local parts = {}
    for part in string.gmatch(fen, "[^%s]+") do
        table.insert(parts, part)
    end
    local piecePlacement = parts[1]
    self.sideToMove = parts[2] == "w" and true or false
    self.castlingRights = parts[3]
    self.enPassantSquare = self:convertSquareToCoords(parts[4])
    self.halfMoveClock = parts[5] == nil and 0 or tonumber(parts[5])
    self.fullMoveNumber = parts[6] == nil and 0 or tonumber(parts[6])
    for i = 1, #piecePlacement do
        local char = piecePlacement:sub(i, i)
        if char == "/" then
            rank = rank - 1  -- Move to the next rank down
            file = self.FILE_A  -- Reset file to A
        elseif char:match("%d") then
            file = file + tonumber(char)  -- Skip the specified number of files
        elseif PIECES[char] then
            self.mailbox[rank][file] = PIECES[char]
            file = file + 1
        end
    end
end

function Board:isInsideBoard(rank, file)
    return self.mailbox[rank][file] ~= self.OUT
    --return file >= self.FILE_A and file <= self.FILE_H and rank >= self.RANK_1 and rank <= self.RANK_8
end

function Board:isEmpty(rank, file)
    return self.mailbox[rank][file] == self.EMPTY
end

function Board:isEnemyPiece(rank, file, side)
    local piece = self.mailbox[rank][file]
    return (side == self.WHITE_TO_MOVE and piece < self.EMPTY) or (side == self.BLACK_TO_MOVE and piece > self.EMPTY)
end

function Board:generatePawnMoves(rank, file, side, moves)
    local direction = side == self.WHITE_TO_MOVE and 1 or -1
    local startRank = side == self.WHITE_TO_MOVE and self.RANK_2 or self.RANK_7
    local promotionRank = side == self.WHITE_TO_MOVE and self.RANK_8 or self.RANK_1
    -- Movimiento hacia adelante
    if self:isEmpty(rank + direction,file) then
        
        if rank + direction == promotionRank then
            for _, flag in ipairs(self.PROMOTION_FLAGS) do
                table.insert(moves, {rank, file, rank + direction, file, flag})
            end
        else
            table.insert(moves, {rank, file, rank + direction, file, self.FLAG_QUIET_MOVE})
            -- Movimiento inicial doble
            if rank == startRank and self:isEmpty(rank + 2 * direction, file) then
                table.insert(moves, {rank, file, rank + 2 * direction, file, self.FLAG_DOUBLE_PAWN_PUSH})
            end
        end
    end

    -- Captura en diagonal izquierda
    if self:isInsideBoard(rank + direction, file - 1) and self:isEnemyPiece(rank + direction, file - 1, side) then
        if rank + direction == promotionRank then
            for _, flag in ipairs(self.CAPTURE_PROMOTION_FLAGS) do
                table.insert(moves, {rank, file, rank + direction, file - 1 , flag})
            end
        else
            table.insert(moves, {rank, file, rank + direction, file - 1, self.FLAG_CAPTURE})
        end
    end

    -- Captura en diagonal derecha
    if self:isInsideBoard(rank + 1, file + direction) and self:isEnemyPiece(rank + 1, file + direction, side) then
        if rank + direction == promotionRank then
            for _, flag in ipairs(self.CAPTURE_PROMOTION_FLAGS) do
                table.insert(moves, {rank, file, rank + direction, file + 1, flag})
            end
        else
            table.insert(moves, {rank, file, rank + direction, file + 1, self.FLAG_CAPTURE})
        end
    end

    -- Captura al paso (en passant)
    if self.enPassantSquare[1] ~= 0 then
        local epRank, epFile = unpack(self.enPassantSquare)
        if file == (side == self.WHITE_TO_MOVE and self.RANK_5 or self.RANK_4) and
            (file - 1 == epFile or file + 1 == epFile) and epRank == rank + direction then
            table.insert(moves, {rank, file, epRank, epFile, self.FLAG_EP_CAPTURE})
        end
    end

end

function Board:generateKnightMoves(rank, file, side, moves)

    for _, offset in ipairs(self.KNIGHT_MOVES) do
        local newRank = rank + offset[1]
        local newFile = file + offset[2]
        if self:isInsideBoard(newRank, newFile) then
            if self:isEmpty(newRank, newFile) then
                table.insert(moves, {rank, file, newRank, newFile, self.FLAG_QUIET_MOVE})
            elseif self:isEnemyPiece(newRank, newFile, side) then
                table.insert(moves, {rank, file, newRank, newFile, self.FLAG_CAPTURE})
            end
        end
    end
end

function Board:generateBishopMoves(rank, file, side, moves)
    -- Movimientos diagonales (noreste, noroeste, sureste, suroeste)
    for rankDirection = -1, 1, 2 do
        for fileDirection = -1, 1, 2 do
            local newRank = rank + rankDirection
            local newFile = file + fileDirection
            while self:isInsideBoard(newRank, newFile) do
                if self:isEmpty(newRank, newFile) then
                    table.insert(moves, {rank, file, newRank, newFile, self.FLAG_QUIET_MOVE})
                elseif self:isEnemyPiece(newRank, newFile, side) then
                    table.insert(moves, {rank, file, newRank, newFile, self.FLAG_CAPTURE})
                    break
                else
                    break
                end
                newRank = newRank + rankDirection
                newFile = newFile + fileDirection
            end
        end
    end
end

function Board:generateRookMoves(rank, file, side,moves)
    -- Movimientos verticales (arriba y abajo)
    for direction = -1, 1, 2 do
        local newFile = file + direction
        while self:isInsideBoard(rank, newFile) do
            if self:isEmpty(rank, newFile) then
                table.insert(moves, {rank, file, rank, newFile, self.FLAG_QUIET_MOVE})
            elseif self:isEnemyPiece(rank, newFile, side) then
                table.insert(moves, {rank, file, rank, newFile, self.FLAG_CAPTURE})
                break
            else
                break
            end
            newFile = newFile + direction
        end
    end

    -- Movimientos horizontales (izquierda y derecha)
    for direction = -1, 1, 2 do
        local newRank = rank + direction
        while self:isInsideBoard(newRank, file) do
            if self:isEmpty(newRank, file) then
                table.insert(moves, {rank, file, newRank, file, self.FLAG_QUIET_MOVE})
            elseif self:isEnemyPiece(newRank, file, side) then
                table.insert(moves, {rank, file, newRank, file, self.FLAG_CAPTURE})
                break
            else
                break
            end
            newRank = newRank + direction
        end
    end
end

function Board:generateQueenMoves(rank, file, side, moves)
    -- Generar movimientos de torre
    self:generateRookMoves(rank, file, side,moves)

    -- Generar movimientos de alfil
    self:generateBishopMoves(rank, file, side,moves)
end

function Board:generateKingMoves(rank, file, side, moves)

    for _, dir in ipairs(self.KING_MOVES) do
        local newRank = rank + dir[1]
        local newFile = file + dir[2]

        if self:isInsideBoard(newRank, newFile) then
            if self:isEmpty(newRank, newFile) then
                table.insert(moves, {rank, file, newRank, newFile, self.FLAG_QUIET_MOVE})
            elseif self:isEnemyPiece(newRank, newFile, side) then
                table.insert(moves, {rank, file, newRank, newFile, self.FLAG_CAPTURE})
            end
        end
    end
    -- #TODO: Agregar movimientos de enroque, solo mover al rey
end

function Board:generatePseudoLegalMoves()
    local moves = {}
    for rank = self.RANK_1, self.RANK_8 do
        for file = self.FILE_A, self.FILE_H do
            local piece = self.mailbox[rank][file]
            if piece ~= self.EMPTY then
                if (piece == self.W_PAWN and self.sideToMove == self.WHITE_TO_MOVE) or
                   (piece == self.B_PAWN and self.sideToMove == self.BLACK_TO_MOVE) then
                    self:generatePawnMoves(rank, file, self.sideToMove, moves)
                elseif (piece == self.W_KNIGHT and self.sideToMove == self.WHITE_TO_MOVE) or
                       (piece == self.B_KNIGHT and self.sideToMove == self.BLACK_TO_MOVE) then
                    self:generateKnightMoves(rank, file, self.sideToMove, moves)
                elseif (piece == self.W_BISHOP and self.sideToMove == self.WHITE_TO_MOVE) or
                       (piece == self.B_BISHOP and self.sideToMove == self.BLACK_TO_MOVE) then
                    self:generateBishopMoves(rank, file, self.sideToMove, moves)
                elseif (piece == self.W_ROOK and self.sideToMove == self.WHITE_TO_MOVE) or
                       (piece == self.B_ROOK and self.sideToMove == self.BLACK_TO_MOVE) then
                    self:generateRookMoves(rank, file, self.sideToMove, moves)
                elseif (piece == self.W_QUEEN and self.sideToMove == self.WHITE_TO_MOVE) or
                       (piece == self.B_QUEEN and self.sideToMove == self.BLACK_TO_MOVE) then
                    self:generateQueenMoves(rank, file, self.sideToMove, moves)
                elseif (piece == self.W_KING and self.sideToMove == self.WHITE_TO_MOVE) or
                       (piece == self.B_KING and self.sideToMove == self.BLACK_TO_MOVE) then
                    self:generateKingMoves(rank, file, self.sideToMove, moves)
                end
            end
        end
    end
    return moves
end

function Board:findKing(side)
    local king = side == self.WHITE_TO_MOVE and self.W_KING or self.B_KING
    for rank = self.RANK_1, self.RANK_8 do
        for file = self.FILE_A, self.FILE_H do
            if self.mailbox[rank][file] == king then
                return rank, file
            end
        end
    end
    return nil, nil
end

function Board:isSquareAttacked(rank, file, side)
    -- Verificar ataques de los caballos
    for _, offset in ipairs(self.KNIGHT_MOVES) do
        local attackerRank = rank + offset[1]
        local attackerFile = file + offset[2]
        if self:isInsideBoard(attackerRank, attackerFile) then
            local attackerPiece = self.mailbox[attackerRank][attackerFile]
            if attackerPiece == (side == self.WHITE_TO_MOVE and self.B_KNIGHT or self.W_KNIGHT) then
                return true
            end
        end
    end

    -- Verificar ataques diagonales (alfiles y damas)
    for rankDirection = -1, 1, 2 do
        for fileDirection = -1, 1, 2 do
            for distance = 1, 8 do -- #TODO: Posiblemente solo sea necesario hasta 7, verificar luego
                local attackerRank = rank + distance * rankDirection
                local attackerFile = file + distance * fileDirection
                if self:isInsideBoard(attackerRank, attackerFile) then
                    local attackerPiece = self.mailbox[attackerRank][attackerFile]
                    if attackerPiece == (side == self.WHITE_TO_MOVE and self.B_BISHOP or self.W_BISHOP)
                            or attackerPiece == (side == self.WHITE_TO_MOVE and self.B_QUEEN or self.W_QUEEN) then
                        return true
                    elseif attackerPiece ~= self.EMPTY then
                        break
                    end
                else
                    break
                end
            end
        end
    end

    -- Verificar ataques horizontales y verticales (torres y damas)
    -- Movimientos horizontales
    for direction = -1, 1, 2 do
        local newFile = file + direction
        while self:isInsideBoard(rank, newFile) do
            local attackerPiece = self.mailbox[rank][newFile]
            if attackerPiece == (side == self.WHITE_TO_MOVE and self.B_ROOK or self.W_ROOK)
                    or attackerPiece == (side == self.WHITE_TO_MOVE and self.B_QUEEN or self.W_QUEEN) then
                return true
            elseif attackerPiece ~= self.EMPTY  then
                break
            end
            newFile = newFile + direction
        end
    end

    -- Movimientos verticales
    for direction = -1, 1, 2 do
        local newRank = rank + direction
        while self:isInsideBoard(newRank, file) do
            local attackerPiece = self.mailbox[newRank][file]
            if attackerPiece == (side == self.WHITE_TO_MOVE and self.B_ROOK or self.W_ROOK)
                    or attackerPiece == (side == self.WHITE_TO_MOVE and self.B_QUEEN or self.W_QUEEN) then
                return true
            elseif attackerPiece ~= self.EMPTY  then
                break
            end
            newRank = newRank + direction
        end
    end

    -- Verificar ataques de los peones
    local pawnDirection = side == self.WHITE_TO_MOVE and 1 or -1
    for _, offset in ipairs({1,-1}) do
        local attackerRank = rank + pawnDirection
        local attackerFile = file + offset
        if self:isInsideBoard(attackerRank, attackerFile) then
            local attackerPiece = self.mailbox[attackerRank][attackerFile]
            if attackerPiece == (side == self.WHITE_TO_MOVE and self.B_PAWN or self.W_PAWN) then
                return true
            end
        end
    end

    -- Verificar ataques del rey
    for _, offset in ipairs(self.KING_MOVES) do
        local attackerRank = rank + offset[1]
        local attackerFile = file + offset[2]
        if self:isInsideBoard(attackerRank, attackerFile) then
            local attackerPiece = self.mailbox[attackerRank][attackerFile]
            if attackerPiece == (side == self.WHITE_TO_MOVE and self.B_KING or self.W_KING) then
                return true
            end
        end
    end

    return false
end

function Board:makeMove(move)
    local fromRank, fromFile, toRank, toFile, flags = unpack(move)
    local capturedPiece = self.mailbox[toRank][toFile]

    -- Guardar información para deshacer el movimiento
    local undo = {
        capturedPiece = capturedPiece,
        enPassantSquare = self.enPassantSquare,
        castlingRights = self.castlingRights,
        halfMoveClock = self.halfMoveClock
    }

    -- Actualizar enPassantSquare
    if flags == self.FLAG_DOUBLE_PAWN_PUSH then
        self.enPassantSquare = {(fromRank+toRank)/2, fromFile}
    else
        self.enPassantSquare = {0,0}
    end

    -- Actualizar halfMoveClock
    if capturedPiece ~= self.EMPTY or flags == self.FLAG_PAWN_MOVE then --#TODO agregar FLAG_PAWN_MOVE
        self.halfMoveClock = 0
    else
        self.halfMoveClock = self.halfMoveClock + 1
    end

    -- Realizar el movimiento
    self.mailbox[toRank][toFile] = self.mailbox[fromRank][fromFile]
    self.mailbox[fromRank][fromFile] = self.EMPTY

    -- Actualizar enroques
    if flags == self.FLAG_KING_CASTLE then
        if self.sideToMove == self.WHITE_TO_MOVE then
            self.mailbox[self.RANK_1][self.FILE_H] = self.EMPTY
            self.mailbox[self.RANK_1][self.FILE_F] = self.W_ROOK
        else
            self.mailbox[self.RANK_8][self.FILE_H] = self.EMPTY
            self.mailbox[self.RANK_8][self.FILE_F] = self.B_ROOK
        end
    elseif flags == self.FLAG_QUEEN_CASTLE then
        if self.sideToMove == self.WHITE_TO_MOVE then
            self.mailbox[self.RANK_1][self.FILE_A] = self.EMPTY
            self.mailbox[self.RANK_1][self.FILE_D] = self.W_ROOK
        else
            self.mailbox[self.RANK_8][self.FILE_A] = self.EMPTY
            self.mailbox[self.RANK_8][self.FILE_D] = self.B_ROOK
        end
    end

    -- Cambiar el lado que mueve
    self.sideToMove = not self.sideToMove

    return undo
end

function Board:unmakeMove(move, undo)
    local fromRank, fromFile, toRank, toFile, flags = unpack(move)

    -- Deshacer el movimiento
    self.mailbox[fromRank][fromFile] = self.mailbox[toRank][toFile]
    self.mailbox[toRank][toFile] = undo.capturedPiece

    -- Restaurar enPassantSquare, castlingRights y halfMoveClock
    self.enPassantSquare = undo.enPassantSquare
    self.castlingRights = undo.castlingRights
    self.halfMoveClock = undo.halfMoveClock

    -- Restaurar lado que mueve
    self.sideToMove = not self.sideToMove

    -- Restaurar enroques
    if flags == self.FLAG_KING_CASTLE then
        if self.sideToMove == self.WHITE_TO_MOVE then
            self.mailbox[self.RANK_1][self.FILE_H] = self.W_ROOK
            self.mailbox[self.RANK_1][self.FILE_F] = self.EMPTY
        else
            self.mailbox[self.RANK_8][self.FILE_H] = self.B_ROOK
            self.mailbox[self.RANK_8][self.FILE_F] = self.EMPTY
        end
    elseif flags == self.FLAG_QUEEN_CASTLE then
        if self.sideToMove == self.WHITE_TO_MOVE then
            self.mailbox[self.RANK_1][self.FILE_A] = self.W_ROOK
            self.mailbox[self.RANK_1][self.FILE_D] = self.EMPTY
        else
            self.mailbox[self.RANK_8][self.FILE_A] = self.B_ROOK
            self.mailbox[self.RANK_8][self.FILE_D] = self.EMPTY
        end
    end
end

function Board:perft(depth)
    if depth == 0 then
        return 1
    end

    local moves = self:generatePseudoLegalMoves()
    local nodes = 0
    local sideToMove = self.sideToMove
    local isCheckMate = true
    for _, move in ipairs(moves) do
        local undo = self:makeMove(move)
        -- Verificar que el rey enemigo no está en jaque
        local kingRank, kingFile = self:findKing(sideToMove)
        local isLegal = not self:isSquareAttacked(kingRank, kingFile, sideToMove)
        -- Si la posición es Legal se suma el nodo
        if isLegal then
            nodes = nodes + self:perft(depth - 1)
        end
        self:unmakeMove(move, undo)
    end

    return nodes
end

Board:initializeMailbox()

return Board