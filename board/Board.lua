local Board = {
    -- Constantes de Board
    WHITE_TO_MOVE = true,
    BLACK_TO_MOVE = false,
    --WHITE_TURN = 1,
    --BLACK_TURN = -1,
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
    castlingRights = "",
    enPassantSquare ="",
    halfMoveClock = 0,
    fullMoveNumber = 0
}

Board.PROMOTION_FLAGS = {Board.FLAG_QUEEN_PROMOTION, Board.FLAG_ROOK_PROMOTION, Board.FLAG_BISHOP_PROMOTION, Board.FLAG_KNIGHT_PROMOTION}
Board.CAPTURE_PROMOTION_FLAGS = {Board.FLAG_QUEEN_PROMOTION_CAPTURE, Board.FLAG_ROOK_PROMOTION_CAPTURE, Board.FLAG_BISHOP_PROMOTION_CAPTURE, Board.FLAG_KNIGHT_PROMOTION_CAPTURE}


function Board:initializeMailbox()
    for file = 1, 12 do
        self.mailbox[file] = {}
        for rank = 1, 12 do
            if file == 1 or file == 2 or file == 11 or file == 12 or
               rank == 1 or rank == 2 or rank == 11 or rank == 12 then
                self.mailbox[file][rank] = self.OUT
            else
                self.mailbox[file][rank] = self.EMPTY
            end
        end
    end
end

function Board:convertSquareToCoords(square)
    local file = square:byte() - string.byte('a') + self.FILE_A
    local rank = tonumber(square:sub(2, 2)) + self.RANK_1 - 1
    return file, rank
end

function Board:print()
    local PIECE_SYMBOLS = {
        [self.W_PAWN] = 'P',
        [self.W_KNIGHT] = 'N',
        [self.W_BISHOP] = 'B',
        [self.W_ROOK] = 'R',
        [self.W_QUEEN] = 'Q',
        [self.W_KING] = 'K',
        [self.B_PAWN] = 'p',
        [self.B_KNIGHT] = 'n',
        [self.B_BISHOP] = 'b',
        [self.B_ROOK] = 'r',
        [self.B_QUEEN] = 'q',
        [self.B_KING] = 'k',
        [self.EMPTY] = '.'  -- Assuming you have a value for empty squares
    }

    for rank = 10, 3, -1 do
        for file = 3, 10 do
            local piece = self.mailbox[file][rank]
            io.write(PIECE_SYMBOLS[piece] or '.', ' ')  -- Print the piece symbol or '.' for empty squares
        end
        io.write("\n")
    end
end


function Board:parseFEN(fen)
    local PIECES = {
        ['P'] = self.W_PAWN,  -- White Pawn
        ['N'] = self.W_KNIGHT,  -- White Knight
        ['B'] = self.W_BISHOP,  -- White Bishop
        ['R'] = self.W_ROOK,  -- White Rook
        ['Q'] = self.W_QUEEN,  -- White Queen
        ['K'] = self.W_KING,  -- White King
        ['p'] = self.B_PAWN, -- Black Pawn
        ['n'] = self.B_KNIGHT, -- Black Knight
        ['b'] = self.B_BISHOP, -- Black Bishop
        ['r'] = self.B_ROOK, -- Black Rook
        ['q'] = self.B_QUEEN, -- Black Queen
        ['k'] = self.B_KING  -- Black King
    }
    local rank = self.RANK_8  -- Adjust rank to start from 8
    local file = self.FILE_A  -- Adjust file to start from A

    local parts = {}
    for part in string.gmatch(fen, "[^%s]+") do
        table.insert(parts, part)
    end
    local piecePlacement = parts[1]
    local sideToMove = parts[2]
    local castlingRights = parts[3]
    local enPassantSquare = parts[4]
    local halfMoveClock = tonumber(parts[5])
    local fullMoveNumber = tonumber(parts[6])

    for i = 1, #piecePlacement do
        local char = piecePlacement:sub(i, i)
        if char == '/' then
            rank = rank - 1  -- Move to the next rank down
            file = self.FILE_A  -- Reset file to A
        elseif char:match("%d") then
            file = file + tonumber(char)  -- Skip the specified number of files
        elseif PIECES[char] then
            self.mailbox[file][rank] = PIECES[char]
            file = file + 1
        end
    end
end


function Board:isInsideBoard(file, rank)
    return file >= self.FILE_A and file <= self.FILE_H and rank >= self.RANK_1 and rank <= self.RANK_8
end

function Board:isEmpty(file, rank)
    return self.mailbox[file][rank] == self.EMPTY
end

function Board:isEnemyPiece(file, rank, side)
    local piece = self.mailbox[file][rank]
    return (side == self.WHITE_TO_MOVE and piece < self.EMPTY) or (side == self.BLACK_TO_MOVE and piece > self.EMPTY and piece < self.OUT)
end

function Board:generatePawnMoves(file, rank, side, moves)
    local direction = side == self.WHITE_TO_MOVE and 1 or -1
    local startRank = side == self.WHITE_TO_MOVE and self.RANK_2 or self.RANK_7
    local promotionRank = side == self.WHITE_TO_MOVE and self.RANK_8 or self.RANK_1
    -- Movimiento hacia adelante
    if self:isEmpty(file, rank + direction) then
        
        if rank + direction == promotionRank then
            for _, flag in ipairs(self.PROMOTION_FLAGS) do
                table.insert(moves, {file, rank, file, rank + direction, flag})
            end
        else
            table.insert(moves, {file, rank, file, rank + direction, self.FLAG_QUIET_MOVE})
            -- Movimiento inicial doble
            if rank == startRank and self:isEmpty(file, rank + 2 * direction) then
                table.insert(moves, {file, rank, file, rank + 2 * direction, self.FLAG_DOUBLE_PAWN_PUSH})
            end
        end
    end

    -- Captura en diagonal izquierda
    if self:isInsideBoard(file - 1, rank + direction) and self:isEnemyPiece(file - 1, rank + direction, side) then
        if rank + direction == promotionRank then
            for _, flag in ipairs(self.CAPTURE_PROMOTION_FLAGS) do
                table.insert(moves, {file, rank, file - 1, rank + direction, flag})
            end
        else
            table.insert(moves, {file, rank, file - 1, rank + direction, self.FLAG_CAPTURE})
        end
    end

    -- Captura en diagonal derecha
    if self:isInsideBoard(file + 1, rank + direction) and self:isEnemyPiece(file + 1, rank + direction, side) then
        if rank + direction == promotionRank then
            for _, flag in ipairs(self.CAPTURE_PROMOTION_FLAGS) do
                table.insert(moves, {file, rank, file + 1, rank + direction, flag})
            end
        else
            table.insert(moves, {file, rank, file + 1, rank + direction, self.FLAG_CAPTURE})
        end
    end

    -- Captura al paso (en passant)
    if self.enPassantSquare ~= "" then
        local epFile, epRank = self:convertSquareToCoords(self.enPassantSquare)
        if rank == (side == self.WHITE_TO_MOVE and self.RANK_5 or self.RANK_4) and
            (file - 1 == epFile or file + 1 == epFile) and epRank == rank + direction then
            table.insert(moves, {file, rank, epFile, epRank, self.FLAG_EP_CAPTURE})
        end
    end

end

function Board:generateKnightMoves(file, rank, side, moves)

    for _, offset in ipairs(self.KNIGHT_MOVES) do
        local newFile = file + offset[1]
        local newRank = rank + offset[2]
        if self:isInsideBoard(newFile, newRank) then
            if self:isEmpty(newFile, newRank) then
                table.insert(moves, {file, rank, newFile, newRank, self.FLAG_QUIET_MOVE})
            elseif self:isEnemyPiece(newFile, newRank, side) then
                table.insert(moves, {file, rank, newFile, newRank, self.FLAG_CAPTURE})
            end
        end
    end
end

function Board:generateBishopMoves(file, rank, side, moves)
    -- Movimientos diagonales (noreste, noroeste, sureste, suroeste)
    for fileDirection = -1, 1, 2 do
        for rankDirection = -1, 1, 2 do
            local newFile = file + fileDirection
            local newRank = rank + rankDirection
            while self:isInsideBoard(newFile, newRank) do
                if self:isEmpty(newFile, newRank) then
                    table.insert(moves, {file, rank, newFile, newRank, self.FLAG_QUIET_MOVE})
                elseif self:isEnemyPiece(newFile, newRank, side) then
                    table.insert(moves, {file, rank, newFile, newRank, self.FLAG_CAPTURE})
                    break
                else
                    break
                end
                newFile = newFile + fileDirection
                newRank = newRank + rankDirection
            end
        end
    end
end

function Board:generateRookMoves(file, rank, side,moves)
    -- Movimientos verticales (arriba y abajo)
    for direction = -1, 1, 2 do
        local newRank = rank + direction
        while self:isInsideBoard(file, newRank) do
            if self:isEmpty(file, newRank) then
                table.insert(moves, {file, rank, file, newRank, self.FLAG_QUIET_MOVE})
            elseif self:isEnemyPiece(file, newRank, side) then
                table.insert(moves, {file, rank, file, newRank, self.FLAG_CAPTURE})
                break
            else
                break
            end
            newRank = newRank + direction
        end
    end

    -- Movimientos horizontales (izquierda y derecha)
    for direction = -1, 1, 2 do
        local newFile = file + direction
        while self:isInsideBoard(newFile, rank) do
            if self:isEmpty(newFile, rank) then
                table.insert(moves, {file, rank, newFile, rank, self.FLAG_QUIET_MOVE})
            elseif self:isEnemyPiece(newFile, rank, side) then
                table.insert(moves, {file, rank, newFile, rank, self.FLAG_CAPTURE})
                break
            else
                break
            end
            newFile = newFile + direction
        end
    end
end

function Board:generateRookMoves(file, rank, side, moves)
    -- Movimientos verticales (arriba y abajo)
    for direction = -1, 1, 2 do
        local newRank = rank + direction
        while self:isInsideBoard(file, newRank) do
            if self:isEmpty(file, newRank) then
                table.insert(moves, {file, rank, file, newRank, self.FLAG_QUIET_MOVE})
            elseif self:isEnemyPiece(file, newRank, side) then
                table.insert(moves, {file, rank, file, newRank, self.FLAG_CAPTURE})
                break
            else
                break
            end
            newRank = newRank + direction
        end
    end

    -- Movimientos horizontales (izquierda y derecha)
    for direction = -1, 1, 2 do
        local newFile = file + direction
        while self:isInsideBoard(newFile, rank) do
            if self:isEmpty(newFile, rank) then
                table.insert(moves, {file, rank, newFile, rank, self.FLAG_QUIET_MOVE})
            elseif self:isEnemyPiece(newFile, rank, side) then
                table.insert(moves, {file, rank, newFile, rank, self.FLAG_CAPTURE})
                break
            else
                break
            end
            newFile = newFile + direction
        end
    end
end

function Board:generateQueenMoves(file, rank, side, moves)
    -- Generar movimientos de torre
    self:generateRookMoves(file, rank, side,moves)

    -- Generar movimientos de alfil
    self:generateBishopMoves(file, rank, side,moves)
end

function Board:generateKingMoves(file, rank, side, moves)

    for _, dir in ipairs(self.KING_MOVES) do
        local newFile = file + dir[1]
        local newRank = rank + dir[2]

        if self:isInsideBoard(newFile, newRank) then
            if self:isEmpty(newFile, newRank) then
                table.insert(moves, {file, rank, newFile, newRank, self.FLAG_QUIET_MOVE})
            elseif self:isEnemyPiece(newFile, newRank, side) then
                table.insert(moves, {file, rank, newFile, newRank, self.FLAG_CAPTURE})
            end
        end
    end
end

function Board:generatePseudoLegalMoves()
    local moves = {}
    for file = self.FILE_A, self.FILE_H do
        for rank = self.RANK_1, self.RANK_8 do
            local piece = self.mailbox[file][rank]
            if piece ~= self.EMPTY and piece ~= self.OUT then
                if (piece == self.W_PAWN and self.sideToMove == self.WHITE_TO_MOVE) or
                   (piece == self.B_PAWN and self.sideToMove == self.BLACK_TO_MOVE) then
                    self:generatePawnMoves(file, rank, self.sideToMove, moves)
                elseif (piece == self.W_KNIGHT and self.sideToMove == self.WHITE_TO_MOVE) or
                       (piece == self.B_KNIGHT and self.sideToMove == self.BLACK_TO_MOVE) then
                    self:generateKnightMoves(file, rank, self.sideToMove, moves)
                elseif (piece == self.W_BISHOP and self.sideToMove == self.WHITE_TO_MOVE) or
                       (piece == self.B_BISHOP and self.sideToMove == self.BLACK_TO_MOVE) then
                    self:generateBishopMoves(file, rank, self.sideToMove, moves)
                elseif (piece == self.W_ROOK and self.sideToMove == self.WHITE_TO_MOVE) or
                       (piece == self.B_ROOK and self.sideToMove == self.BLACK_TO_MOVE) then
                    self:generateRookMoves(file, rank, self.sideToMove, moves)
                elseif (piece == self.W_QUEEN and self.sideToMove == self.WHITE_TO_MOVE) or
                       (piece == self.B_QUEEN and self.sideToMove == self.BLACK_TO_MOVE) then
                    self:generateQueenMoves(file, rank, self.sideToMove, moves)
                elseif (piece == self.W_KING and self.sideToMove == self.WHITE_TO_MOVE) or
                       (piece == self.B_KING and self.sideToMove == self.BLACK_TO_MOVE) then
                    self:generateKingMoves(file, rank, self.sideToMove, moves)
                end
            end
        end
    end
    return moves
end

function Board:findKing(side)
    local king = side == self.WHITE_TO_MOVE and self.W_KING or self.B_KING
    for file = self.FILE_A, self.FILE_H do
        for rank = self.RANK_1, self.RANK_8 do
            if self.mailbox[file][rank] == king then
                return file, rank
            end
        end
    end
    return nil, nil
end

function Board:isSquareAttacked(file, rank, side)
    -- Verificar ataques de los caballos
    for _, offset in ipairs(self.KNIGHT_MOVES) do
        local attackerFile = file + offset[1]
        local attackerRank = rank + offset[2]
        if self:isInsideBoard(attackerFile, attackerRank) then
            local attackerPiece = self.mailbox[attackerFile][attackerRank]
            if attackerPiece == (side == self.WHITE_TO_MOVE and self.B_KNIGHT or self.W_KNIGHT) then
                return true
            end
        end
    end

    -- Verificar ataques diagonales (alfiles y damas)
    for fileDirection = -1, 1, 2 do
        for rankDirection = -1, 1, 2 do
            for distance = 1, 8 do
                local attackerFile = file + distance * fileDirection
                local attackerRank = rank + distance * rankDirection
                if self:isInsideBoard(attackerFile, attackerRank) then
                    local attackerPiece = self.mailbox[attackerFile][attackerRank]
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
    for direction = -1, 1, 2 do
        for _, axis in ipairs({self.FILE_A, self.RANK_1}) do
            for distance = 1, 8 do
                local attackerFile = file + distance * direction * (axis == self.FILE_A and 1 or 0)
                local attackerRank = rank + distance * direction * (axis == self.RANK_1 and 1 or 0)
                if self:isInsideBoard(attackerFile, attackerRank) then
                    local attackerPiece = self.mailbox[attackerFile][attackerRank]
                    if attackerPiece == (side == self.WHITE_TO_MOVE and self.B_ROOK or self.W_ROOK)
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

    -- Verificar ataques del rey
    for _, offset in ipairs(self.KING_MOVES) do
        local attackerFile = file + offset[1]
        local attackerRank = rank + offset[2]
        if self:isInsideBoard(attackerFile, attackerRank) then
            local attackerPiece = self.mailbox[attackerFile][attackerRank]
            if attackerPiece == (side == self.WHITE_TO_MOVE and self.B_KING or self.W_KING) then
                return true
            end
        end
    end

    -- Verificar ataques de los peones
    local pawnDirection = side == self.WHITE_TO_MOVE and 1 or -1
    for _, offset in ipairs({{1, pawnDirection}, {-1, pawnDirection}}) do
        local attackerFile = file + offset[1]
        local attackerRank = rank + offset[2]
        if self:isInsideBoard(attackerFile, attackerRank) then
            local attackerPiece = self.mailbox[attackerFile][attackerRank]
            if attackerPiece == (side == self.WHITE_TO_MOVE and self.B_PAWN or self.W_PAWN) then
                return true
            end
        end
    end

    return false
end

function Board:makeMove(move)
    local fromFile, fromRank, toFile, toRank, flags = unpack(move)
    local capturedPiece = self.mailbox[toFile][toRank]

    -- Guardar información para deshacer el movimiento
    local undo = {
        capturedPiece = capturedPiece,
        enPassantSquare = self.enPassantSquare,
        castlingRights = self.castlingRights,
        halfMoveClock = self.halfMoveClock
    }

    -- Actualizar enPassantSquare
    if flags == self.FLAG_DOUBLE_PAWN_PUSH then
        self.enPassantSquare = string.char(fromFile + string.byte("a") - 1) .. tostring((fromRank + toRank) / 2)
    else
        self.enPassantSquare = ""
    end

    -- Actualizar halfMoveClock
    if capturedPiece ~= self.EMPTY or flags == self.FLAG_PAWN_MOVE then
        self.halfMoveClock = 0
    else
        self.halfMoveClock = self.halfMoveClock + 1
    end

    -- Realizar el movimiento
    self.mailbox[toFile][toRank] = self.mailbox[fromFile][fromRank]
    self.mailbox[fromFile][fromRank] = self.EMPTY

    -- Actualizar castlingRights y enPassantSquare para enroques
    if flags == self.FLAG_KING_CASTLE then
        if self.sideToMove == self.WHITE_TO_MOVE then
            self.mailbox[self.FILE_G][self.RANK_1] = self.EMPTY
            self.mailbox[self.FILE_F][self.RANK_1] = self.W_ROOK
        else
            self.mailbox[self.FILE_G][self.RANK_8] = self.EMPTY
            self.mailbox[self.FILE_F][self.RANK_8] = self.B_ROOK
        end
    elseif flags == self.FLAG_QUEEN_CASTLE then
        if self.sideToMove == self.WHITE_TO_MOVE then
            self.mailbox[self.FILE_C][self.RANK_1] = self.EMPTY
            self.mailbox[self.FILE_D][self.RANK_1] = self.W_ROOK
        else
            self.mailbox[self.FILE_C][self.RANK_8] = self.EMPTY
            self.mailbox[self.FILE_D][self.RANK_8] = self.B_ROOK
        end
    end

    -- Cambiar el lado que mueve
    self.sideToMove = not self.sideToMove

    return undo
end

function Board:unmakeMove(move, undo)
    local fromFile, fromRank, toFile, toRank, flags = unpack(move)

    -- Deshacer el movimiento
    self.mailbox[fromFile][fromRank] = self.mailbox[toFile][toRank]
    self.mailbox[toFile][toRank] = undo.capturedPiece

    -- Restaurar enPassantSquare, castlingRights y halfMoveClock
    self.enPassantSquare = undo.enPassantSquare
    self.castlingRights = undo.castlingRights
    self.halfMoveClock = undo.halfMoveClock

    -- Restaurar lado que mueve
    self.sideToMove = not self.sideToMove

    -- Restaurar enroques
    if flags == self.FLAG_KING_CASTLE then
        if self.sideToMove == self.WHITE_TO_MOVE then
            self.mailbox[self.FILE_G][self.RANK_1] = self.W_KING
            self.mailbox[self.FILE_F][self.RANK_1] = self.EMPTY
        else
            self.mailbox[self.FILE_G][self.RANK_8] = self.B_KING
            self.mailbox[self.FILE_F][self.RANK_8] = self.EMPTY
        end
    elseif flags == self.FLAG_QUEEN_CASTLE then
        if self.sideToMove == self.WHITE_TO_MOVE then
            self.mailbox[self.FILE_C][self.RANK_1] = self.W_KING
            self.mailbox[self.FILE_D][self.RANK_1] = self.EMPTY
        else
            self.mailbox[self.FILE_C][self.RANK_8] = self.B_KING
            self.mailbox[self.FILE_D][self.RANK_8] = self.EMPTY
        end
    end
end

function Board:isLegalMove(move)
    local fromFile, fromRank, toFile, toRank, flags = unpack(move)
    local piece = self.mailbox[fromFile][fromRank]
    local capturedPiece = self.mailbox[toFile][toRank]

    -- Realizar el movimiento temporalmente
    local undo = self:makeMove(move)

    -- Verificar si el rey está bajo ataque
    local kingFile, kingRank = self:findKing(self.sideToMove)
    local isLegal = not self:isSquareAttacked(kingFile, kingRank, not self.sideToMove)

    -- Deshacer el movimiento
    self:unmakeMove(move, undo)

    return isLegal
end

function Board:perft(depth)
    if depth == 0 then
        return 1
    end

    local moves = self:generatePseudoLegalMoves()
    local nodes = 0
    local sideToMove = self.sideToMove
    for _, move in ipairs(moves) do
        local undo = self:makeMove(move)
        -- Verificar que el rey enemigo no está en jaque
        local kingFile, kingRank = self:findKing(sideToMove)
        local isLegal = not self:isSquareAttacked(kingFile, kingRank, sideToMove)
        -- Si la posición es Legal se suma el nodo
        if isLegal then
            local kfile, krank = self:findKing(self.sideToMove)
            
            nodes = nodes + self:perft(depth - 1)
        end

        self:unmakeMove(move, undo)
    end

    return nodes
end

Board:initializeMailbox()

return Board