#pragma once

#include "intsect/board.hpp"

#include <string>

namespace intsect {

// Recursive perft function - implemented in perft.cpp (not inlined due to recursion)
size_t perft(Board& board, int depth);

void perft_with_output(Board& board, int depth);

void perft(int depth, std::string movestring);

} // namespace intsect