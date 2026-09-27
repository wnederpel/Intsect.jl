// Standalone developer tools entrypoint.
// A cross-engine perft comparator that treats one external
// executable as ground truth and drills down to the deepest mismatch.

#include "intsect/game_string.hpp"
#include "intsect/perft.hpp"
#include "intsect/version.hpp"
#include "perft_diff.hpp"

#include <iostream>
#include <vector>

#if defined(_WIN32)
#define INTSECT_POPEN _popen
#define INTSECT_PCLOSE _pclose
#else
#define INTSECT_POPEN popen
#define INTSECT_PCLOSE pclose
#endif

void print_usage() {
    std::cout << "intsect-tools " << intsect::version() << "\n\n"
              << "Usage:\n"
              << "  intsect-tools perft-compare [--position <GameString>] [--depth <N>]\n"
              << "                             [--oracle-path <path>]\n"
              << "  or intsect-tools perft-test [--position <GameString>] [--depth <N>]\n"
              << "\n"
              << "Defaults:\n"
              << "  --position   Base+MLP;InProgress;White[1]\n"
              << "  --depth      4\n"
              << "  --oracle-path engines/nokamute(.exe) auto-discovered\n";
}

[[nodiscard]] bool parse_cli(int argc, char** argv, intsect::tools::Options& out) {
    if (argc <= 1) {
        print_usage();
        return false;
    }

    const std::string cmd = argv[1];
    if (cmd != "perft-compare" && cmd != "perft-test") {
        print_usage();
        return false;
    }

    for (int i = 2; i < argc; ++i) {
        const std::string arg = argv[i];
        if (arg == "--position" && i + 1 < argc) {
            out.position = argv[++i];
        } else if (arg == "--depth" && i + 1 < argc) {
            out.depth = std::max(1, std::atoi(argv[++i]));
        } else if (arg == "--oracle-path" && i + 1 < argc) {
            out.oracle_path = argv[++i];
        } else if (arg == "--help" || arg == "-h") {
            print_usage();
            return false;
        } else {
            std::cerr << "Unknown argument: " << arg << "\n";
            print_usage();
            return false;
        }
    }

    return true;
}

int main(int argc, char** argv) {
    intsect::tools::Options opts;

    if (!parse_cli(argc, argv, opts))
        return 1;

    const std::string cmd = argv[1];

    if (cmd == "perft-compare") {
        if (opts.oracle_path.empty()) {
            const auto resolved =
                intsect::tools::resolve_default_oracle_path(argc > 0 ? argv[0] : nullptr);
            if (!resolved.has_value()) {
                std::cerr << "Could not auto-discover nokamute executable. Use --oracle-path.\n";
                return 1;
            }
            opts.oracle_path = resolved->string();
        }

        return intsect::tools::run_perft_compare(opts);
    } else if (cmd == "perft-test") {
        intsect::Board board = intsect::parse_game_string(opts.position);
        intsect::perft_with_output(board, opts.depth);
    }
}
