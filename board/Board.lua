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
    -- Filas y Columnas
    FILE_A = 1,
    FILE_B = 2,
    FILE_C = 3,
    FILE_D = 4,
    FILE_E = 5,
    FILE_F = 6,
    FILE_G = 7,
    FILE_H = 8,
    RANK_1 = 1,
    RANK_2 = 2,
    RANK_3 = 3,
    RANK_4 = 4,
    RANK_5 = 5,
    RANK_6 = 6,
    RANK_7 = 7,
    RANK_8 = 8,
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
    castlingRights = {false,false,false,false},
    enPassantSquare = {0,0},
    halfMoveClock = 0,
    fullMoveNumber = 0
}

Board.PROMOTION_FLAGS = {Board.FLAG_QUEEN_PROMOTION, Board.FLAG_ROOK_PROMOTION, Board.FLAG_BISHOP_PROMOTION, Board.FLAG_KNIGHT_PROMOTION}
Board.CAPTURE_PROMOTION_FLAGS = {Board.FLAG_QUEEN_PROMOTION_CAPTURE, Board.FLAG_ROOK_PROMOTION_CAPTURE, Board.FLAG_BISHOP_PROMOTION_CAPTURE, Board.FLAG_KNIGHT_PROMOTION_CAPTURE}

function Board:initializeMailbox()
    for rank = self.RANK_1, self.RANK_8 do
        self.mailbox[rank] = {}
        for file = self.FILE_A, self.FILE_H do
            self.mailbox[rank][file] = self.EMPTY
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
    local map = ""
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
        [self.EMPTY] = "."
    }

    for rank = self.RANK_8, self.RANK_1, -1 do
        for file = self.FILE_A, self.FILE_H do
            local piece = self.mailbox[rank][file]
            map = map .. (PIECE_SYMBOLS[piece] or ".") .. " "
        end
        map = map .."\n"
    end
    io.write(map)
end

function Board:parseFEN(fen)
    -- Resetear el tablero
    self:initializeMailbox()
    self.castlingRights = {false,false,false,false}
    self.enPassantSquare = {0,0}
    self.halfMoveClock = 0
    self.fullMoveNumber = 0

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
    local rank = self.RANK_8
    local file = self.FILE_A

    local parts = {} -- Dividir el FEN en partes
    for part in string.gmatch(fen, "[^%s]+") do
        table.insert(parts, part)
    end

    local piecePlacement = parts[1]
    -- Si "w" mueven las blancas de lo contrario ("b") mueven las negras
    self.sideToMove = parts[2] == "w" and self.WHITE_TO_MOVE or self.BLACK_TO_MOVE

    -- Agregar derechos de enroque
    if parts[3]:find("K") then self.castlingRights[1] = true end  -- Enroque corto blanco
    if parts[3]:find("Q") then self.castlingRights[2] = true end  -- Enroque largo blanco
    if parts[3]:find("k") then self.castlingRights[3] = true end  -- Enroque corto negro
    if parts[3]:find("q") then self.castlingRights[4] = true end  -- Enroque largo negro

    self.enPassantSquare = self:convertSquareToCoords(parts[4])
    self.halfMoveClock = parts[5] == nil and 0 or tonumber(parts[5])
    self.fullMoveNumber = parts[6] == nil and 0 or tonumber(parts[6])

    for i = 1, #piecePlacement do
        local char = piecePlacement:sub(i, i)
        if char == "/" then
            rank = rank - 1
            file = self.FILE_A
        elseif char:match("%d") then
            file = file + tonumber(char)
        elseif PIECES[char] then
            self.mailbox[rank][file] = PIECES[char]
            file = file + 1
        end
    end
end

function Board:isInsideBoard(rank, file)
    return file >= self.FILE_A and file <= self.FILE_H and rank >= self.RANK_1 and rank <= self.RANK_8
end

function Board:isEmpty(rank, file)
    return self.mailbox[rank][file] == self.EMPTY
end

function Board:isEnemyPiece(rank, file, side)
    local piece = self.mailbox[rank][file]
    return (side == self.WHITE_TO_MOVE and piece < self.EMPTY) or (side == self.BLACK_TO_MOVE and piece > self.EMPTY and piece < self.OUT)
end

function Board:generatePawnMoves(rank, file, side, moves)
    local direction = side == self.WHITE_TO_MOVE and 1 or -1
    local startRank = side == self.WHITE_TO_MOVE and self.RANK_2 or self.RANK_7
    local promotionRank = side == self.WHITE_TO_MOVE and self.RANK_8 or self.RANK_1
    local toRank = rank + direction
    -- Movimiento hacia adelante
    if self:isEmpty(toRank,file) then
        
        if toRank == promotionRank then
            for _, flag in ipairs(self.PROMOTION_FLAGS) do
                table.insert(moves, {rank, file, toRank, file, flag})
            end
        else
            table.insert(moves, {rank, file, toRank, file, self.FLAG_QUIET_MOVE})
            -- Movimiento inicial doble
            if rank == startRank and self:isEmpty(toRank + direction, file) then
                table.insert(moves, {rank, file, toRank + direction, file, self.FLAG_DOUBLE_PAWN_PUSH})
            end
        end
    end

    -- Captura en diagonal izquierda
    local toFile = file - 1
    if self:isInsideBoard(toRank, toFile) and self:isEnemyPiece(toRank, toFile, side) then
        if toRank == promotionRank then
            for _, flag in ipairs(self.CAPTURE_PROMOTION_FLAGS) do
                table.insert(moves, {rank, file, toRank, toFile , flag})
            end
        else
            table.insert(moves, {rank, file, toRank, toFile, self.FLAG_CAPTURE})
        end
    end

    -- Captura en diagonal derecha
    toFile = file + 1
    if self:isInsideBoard(toRank, toFile) and self:isEnemyPiece(toRank, toFile, side) then
        if toRank == promotionRank then
            for _, flag in ipairs(self.CAPTURE_PROMOTION_FLAGS) do
                table.insert(moves, {rank, file, toRank, toFile, flag})
            end
        else
            table.insert(moves, {rank, file, toRank, toFile, self.FLAG_CAPTURE})
        end
    end

    -- Captura al paso (en passant)
    if self.enPassantSquare[1] ~= 0 then
        local epRank, epFile = unpack(self.enPassantSquare)
        if rank == (side == self.WHITE_TO_MOVE and self.RANK_5 or self.RANK_4) and
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
    -- Movimientos horizontales (izquierda y derecha)
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

    -- Movimientos verticales (arriba y abajo)
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
    -- Agregar movimientos de enroque
    if side == self.WHITE_TO_MOVE then
        if self.castlingRights[1] then -- Enroque corto blanco
            if self.mailbox[self.RANK_1][self.FILE_F] == self.EMPTY and
               self.mailbox[self.RANK_1][self.FILE_G] == self.EMPTY and
               not self:isSquareAttacked(self.RANK_1, self.FILE_E, self.sideToMove) and
               not self:isSquareAttacked(self.RANK_1, self.FILE_F, self.sideToMove) and
               not self:isSquareAttacked(self.RANK_1, self.FILE_G, self.sideToMove) then
                table.insert(moves, {rank, file, self.RANK_1, self.FILE_G, self.FLAG_KING_CASTLE})
            end
        end

        if self.castlingRights[2] then -- Enroque largo blanco
            if self.mailbox[self.RANK_1][self.FILE_D] == self.EMPTY and
               self.mailbox[self.RANK_1][self.FILE_C] == self.EMPTY and
               self.mailbox[self.RANK_1][self.FILE_B] == self.EMPTY and
               not self:isSquareAttacked(self.RANK_1, self.FILE_E, self.sideToMove) and
               not self:isSquareAttacked(self.RANK_1, self.FILE_D, self.sideToMove) and
               not self:isSquareAttacked(self.RANK_1, self.FILE_C, self.sideToMove) then
                table.insert(moves, {rank, file, self.RANK_1, self.FILE_C, self.FLAG_QUEEN_CASTLE})
            end
        end
    else
        if self.castlingRights[3] then -- Enroque corto negro
            if self.mailbox[self.RANK_8][self.FILE_F] == self.EMPTY and
               self.mailbox[self.RANK_8][self.FILE_G] == self.EMPTY and
               not self:isSquareAttacked(self.RANK_8, self.FILE_E, self.sideToMove) and
               not self:isSquareAttacked(self.RANK_8, self.FILE_F, self.sideToMove) and
               not self:isSquareAttacked(self.RANK_8, self.FILE_G, self.sideToMove) then
                table.insert(moves, {rank, file, self.RANK_8, self.FILE_G, self.FLAG_KING_CASTLE})
            end
        end

        if self.castlingRights[4] then -- Enroque largo negro
            if self.mailbox[self.RANK_8][self.FILE_D] == self.EMPTY and
               self.mailbox[self.RANK_8][self.FILE_C] == self.EMPTY and
               self.mailbox[self.RANK_8][self.FILE_B] == self.EMPTY and
               not self:isSquareAttacked(self.RANK_8, self.FILE_E, self.sideToMove) and
               not self:isSquareAttacked(self.RANK_8, self.FILE_D, self.sideToMove) and
               not self:isSquareAttacked(self.RANK_8, self.FILE_C, self.sideToMove) then
                table.insert(moves, {rank, file, self.RANK_8, self.FILE_C, self.FLAG_QUEEN_CASTLE})
            end
        end
    end
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
            for distance = 1, 7 do
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
        enPassantSquare = {unpack(self.enPassantSquare)},
        castlingRights = {unpack(self.castlingRights)},
        halfMoveClock = self.halfMoveClock
    }

    -- Actualizar enPassantSquare
    if flags == self.FLAG_DOUBLE_PAWN_PUSH then
        self.enPassantSquare[1] = (fromRank + toRank) / 2
        self.enPassantSquare[2] = fromFile
        --self.enPassantSquare = {(fromRank + toRank) / 2, fromFile}
    else
        --self.enPassantSquare = {0, 0}
        self.enPassantSquare[1] = 0
        self.enPassantSquare[2] = 0
    end

    -- Actualizar halfMoveClock
    if capturedPiece ~= self.EMPTY or self.mailbox[fromRank][fromFile] == self.W_PAWN or self.mailbox[fromRank][fromFile] == self.B_PAWN then
        self.halfMoveClock = 0
    else
        self.halfMoveClock = self.halfMoveClock + 1
    end

    -- Realizar el movimiento
    if flags >= self.FLAG_KNIGHT_PROMOTION and flags <= self.FLAG_QUEEN_PROMOTION_CAPTURE then
        local promotionPiece
        if flags == self.FLAG_KNIGHT_PROMOTION or flags == self.FLAG_KNIGHT_PROMOTION_CAPTURE then
            promotionPiece = self.sideToMove == self.WHITE_TO_MOVE and self.W_KNIGHT or self.B_KNIGHT
        elseif flags == self.FLAG_BISHOP_PROMOTION or flags == self.FLAG_BISHOP_PROMOTION_CAPTURE then
            promotionPiece = self.sideToMove == self.WHITE_TO_MOVE and self.W_BISHOP or self.B_BISHOP
        elseif flags == self.FLAG_ROOK_PROMOTION or flags == self.FLAG_ROOK_PROMOTION_CAPTURE then
            promotionPiece = self.sideToMove == self.WHITE_TO_MOVE and self.W_ROOK or self.B_ROOK
        elseif flags == self.FLAG_QUEEN_PROMOTION or flags == self.FLAG_QUEEN_PROMOTION_CAPTURE then
            promotionPiece = self.sideToMove == self.WHITE_TO_MOVE and self.W_QUEEN or self.B_QUEEN
        end
        self.mailbox[toRank][toFile] = promotionPiece
    else
        self.mailbox[toRank][toFile] = self.mailbox[fromRank][fromFile]
    end
    self.mailbox[fromRank][fromFile] = self.EMPTY

    -- Capturas al paso
    if flags == self.FLAG_EP_CAPTURE then
        local captureRank = self.sideToMove == self.WHITE_TO_MOVE and toRank - 1 or toRank + 1
        self.mailbox[captureRank][toFile] = self.EMPTY
    end

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

    -- Actualizar derechos de enroque
    if self.mailbox[toRank][toFile] == self.W_KING then
        self.castlingRights[1] = false
        self.castlingRights[2] = false
    elseif self.mailbox[toRank][toFile] == self.B_KING then
        self.castlingRights[3] = false
        self.castlingRights[4] = false
    elseif self.mailbox[toRank][toFile] == self.W_ROOK then
        if fromRank == self.RANK_1 then
            if fromFile == self.FILE_H then self.castlingRights[1] = false end
            if fromFile == self.FILE_A then self.castlingRights[2] = false end
        end
    elseif self.mailbox[toRank][toFile] == self.B_ROOK then
        if fromRank == self.RANK_8 then
            if fromFile == self.FILE_H then self.castlingRights[3] = false end
            if fromFile == self.FILE_A then self.castlingRights[4] = false end
        end
    elseif capturedPiece == self.W_ROOK and self.sideToMove == self.BLACK_TO_MOVE then
        if toRank == self.RANK_1 then
            if toFile == self.FILE_H then self.castlingRights[1] = false end
            if toFile == self.FILE_A then self.castlingRights[2] = false end
        end
    elseif capturedPiece == self.B_ROOK and self.sideToMove == self.WHITE_TO_MOVE then
        if toRank == self.RANK_8 then
            if toFile == self.FILE_H then self.castlingRights[3] = false end
            if toFile == self.FILE_A then self.castlingRights[4] = false end
        end
    end

    -- Cambiar el lado que mueve
    self.sideToMove = not self.sideToMove

    return undo
end


function Board:unmakeMove(move, undo)
    local fromRank, fromFile, toRank, toFile, flags = unpack(move)

    -- Restaurar lado que mueve
    self.sideToMove = not self.sideToMove

    -- Deshacer el movimiento
    if flags >= self.FLAG_KNIGHT_PROMOTION and flags <= self.FLAG_QUEEN_PROMOTION_CAPTURE then
        self.mailbox[fromRank][fromFile] = self.sideToMove == self.WHITE_TO_MOVE and self.W_PAWN or self.B_PAWN
    else
        self.mailbox[fromRank][fromFile] = self.mailbox[toRank][toFile]
    end
    self.mailbox[toRank][toFile] = undo.capturedPiece

    -- Restaurar capturas al paso
    if flags == self.FLAG_EP_CAPTURE then
        local captureRank = self.sideToMove == self.WHITE_TO_MOVE and toRank - 1 or toRank + 1
        self.mailbox[captureRank][toFile] = self.sideToMove == self.WHITE_TO_MOVE and self.B_PAWN or self.W_PAWN
    end

    self.enPassantSquare[1] = undo.enPassantSquare[1]
    self.enPassantSquare[2] = undo.enPassantSquare[2]
    self.castlingRights[1] = undo.castlingRights[1]
    self.castlingRights[2] = undo.castlingRights[2]
    self.castlingRights[3] = undo.castlingRights[3]
    self.castlingRights[4] = undo.castlingRights[4]
    self.halfMoveClock = undo.halfMoveClock

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