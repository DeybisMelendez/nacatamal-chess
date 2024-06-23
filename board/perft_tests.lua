local board = require "board.Board"

local function run_perft_tests(fen, tests)
    board:parseFEN(fen)
    for _, test in ipairs(tests) do
        local depth, expected_result = test.depth, test.result
        local result = board:perft(depth)
        if result == expected_result then
            print("La profundidad " .. depth .. " se ha realizado con éxito")
        else
            print("Error en la profundidad " .. depth .. ", se esperaba:", expected_result, "pero se obtuvo:", result)
        end
    end
end

local test_cases = {
    {
        description = "--- Posición inicial ---",
        fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
        tests = {
            {depth = 1, result = 20},
            {depth = 2, result = 400},
            {depth = 3, result = 8902},
            {depth = 4, result = 197281},
            -- {depth = 5, result = 4865609},
        }
    },
    {
        description = "--- Kiwipete ---",
        fen = "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - ",
        tests = {
            {depth = 1, result = 48},
            {depth = 2, result = 2039},
            {depth = 3, result = 97862},
            -- {depth = 4, result = 4085603},
        }
    },
    {
        description = "--- Position 3 ---",
        fen = "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - ",
        tests = {
            {depth = 1, result = 14},
            {depth = 2, result = 191},
            {depth = 3, result = 2812},
            {depth = 4, result = 43238},
            {depth = 5, result = 674624},
        }
    },
    {
        description = "--- Position 4 ---",
        fen = "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1",
        tests = {
            {depth = 1, result = 6},
            {depth = 2, result = 264},
            {depth = 3, result = 9467},
            {depth = 4, result = 422333},
        }
    },
    {
        description = "--- Position 4 Colores invertidos ---",
        fen = "r2q1rk1/pP1p2pp/Q4n2/bbp1p3/Np6/1B3NBn/pPPP1PPP/R3K2R b KQ - 0 1 ",
        tests = {
            {depth = 1, result = 6},
            {depth = 2, result = 264},
            {depth = 3, result = 9467},
            {depth = 4, result = 422333},
        }
    },
    {
        description = "--- Position 5 ---",
        fen = "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8",
        tests = {
            {depth = 1, result = 44},
            {depth = 2, result = 1486},
            {depth = 3, result = 62379},
            --{depth = 4, result = 2103487},
        }
    },
    {
        description = "--- Position 6 ---",
        fen = "r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10",
        tests = {
            {depth = 1, result = 46},
            {depth = 2, result = 2079},
            {depth = 3, result = 89890},
            --{depth = 4, result = 3894594},
        }
    },
    {
        description = "--- Prueba de personalizada ---",
        fen = "8/2p5/3p4/KP5r/1R2Pp1k/8/6P1/8 b - - 0 1",
        tests = {
            {depth = 1, result = 16}
        }
    },
}

for _, case in ipairs(test_cases) do
    print(case.description)
    run_perft_tests(case.fen, case.tests)
end
