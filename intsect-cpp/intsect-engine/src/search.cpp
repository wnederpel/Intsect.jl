
#include "intsect/search.hpp"

#include "intsect/board.hpp"
#include "intsect/game_string.hpp"
#include "intsect/move_generation.hpp"

#include <chrono>
#include <iostream>
#include <thread>

namespace intsect {

Action get_best_action(Board& board, float time_limit_s) {
    return timed_iterative_deepening(board, time_limit_s);
}

Action timed_iterative_deepening(Board& board, float time_limit_s) {
    bool time_out;
    bool done_computing = false;
    Action best_action = Action();

    std::thread t([&time_out, &done_computing, &best_action, &board]() {
        best_action = iterative_deepening(time_out, board);
        std::string action_string = intsect::move_string_from_action(board, best_action);
        std::cout << "Best move = " << action_string << "\n";

        done_computing = true;
    });

    t.detach();

    {
        std::this_thread::sleep_for(std::chrono::duration<float>(time_limit_s));
        time_out = true;
    }

    while (true) {
        if (done_computing) {
            return best_action;
        }
    }

    return best_action;
}

struct ActionBuffers {
    std::vector<std::array<Action, VALID_BUFFER_SIZE>> action_buffers;

    explicit ActionBuffers(int max_depth) : action_buffers(static_cast<size_t>(max_depth) + 1u) {}
};

Action iterative_deepening(bool time_out, Board& board) {
    while (true) {
        if (time_out) {
            auto action_buffers = ActionBuffers(1);
            auto& action_buffer = action_buffers.action_buffers[0];
            get_valid_actions_into(board, action_buffer);

            return action_buffer[0];
        }
    }
    return Action();
}

} // namespace intsect