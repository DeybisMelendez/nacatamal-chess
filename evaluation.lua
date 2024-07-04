local b = require "board"
local evaluation = {
    PawnPhase = 0,
    KnightPhase = 1,
    BishopPhase = 1,
    RookPhase = 2,
    QueenPhase = 4,
    material = {}
}
evaluation.TotalPhase = evaluation.PawnPhase*16 + evaluation.KnightPhase*4 +
    evaluation.BishopPhase*4 + evaluation.RookPhase*4 + evaluation.QueenPhase*2

evaluation.material[b.EMPTY] = 0
evaluation.material[b.W_PAWN] = 100
evaluation.material[b.W_KNIGHT] = 320
evaluation.material[b.W_BISHOP] = 350
evaluation.material[b.W_ROOK] = 525
evaluation.material[b.W_QUEEN] = 1000
evaluation.material[b.W_KING] = 10000
evaluation.material[b.B_PAWN] = -100
evaluation.material[b.B_KNIGHT] = -320
evaluation.material[b.B_BISHOP] = -350
evaluation.material[b.B_ROOK] = -525
evaluation.material[b.B_QUEEN] = -1000
evaluation.material[b.B_KING] = -10000

function evaluation:doubledPawn(board,pawn,fromRank,file)
    local toRank = pawn == board.W_PAWN and board.RANK_8 or board.RANK_1
    for rank = fromRank, toRank, pawn do
        if board.mailbox[rank][file] == pawn then
            return -50 * pawn
        end
    end
    return 0
end

function evaluation:isolatedPawn(board,pawn,file)
    for rank = board.RANK_1, board.RANK_8 do
        if file > 1 then
            if board.mailbox[rank][file-1] == pawn then
                return 0
            end
        end
        if file < 8 then
            if board.mailbox[rank][file+1] == pawn then
                return 0
            end
        end
    end
    return -50 * pawn
end

function evaluation:blockedPawn(board,pawn,rank,file)
    if pawn == board.W_PAWN and rank < board.RANK_8 then
        if board:isEmpty(rank+1,file) then
            return 0
        end
    elseif pawn == board.B_PAWN and rank > board.RANK_1 then
        if board:isEmpty(rank-1,file) then
            return 0
        end
    end
    return -50 * pawn
end

function evaluation:mobilityKnight(board,rank,file,side)
    local eval = 0
    for _, offset in ipairs(board.KNIGHT_MOVES) do
        local newRank = rank + offset[1]
        local newFile = file + offset[2]
        if board:isInsideBoard(newRank, newFile) then
            if board:isEmpty(newRank, newFile) then
                eval = eval + 10
            elseif board:isEnemyPiece(newRank, newFile, side) then
                eval = eval + 20
            end
        end
    end
    return eval
end

function evaluation:mobilityBishop(board,rank, file, side)
    local eval = 0
    for rankDirection = -1, 1, 2 do
        for fileDirection = -1, 1, 2 do
            local newRank = rank + rankDirection
            local newFile = file + fileDirection
            while board:isInsideBoard(newRank, newFile) do
                if board:isEmpty(newRank, newFile) then
                    eval = eval + 10
                elseif board:isEnemyPiece(newRank, newFile, side) then
                    eval = eval + 20
                    break
                else
                    break
                end
                newRank = newRank + rankDirection
                newFile = newFile + fileDirection
            end
        end
    end
    return eval
end

function evaluation:mobilityRook(board,rank, file, side)
    local eval = 0
    -- Movimientos horizontales (izquierda y derecha)
    for direction = -1, 1, 2 do
        local newFile = file + direction
        while board:isInsideBoard(rank, newFile) do
            if board:isEmpty(rank, newFile) then
                eval = eval + 8 -- Se evalua la movilidad horizontal un poco menor que la vertical
            elseif board:isEnemyPiece(rank, newFile, side) then
                eval = eval + 20
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
        while board:isInsideBoard(newRank, file) do
            if board:isEmpty(newRank, file) then
                eval = eval + 10
            elseif board:isEnemyPiece(newRank, file, side) then
                eval = eval + 20
                break
            else
                break
            end
            newRank = newRank + direction
        end
    end
    return eval
end

function evaluation:eval(board,turn,test)
    if test == nil then
        test = false
    end
    local TotalPhase = evaluation.TotalPhase
    local opening,endgame,phase = 0,0,TotalPhase
    local piece,material,mobility,kingSafety,doubledPawn,isolatedPawn,blockedPawn = 0,0,0,0,0,0,0
    for rank = board.RANK_1, board.RANK_8 do
        for file = board.FILE_A, board.FILE_H do
            piece = board.mailbox[rank][file]
            material = material + evaluation.material[piece]
            if piece == board.W_PAWN or piece == board.B_PAWN then
                phase = phase - self.PawnPhase
                doubledPawn = doubledPawn + self:doubledPawn(board,piece,rank,file)
                isolatedPawn = isolatedPawn + self:isolatedPawn(board,piece,file)
                blockedPawn = blockedPawn + self:blockedPawn(board,piece,rank,file)
            elseif piece == board.W_KNIGHT then
                phase = phase - self.KnightPhase
                mobility = mobility + self:mobilityKnight(board,rank,file,board.WHITE_TO_MOVE)
            elseif piece == board.B_KNIGHT then
                phase = phase - self.KnightPhase
                mobility = mobility - self:mobilityKnight(board,rank,file,board.BLACK_TO_MOVE)
            elseif piece == board.W_BISHOP then
                phase = phase - self.BishopPhase
                mobility = mobility + self:mobilityBishop(board,rank,file,board.WHITE_TO_MOVE)
            elseif piece == board.B_BISHOP then
                phase = phase - self.BishopPhase
                mobility = mobility - self:mobilityBishop(board,rank,file,board.BLACK_TO_MOVE)
            elseif piece == board.W_ROOK then
                phase = phase - self.RookPhase
                mobility = mobility + self:mobilityRook(board,rank,file,board.WHITE_TO_MOVE)
            elseif piece == board.B_ROOK then
                phase = phase - self.RookPhase
                mobility = mobility - self:mobilityRook(board,rank,file,board.BLACK_TO_MOVE)
            elseif piece == board.W_KING then
                kingSafety = kingSafety - self:mobilityBishop(board,rank,file,board.WHITE_TO_MOVE) -
                    self:mobilityRook(board,rank,file,board.WHITE_TO_MOVE)
            elseif piece == board.B_KING then
                kingSafety = kingSafety + self:mobilityBishop(board,rank,file,board.BLACK_TO_MOVE) +
                    self:mobilityRook(board,rank,file,board.BLACK_TO_MOVE)
            elseif piece == board.W_QUEEN or piece == board.B_QUEEN then
                phase = phase - self.QueenPhase
            end
        end
    end

    opening = material + doubledPawn + isolatedPawn + blockedPawn + mobility + kingSafety
    endgame = material + doubledPawn + isolatedPawn + blockedPawn + mobility
    phase = math.floor((phase * 256 + (TotalPhase / 2)) / TotalPhase)
    local eval = ((opening * (256 - phase)) + (endgame * phase)) / 256
    if test then
        board:print()
        print("opening",opening)
        print("endgame",endgame)
        print("phase",phase)
        print("material",material)
        print("doubled pawn",doubledPawn)
        print("isolatedPawn", isolatedPawn)
        print("blocked pawn",blockedPawn)
        print("mobility", mobility)
        print("king Safety", kingSafety)
        print("eval",eval)
    end
    return eval * turn
end

return evaluation