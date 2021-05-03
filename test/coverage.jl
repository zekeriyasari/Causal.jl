# This file is used for code coverage of Causal test suites.

# NOTE: Before executing this script, run test suite of Causal as 
# ] test --coverage Causal
#  

using Coverage

# process '*.cov' files
coverage = process_folder() # defaults to src/; alternatively, supply the folder name as argument
coverage = append!(coverage, process_folder("deps"))

# process '*.info' files
coverage = merge_coverage_counts(coverage, filter!(
    let prefixes = (joinpath(pwd(), "src", ""),
                    joinpath(pwd(), "deps", ""))
        c -> any(p -> startswith(c.filename, p), prefixes)
    end,
    LCOV.readfolder("test")))

# Get total coverage for all Julia files
covered_lines, total_lines = get_summary(coverage)
percentage = covered_lines / total_lines * 100
@info "Code coverage percentage : $percentage%"

# Clean folders 
foreach(clean_folder, ["src", "test"])
