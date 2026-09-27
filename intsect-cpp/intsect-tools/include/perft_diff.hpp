#pragma once

#include <filesystem>
#include <optional>
#include <string>

namespace intsect::tools {

struct Options {
    std::string oracle_path;
    std::string position = "Base+MLP;InProgress;White[1]";
    int depth = 4;
};

void print_usage();

[[nodiscard]] std::optional<std::filesystem::path> resolve_default_oracle_path(char* argv0);

[[nodiscard]] int run_perft_compare(const Options& opts);

} // namespace intsect::tools
