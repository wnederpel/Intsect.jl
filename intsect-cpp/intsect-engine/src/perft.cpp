#include "intsect/perft.hpp"

#include "intsect/board.hpp"
#include "intsect/game_string.hpp"
#include "intsect/move_generation.hpp"

#include <chrono>
#include <iostream>
#include <string>
#include <vector>

namespace intsect {

namespace {

std::string format_with_thousands_sep(size_t value) {
    std::string digits = std::to_string(value);
    const int insert_from = static_cast<int>(digits.size()) - 3;
    for (int i = insert_from; i > 0; i -= 3) {
        digits.insert(static_cast<size_t>(i), ".");
    }
    return digits;
}

struct PerftContext {
    std::vector<std::array<Action, VALID_BUFFER_SIZE>> action_buffers;

    explicit PerftContext(int max_depth) : action_buffers(static_cast<size_t>(max_depth) + 1u) {}
};

size_t perft_impl(Board& board, int depth, PerftContext& context) {
    if (depth <= 0) {
        return 1;
    }

    auto& action_buffer = context.action_buffers[static_cast<size_t>(depth)];
    get_valid_actions_into(board, action_buffer);
    const int action_count = board.action_index;

    if (depth == 1)
        return static_cast<size_t>(action_count);

    size_t total = 0;
    for (int i = 0; i < action_count; ++i) {
        const Action& action = action_buffer[static_cast<size_t>(i)];
        bool s = board.do_action(action);
        total += perft_impl(board, depth - 1, context);
        s &= board.undo();

        if (!s) {
            std::cout << "Some action was invalid";
            return (size_t)-1;
        }
    }
    return total;
}

} // namespace

// Pass by reference for efficiency and to follow standard minimax/perft pattern.
// The board state is modified in place (do_action), explored recursively, then restored (undo).
size_t perft(Board& board, int depth) {
    if (depth <= 0)
        return 1;

    PerftContext context(depth);
    return perft_impl(board, depth, context);
}

void perft_with_output(Board& board, int depth) {
    if (depth <= 0)
        return;

    PerftContext context(depth);
    for (int i = 1; i <= depth; ++i) {
        const auto start = std::chrono::steady_clock::now();
        const size_t result = perft_impl(board, i, context);
        const auto elapsed = std::chrono::steady_clock::now() - start;
        const double seconds = std::chrono::duration<double>(elapsed).count();
        const double kilo_nodes_per_second =
            (seconds > 0.0) ? static_cast<double>(result) / seconds / 1000.0 : 0.0;
        const size_t knps_rounded = static_cast<size_t>(kilo_nodes_per_second + 0.5);

        std::cout << "perft(" << i << ") = " << format_with_thousands_sep(result) << "\n"
                  << "  time = " << seconds << " s, "
                  << "speed = " << format_with_thousands_sep(knps_rounded) << " KN/s\n";
    }
}

void perft(int depth, std::string s) {
    Board board = parse_game_string(s);
    perft_with_output(board, depth);
}

} // namespace intsect
