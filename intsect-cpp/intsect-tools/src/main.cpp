// Standalone developer tools entrypoint.
// A cross-engine perft comparator that treats one external
// executable as ground truth and drills down to the deepest mismatch.

#include "perft_diff.hpp"

#include <iostream>

#if defined(_WIN32)
#define INTSECT_POPEN _popen
#define INTSECT_PCLOSE _pclose
#else
#define INTSECT_POPEN popen
#define INTSECT_PCLOSE pclose
#endif

int main(int argc, char** argv) {
    intsect::tools::Options opts;

    if (!intsect::tools::parse_cli(argc, argv, opts))
        return 1;

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
}
