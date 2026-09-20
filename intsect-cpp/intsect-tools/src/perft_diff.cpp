// Perft diff implementation shared by tools executable and tests.

#include "perft_diff.hpp"

#include "intsect/game_string.hpp"
#include "intsect/move_generation.hpp"
#include "intsect/perft.hpp"
#include "intsect/version.hpp"

#include <array>
#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <optional>
#include <regex>
#include <set>
#include <sstream>
#include <string>
#include <string_view>
#include <vector>

#if defined(_WIN32)
#define INTSECT_POPEN _popen
#define INTSECT_PCLOSE _pclose
#else
#define INTSECT_POPEN popen
#define INTSECT_PCLOSE pclose
#endif

namespace intsect::tools {

using intsect::Action;
using intsect::Board;

struct ActionLess {
    bool operator()(const Action& a, const Action& b) const noexcept {
        if (a.kind != b.kind)
            return a.kind < b.kind;
        if (a.from != b.from)
            return a.from < b.from;
        if (a.to != b.to)
            return a.to < b.to;
        return a.tile < b.tile;
    }
};

struct DiffSummary {
    std::set<Action, ActionLess> missing_from_cpp;
    std::set<Action, ActionLess> extra_in_cpp;
    std::vector<std::string> unparsable_oracle_moves;
};

[[nodiscard]] std::string quote_arg(const std::string& s) {
    std::string out;
    out.reserve(s.size() + 2);
    out.push_back('"');
    for (char ch : s) {
        if (ch == '"')
            out += "\\\"";
        else
            out.push_back(ch);
    }
    out.push_back('"');
    return out;
}

[[nodiscard]] std::string quote_bash_single(const std::string& s) {
    std::string out;
    out.reserve(s.size() + 2);
    out.push_back('\'');
    for (char ch : s) {
        if (ch == '\'')
            out += "'\\''";
        else
            out.push_back(ch);
    }
    out.push_back('\'');
    return out;
}

[[nodiscard]] std::string to_slash_path(std::string path) {
    for (char& ch : path) {
        if (ch == '\\')
            ch = '/';
    }
    return path;
}

[[nodiscard]] std::string trim(std::string s) {
    while (!s.empty() && std::isspace(static_cast<unsigned char>(s.front())))
        s.erase(s.begin());
    while (!s.empty() && std::isspace(static_cast<unsigned char>(s.back())))
        s.pop_back();
    return s;
}

[[nodiscard]] std::vector<std::string> split_semicolon(const std::string& line) {
    std::vector<std::string> out;
    std::istringstream iss(line);
    std::string token;
    while (std::getline(iss, token, ';')) {
        token = trim(token);
        if (!token.empty())
            out.push_back(token);
    }
    return out;
}

[[nodiscard]] std::string run_command_capture(const std::string& command) {
    std::array<char, 4096> buffer{};
    std::string output;

    FILE* pipe = INTSECT_POPEN(command.c_str(), "r");
    if (pipe == nullptr)
        return output;

    while (std::fgets(buffer.data(), static_cast<int>(buffer.size()), pipe) != nullptr) {
        output += buffer.data();
    }
    (void)INTSECT_PCLOSE(pipe);
    return output;
}

[[nodiscard]] size_t next_oracle_script_id() {
    static size_t script_id = 0;
    ++script_id;
    return script_id;
}

[[nodiscard]] std::optional<std::string>
run_oracle_session(const std::string& oracle_path, const std::vector<std::string>& commands) {
    std::error_code ec;
    const auto script_name =
        "intsect_oracle_uhp_" + std::to_string(next_oracle_script_id()) + ".txt";
    // Use a tmp file as standard in for ease of use.
    const auto script_path = std::filesystem::temp_directory_path(ec) / script_name;
    if (ec)
        return std::nullopt;

    {
        std::ofstream script(script_path);
        if (!script)
            return std::nullopt;
        for (const auto& cmd : commands)
            script << cmd << "\n";
    }

    std::string shell_command;
#if defined(_WIN32)
    const std::string oracle_bash = to_slash_path(oracle_path);
    const std::string script_bash = to_slash_path(script_path.string());
    const std::string bash_inner =
        quote_bash_single(oracle_bash) + " < " + quote_bash_single(script_bash);
    shell_command = "bash -lc " + quote_arg(bash_inner);
#else
    shell_command = quote_arg(oracle_path) + " < " + quote_arg(script_path.string());
#endif

    std::cout << "[oracle-shell] " << shell_command << "\n";
    for (const auto& cmd : commands)
        std::cout << "[oracle-stdin] " << cmd << "\n";

    const std::string output = run_command_capture(shell_command);
    std::filesystem::remove(script_path, ec);

    if (output.empty())
        return std::nullopt;
    return output;
}

[[nodiscard]] std::optional<std::filesystem::path> resolve_default_oracle_path(char* argv0) {
    const std::vector<std::string> names = {
#if defined(_WIN32)
        "nokamute.exe",
#else
        "nokamute",
#endif
        "nokamute"};

    std::vector<std::filesystem::path> bases;
    bases.push_back(std::filesystem::current_path());
    if (argv0 != nullptr) {
        std::error_code ec;
        const std::filesystem::path exe = std::filesystem::absolute(argv0, ec);
        if (!ec)
            bases.push_back(exe.parent_path());
    }

    for (const auto& base : bases) {
        for (int up = 0; up < 8; ++up) {
            std::filesystem::path root = base;
            for (int i = 0; i < up; ++i)
                root = root.parent_path();
            for (const auto& name : names) {
                const auto candidate = root / "engines" / name;
                std::error_code ec;
                if (std::filesystem::exists(candidate, ec) && !ec)
                    return candidate;
            }
        }
    }

    return std::nullopt;
}

void print_usage() {
    std::cout << "intsect-tools " << intsect::version() << "\n\n"
              << "Usage:\n"
              << "  intsect-tools perft-compare [--position <GameString>] [--depth <N>]\n"
              << "                             [--oracle-path <path>]\n\n"
              << "Defaults:\n"
              << "  --position   Base+MLP;InProgress;White[1]\n"
              << "  --depth      4\n"
              << "  --oracle-path engines/nokamute(.exe) auto-discovered\n";
}

[[nodiscard]] bool parse_cli(int argc, char** argv, Options& out) {
    if (argc <= 1) {
        print_usage();
        return false;
    }

    const std::string cmd = argv[1];
    if (cmd != "perft-compare") {
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

[[nodiscard]] std::optional<size_t> oracle_perft_count(const std::string& oracle_path,
                                                       const std::string& game_string, int depth) {
    const auto output = run_oracle_session(
        oracle_path, {"newgame " + game_string, "perft " + std::to_string(depth)});
    if (!output.has_value())
        return std::nullopt;

    const std::regex line_re(R"(^\s*(\d+)\s+(\d+)\b)", std::regex::ECMAScript);
    std::istringstream iss(*output);
    std::string line;

    while (std::getline(iss, line)) {
        std::smatch match;
        if (!std::regex_search(line, match, line_re) || match.size() < 3)
            continue;

        const int parsed_depth = std::stoi(match[1].str());
        if (parsed_depth == depth)
            return static_cast<size_t>(std::stoull(match[2].str()));
    }

    return std::nullopt;
}

[[nodiscard]] std::optional<std::vector<std::string>>
oracle_valid_moves(const std::string& oracle_path, const std::string& game_string) {
    const auto output = run_oracle_session(oracle_path, {"newgame " + game_string, "validmoves"});
    if (!output.has_value())
        return std::nullopt;

    std::vector<std::string> moves;
    std::istringstream iss(*output);
    std::string line;
    int seen_ok = 0;
    while (std::getline(iss, line)) {
        line = trim(line);
        if (line.empty())
            continue;

        if (line == "ok") {
            ++seen_ok;
            continue;
        }
        if (seen_ok < 2)
            continue;

        auto parts = split_semicolon(line);
        moves.insert(moves.end(), parts.begin(), parts.end());
    }

    if (moves.empty())
        return std::nullopt;
    return moves;
}

[[nodiscard]] DiffSummary compare_valid_moves_internal(const std::string& oracle_path,
                                                       const std::string& game_string,
                                                       Board& board) {
    DiffSummary summary;

    const auto maybe_moves = oracle_valid_moves(oracle_path, game_string);
    if (!maybe_moves.has_value())
        return summary;

    std::set<Action, ActionLess> oracle_actions;
    for (const auto& move : maybe_moves.value()) {
        const auto parsed = intsect::action_from_move_string(board, move);
        if (!parsed.has_value()) {
            summary.unparsable_oracle_moves.push_back(move);
            continue;
        }
        oracle_actions.insert(*parsed);
    }

    std::array<Action, intsect::VALID_BUFFER_SIZE> cpp_buffer{};
    intsect::get_valid_actions_into(board, cpp_buffer);
    std::set<Action, ActionLess> cpp_actions;
    for (int i = 0; i < board.action_index; ++i)
        cpp_actions.insert(cpp_buffer[static_cast<size_t>(i)]);

    for (const auto& a : oracle_actions) {
        if (!cpp_actions.contains(a))
            summary.missing_from_cpp.insert(a);
    }
    for (const auto& a : cpp_actions) {
        if (!oracle_actions.contains(a))
            summary.extra_in_cpp.insert(a);
    }

    return summary;
}

void print_action_set(const std::string_view label, const std::set<Action, ActionLess>& actions,
                      const Board& board) {
    if (actions.empty()) {
        std::cout << label << ": none\n";
        return;
    }
    std::cout << label << ":\n";
    for (const auto& a : actions) {
        std::cout << "  " << intsect::move_string_from_action(board, a) << "\n";
    }
}

void report_leaf_mismatch(const std::string& oracle_path, const std::string& game_string,
                          Board& board, size_t my_nodes, size_t oracle_nodes) {
    std::cout << "\nLeaf mismatch at depth 1\n";
    std::cout << "Position: " << game_string << "\n";
    std::cout << "C++ perft(1): " << my_nodes << "\n";
    std::cout << "Oracle perft(1): " << oracle_nodes << "\n";

    const DiffSummary diff = compare_valid_moves_internal(oracle_path, game_string, board);
    print_action_set("Missing from C++", diff.missing_from_cpp, board);
    print_action_set("Extra in C++", diff.extra_in_cpp, board);

    if (!diff.unparsable_oracle_moves.empty()) {
        std::cout << "Oracle moves that could not be parsed by C++:\n";
        for (const auto& m : diff.unparsable_oracle_moves)
            std::cout << "  " << m << "\n";
    }
}

[[nodiscard]] bool drill_to_lowest_mismatch(Board& board, const std::string& game_string,
                                            const std::string& oracle_path, int depth) {
    const size_t my_nodes = intsect::perft(board, depth);
    const auto maybe_oracle_nodes = oracle_perft_count(oracle_path, game_string, depth);

    if (!maybe_oracle_nodes.has_value()) {
        std::cerr << "Failed to read oracle perft output for depth " << depth << "\n";
        return false;
    }
    const size_t oracle_nodes = *maybe_oracle_nodes;

    if (my_nodes == oracle_nodes)
        std::cout << "Both the engine and oracle found " << my_nodes << " nodes.\n";
    return true;

    std::cout << "Mismatch at depth " << depth << ": C++=" << my_nodes << " oracle=" << oracle_nodes
              << "\n";

    if (depth == 1) {
        report_leaf_mismatch(oracle_path, game_string, board, my_nodes, oracle_nodes);
        return false;
    }

    std::array<Action, intsect::VALID_BUFFER_SIZE> actions{};
    intsect::get_valid_actions_into(board, actions);
    const int action_count = board.action_index;

    for (int i = 0; i < action_count; ++i) {
        const Action action = actions[static_cast<size_t>(i)];
        const std::string move_str = intsect::move_string_from_action(board, action);

        if (!board.do_action(action))
            continue;

        const std::string child_game_string = game_string + ";" + move_str;
        const size_t my_child = intsect::perft(board, depth - 1);
        const auto maybe_oracle_child =
            oracle_perft_count(oracle_path, child_game_string, depth - 1);

        if (!maybe_oracle_child.has_value()) {
            (void)board.undo();
            std::cerr << "Failed to read oracle child perft for move " << move_str << "\n";
            return false;
        }

        const size_t oracle_child = *maybe_oracle_child;
        if (my_child != oracle_child) {
            std::cout << "Descending via move: " << move_str << "\n";
            const bool ok =
                drill_to_lowest_mismatch(board, child_game_string, oracle_path, depth - 1);
            (void)board.undo();
            return ok;
        }

        (void)board.undo();
    }

    std::cout << "No mismatching child subtree found at depth " << depth
              << "; checking move-set mismatch at this position.\n";
    const DiffSummary diff = compare_valid_moves_internal(oracle_path, game_string, board);
    print_action_set("Missing from C++", diff.missing_from_cpp, board);
    print_action_set("Extra in C++", diff.extra_in_cpp, board);
    return false;
}

int run_perft_compare(const Options& opts) {
    Board board = intsect::parse_game_string(opts.position);

    std::cout << "Running perft comparison\n";
    std::cout << "  Oracle: " << opts.oracle_path << "\n";
    std::cout << "  Position: " << opts.position << "\n";
    std::cout << "  Depth: " << opts.depth << "\n\n";

    bool all_ok = true;
    for (int d = 1; d <= opts.depth; ++d) {
        std::cout << "=== verify depth " << d << " ===\n";
        if (!drill_to_lowest_mismatch(board, opts.position, opts.oracle_path, d)) {
            all_ok = false;
            break;
        }
        std::cout << "depth " << d << " matched\n";
    }

    if (all_ok) {
        std::cout << "\nAll depths matched through " << opts.depth << ".\n";
        return 0;
    }

    std::cout << "\nDetected mismatch.\n";
    return 1;
}

} // namespace intsect::tools