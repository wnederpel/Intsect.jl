#include "perft_diff.hpp"

#include <cassert>
#include <doctest/doctest.h>
#include <string>

namespace {

void run_perft_diff_case(const std::string& position, int depth) {
    intsect::tools::Options opts;

    const auto oracle = intsect::tools::resolve_default_oracle_path(nullptr);
    if (!oracle.has_value()) {
        DOCTEST_WARN("Skipping perft diff parity test: oracle executable not found");
        return;
    }

    opts.oracle_path = oracle->string();
    opts.position = position;
    opts.depth = depth;

    const int rc = intsect::tools::run_perft_compare(opts);
    CHECK(rc == 0);
}

} // namespace

TEST_CASE("perft diff: diff test 1") {
    run_perft_diff_case(
        "Base+MLP;InProgress;white[10];wP;bM wP-;wQ /wP;bQ bM/;wQ wP\\;bA1 bQ\\;wQ -bQ;bA2 "
        "bQ/;wQ -bA2",
        4);
}

TEST_CASE("perft diff: diff test 2") {
    run_perft_diff_case(
        "Base+MLP;InProgress;white[5];wL;bL wL\\;wM \\wL;bM bL\\;wA1 /wM;bA1 /bL;wQ "
        "wM/;bQ bM-;wA2 wQ\\;bA2 bA1\\;wA2 /bA2;bA1 /wA1;wB1 wQ\\;bP bA2-;wM wQ;bA1 "
        "\\wM",
        4);
}

TEST_CASE("perft diff: diff test 3") {
    run_perft_diff_case(
        "Base+MLP;InProgress;white[5];wL;bL wL\\;wM \\wL;bM bL\\;wA1 /wM;bA1 /bL;wQ "
        "wM/;bQ bM-;wA2 wQ\\;bA2 bA1\\;wA2 /bA2;bA1 /wA1;wB1 wQ\\;bP bA2-;wM wQ;bA1 "
        "\\wM;wP wB1/;bA3 bA1/",
        4);
}

TEST_CASE("perft diff: diff test 4") {
    run_perft_diff_case(
        "Base+MLP;InProgress;white[5];wL;bL wL\\;wM \\wL;bM bL\\;wA1 /wM;bA1 /bL;wQ "
        "wM/;bQ bM-;wA2 wQ\\;bA2 bA1\\;wA2 /bA2;bA1 /wA1;wB1 wQ\\;bP bA2-;wM wQ;bA1 "
        "\\wM;wP wB1/;bA3 bA1/;wM /bA1",
        4);
}

TEST_CASE("perft diff: diff test 5") {
    run_perft_diff_case(
        "Base+MLP;InProgress;white[11];wB1;bS1 wB1-;wQ /wB1;bQ bS1/;wG1 -wB1;bG1 bS1-;wM "
        "-wQ;bM bQ-;wP /wQ;bP bQ/;wL -wG1;bL bG1-;wA1 wQ\\;bB1 \\bQ;wS1 wA1-;bA1 "
        "-bB1;wA2 -wP;bA2 bP-;wA2 wS1/;bA2 /bA1",
        4);
}

TEST_CASE("perft diff: diff test 6") {
    run_perft_diff_case(
        "Base+MLP;InProgress;White[10];wS1;bS1 wS1-;wQ -wS1;bQ bS1\\;wB1 -wQ;bB1 bQ-;wB1 "
        "wQ;bA1 bS1-;wM -wB1;bP bA1-;wL \\wB1;bL bP-;wP \\wL;bM bL-;wA1 -wP;bG1 "
        "bP\\;wA1 wP-;bB1 bA1;wA2 wB1\\;bB1 bS1;wA3 wB1/;bG2 bB1/;wB1 wA3;bM bQ-;wL "
        "-wA2",
        4);
}

TEST_CASE("perft diff: diff test 7") {
    run_perft_diff_case("Base+MLP;InProgress;White[10];wA1;bA1 wA1-;wQ -wA1;bQ bA1-;wB1 /wA1;bB1 "
                        "bA1\\;wB2 \\wA1;bB2 bA1/;wB1 wA1;bB1 bA1;wB2 wB1;bG1 bB1\\;wB2 bB1;bB2 "
                        "wB2;wB1 bB2;bA2 bQ-;wL wQ/;bL /bG1;wA2 -wQ;bA3 bQ/;wB1 bQ",
                        4);
}

TEST_CASE("perft diff: diff test 8") {
    run_perft_diff_case(
        "Base+MLP;InProgress;White[10];wA1;bA1 wA1-;wQ -wA1;bQ bA1-;wB1 wQ\\;bB1 "
        "bA1\\;wB2 \\wA1;bB2 \\bQ;wB1 wA1;bB1 bA1;wB2 wB1;bG1 bB1\\;wB2 bB1;bB2 "
        "wB2;wB1 bB2;bA2 bQ-;wL \\wA1;bL /bG1;wA2 -wQ;bA3 \\bA2;wB1 bQ;bB2 wA1/;wA2 "
        "\\wL;bL bG1-;wQ /wA1",
        4);
}

TEST_CASE("perft diff: diff test 9") {
    run_perft_diff_case(
        "Base+MLP;InProgress;white[5];wL;bL wL\\;wM \\wL;bM bL\\;wA1 /wM;bA1 /bL;wQ "
        "wM/;bQ bM-;wA2 wQ\\;bA2 bA1\\;wA2 /bA2;bA1 /wA1;wB1 wQ\\;bP bA2-;wM wB1\\;bB1 "
        "\\bA2;wA3 -wQ;bS1 /bA1;wA3 -bS1",
        4);
}

TEST_CASE("perft diff: diff test 10 - draws") {
    run_perft_diff_case(
        "Base+MLP;InProgress;white[5];wL;bL wL\\;wM \\wL;bM bL\\;wA1 /wM;bA1 /bL;wQ "
        "wM/;bQ bM-;wA2 wQ\\;bA2 bA1\\;wA2 /bA2;bA1 /wA1;wB1 wQ\\;bP bA2-;wM wB1\\;bB1 "
        "\\bA2;wA3 -wQ;bS1 /bA1;wA3 -bS1;bQ bP-;wQ -wB1;bQ bM-;wQ \\wB1;bQ bP-;wQ "
        "-wB1;bQ bM-",
        4);
}

TEST_CASE("perft diff: diff test 10 - draws") {
    // TODO: speed up these tests, use vtune for profiling memory and performance. Test case 4 takes
    // 22 secs for example. test 1 takes 5, test 5 takes 55 seconds!, test 8 takes 4 seconds, maybe
    // that's an easy target to start with. All tests pass tho so that's amazing!
    assert(false);
}