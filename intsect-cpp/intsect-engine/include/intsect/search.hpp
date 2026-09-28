#include "intsect/board.hpp"

namespace intsect {

struct SearchConstants {
    // Constants that are relevant to the search but are static during the search
};

struct SearchVariables {
    // Variables that are relevant to the search and will vary over the search
    int depth;
    float alpha;
    float beta;
};

Action get_best_action(Board& board, float time_limit_s);

Action timed_iterative_deepening(Board& board, float time_limit_s);

Action iterative_deepening(bool time_out, Board& board);

} // namespace intsect