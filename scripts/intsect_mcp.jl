using ModelContextProtocol
using JSON
using Dates
using Intsect

# Shared state for the hive board
mutable struct HiveState
    board::Union{Board,Nothing}
end

const HIVE_STATE = HiveState(nothing)

# Helper to convert gametype string to type
function get_gametype(type_str::String)
    type_str = strip(type_str)
    if type_str == "Base+MLP" || type_str == ""
        return MLPGame
    elseif type_str == "Base+M"
        return MGame
    elseif type_str == "Base+P"
        return PGame
    elseif type_str == "Base+L"
        return LGame
    elseif type_str == "Base+ML"
        return MLGame
    elseif type_str == "Base+MP"
        return MPGame
    elseif type_str == "Base+LP"
        return LPGame
    elseif type_str == "Base"
        return BaseGame
    else
        return MLPGame
    end
end

# Tool: Start a new game
new_game_tool = MCPTool(;
    name="new_game",
    description="Start a new hive game. You must always start a hive game before making any moves or querying the board state.",
    parameters=[
        ToolParameter(;
            name="type",
            type="string",
            description="The type of game to start. Must be one of: Base+MLP Base+M Base+P Base+L Base+ML Base+MP Base+LP Base. Default is Base+MLP.",
            required=false,
        ),
        ToolParameter(;
            name="gamestring",
            type="string",
            description="A gamestring in UHP format to initialize the board to a specific state. If provided, this will override the 'type' parameter.",
            required=false,
        ),
    ],
    handler=params -> begin
        gs_str = get(params, "gamestring", nothing)
        if gs_str !== nothing
            try
                HIVE_STATE.board = from_game_string(gs_str)
                return TextContent(;
                    text=JSON.json(
                        Dict(
                            "status" => "ok",
                            "message" => "New game started from gamestring",
                            "current_player" =>
                                HIVE_STATE.board.current_color == WHITE ? "White" : "Black",
                            "turn" => HIVE_STATE.board.turn,
                        ),
                    ),
                )
            catch e
                return TextContent(; text=JSON.json(Dict("error" => "Invalid gamestring: $(e)")))
            end
        end
        gametype_str = get(params, "type", "Base+MLP")
        gametype = get_gametype(gametype_str)
        HIVE_STATE.board = handle_newgame_command(gametype)
        TextContent(;
            text=JSON.json(
                Dict(
                    "status" => "ok",
                    "message" => "New game started",
                    "gametype" => gametype_str,
                    "current_player" =>
                        HIVE_STATE.board.current_color == WHITE ? "White" : "Black",
                    "turn" => HIVE_STATE.board.turn,
                ),
            ),
        )
    end,
)

# Tool: Make a move
make_move_tool = MCPTool(;
    name="make_move",
    description="Make a move on the hive board. The move string format follows standard Hive notation: 'wA1' to place white ant 1 in the center (first move), 'bG1 wA1-' to place black grasshopper 1 to the east of white ant 1, 'wQ -bG1' to place white queen to the west of black grasshopper 1, etc. Use 'pass' if no moves are available.",
    parameters=[
        ToolParameter(;
            name="move",
            type="string",
            description="The move string in Hive notation (e.g., 'wA1', 'bG1 wA1-', 'wQ -bG1', 'pass')",
            required=true,
        ),
    ],
    handler=params -> begin
        if HIVE_STATE.board === nothing
            return TextContent(;
                text=JSON.json(Dict("error" => "No game started. Use new_game first."))
            )
        end
        move_str = params["move"]
        try
            do_action(HIVE_STATE.board, move_str)
            TextContent(;
                text=JSON.json(
                    Dict(
                        "status" => "ok",
                        "move" => move_str,
                        "current_player" =>
                            HIVE_STATE.board.current_color == WHITE ? "White" : "Black",
                        "turn" => HIVE_STATE.board.turn,
                        "gameover" => HIVE_STATE.board.gameover,
                        "victor" =>
                            HIVE_STATE.board.gameover ?
                            (
                                HIVE_STATE.board.victor == Integer(WHITE) ? "White" :
                                (HIVE_STATE.board.victor == Integer(BLACK) ? "Black" : "Draw")
                            ) : nothing,
                    ),
                ),
            )
        catch e
            TextContent(; text=JSON.json(Dict("error" => string(e))))
        end
    end,
)

# Tool: Get valid moves
valid_moves_tool = MCPTool(;
    name="valid_moves",
    description="Get all valid moves for the current position. Returns a list of move strings that can be played.",
    parameters=[],
    handler=params -> begin
        if HIVE_STATE.board === nothing
            return TextContent(;
                text=JSON.json(Dict("error" => "No game started. Use new_game first."))
            )
        end
        actions = validactions(HIVE_STATE.board)
        move_strings = String[]
        for action in actions
            push!(move_strings, move_string_from_action(HIVE_STATE.board, action))
        end
        TextContent(;
            text=JSON.json(
                Dict(
                    "status" => "ok",
                    "valid_moves" => move_strings,
                    "count" => length(move_strings),
                ),
            ),
        )
    end,
)

# Tool: Get game string (UHP format)
game_string_tool = MCPTool(;
    name="game_string",
    description="Get the game string in Universal Hive Protocol (UHP) format. This can be used to save/restore game state. This documents the game state",
    parameters=[],
    handler=params -> begin
        if HIVE_STATE.board === nothing
            return TextContent(;
                text=JSON.json(Dict("error" => "No game started. Use new_game first."))
            )
        end
        gamestring = GameString(HIVE_STATE.board)
        TextContent(; text=JSON.json(Dict("gamestring" => gamestring)))
    end,
)

# Tool: Get best move (AI)
best_move_tool = MCPTool(;
    name="best_move",
    description="Get the AI's recommended best move for the current position.",
    parameters=[
        ToolParameter(;
            name="time_s",
            type="number",
            description="search time in seconds (default 5). Higher values take longer but may find better moves.",
            required=false,
        ),
    ],
    handler=params -> begin
        if HIVE_STATE.board === nothing
            return TextContent(;
                text=JSON.json(Dict("error" => "No game started. Use new_game first."))
            )
        end
        time_s = get(params, "time_s", 5)
        try
            best_action = get_best_move(HIVE_STATE.board; time_limit_s=time_s, debug=false)
            move_str = move_string_from_action(HIVE_STATE.board, best_action)
            TextContent(; text=JSON.json(Dict("status" => "ok", "best_move" => move_str)))
        catch e
            TextContent(; text=JSON.json(Dict("error" => string(e))))
        end
    end,
)

# Create and start server with all tools
server = mcp_server(;
    name="intsect-server",
    description="MCP server for the Intsect Hive engine - play and analyze Hive games",
    tools=[new_game_tool, make_move_tool, valid_moves_tool, game_string_tool, best_move_tool],
)

# Start the server
start!(server)