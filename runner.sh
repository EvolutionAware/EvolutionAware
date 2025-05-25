#!/bin/bash

IFS=$'\n\t'

TIMEOUT_SECONDS=600
CONFIGURABLE_RUNS=3

assert() {
    if ! eval "$1"; then
        echo "Assertion failed: $1" >&2
        exit 1
    fi
}

sanitize() {
    echo "$1" | tr -d '\n' | tr -d '\r'
}

process_file_pairs() {
    local input_file="$1"
    local original_storing_location="$2"
    local evolution_storing_location="$3"
    local output_csv="$4"

    if [[ ! -f "$input_file" ]]; then
        echo "The input file $input_file does not exist"
        return 1
    fi

    while IFS=',' read -r file1 file2; do
        file1=$(sanitize "$file1")
        file2=$(sanitize "$file2")

        if [[ ! -f "$file1" || ! -f "$file2" ]]; then
            echo "One or both files do not exist: $file1, $file2"
            continue
        fi

        for ((run=1; run<=CONFIGURABLE_RUNS; run++)); do
            if cmp -s "$file1" "$file2"; then
                echo "Specs are the same, skipping"
                continue
            fi

            echo "Processing: $file1 $file2"

            echo "Realizability Checking of original"
            original_start_time=$(date +%s%N)
            timeout $TIMEOUT_SECONDS java -jar singleSpec.jar "$file1" "$original_storing_location" > "original_log"
            original_exit_status=$?
            original_end_time=$(date +%s%N)
            original_duration=$(( (original_end_time - original_start_time) / 1000000 ))
            is_original_realizable=$(grep -oP "Is realizable: \\K(true|false)" original_log || echo "")

            if [[ $original_exit_status -eq 124 ]]; then
                echo "Original got timeout, skipping for the next pair"
                echo "$file1,$file2,timeout" >> "$output_csv"
                continue
            fi

            echo "Realizability Checking of Evolution"
            evolution_start_time=$(date +%s%N)
            timeout $TIMEOUT_SECONDS java -jar singleSpec.jar "$file2" "$evolution_storing_location" > "evolution_log"
            evolution_exit_status=$?
            evolution_end_time=$(date +%s%N)
            evolution_duration=$(( (evolution_end_time - evolution_start_time) / 1000000 ))
            is_evolution_realizable=$(grep -oP "Is realizable: \\K(true|false)" evolution_log || echo "")

            if [[ $evolution_exit_status -eq 124 ]]; then
                echo "Evolution got timeout"
                evolution_duration="timeout"
            fi

            echo "Evolution-Aware Realizability Checking"
            evolution_aware_start_time=$(date +%s%N)
            timeout $TIMEOUT_SECONDS java -jar singleSpec.jar "$file2" "$evolution_storing_location" "$original_storing_location" > "evolution_aware_log"
            evolution_aware_exit_status=$?
            evolution_aware_end_time=$(date +%s%N)
            evolution_aware_duration=$(( (evolution_aware_end_time - evolution_aware_start_time) / 1000000 ))
            is_evolution_aware_realizable=$(grep -oP "Is realizable: \\K(true|false)" evolution_aware_log || echo "")

            applied_heuristic=$(grep -oP "Found: \\K.*" evolution_aware_log | head -n 1 || echo "")

            if [[ $evolution_aware_exit_status -eq 124 ]]; then
                echo "Evolution Aware got timeout"
                evolution_aware_duration="timeout"
            fi

            if [[ $evolution_aware_duration != "timeout" && $evolution_duration != "timeout" && $evolution_aware_duration != "" && $evolution_duration != "" ]]; then
                echo "Comparing evolution and evolution-aware outputs"
                assert "[[ \"$is_evolution_realizable\" == \"$is_evolution_aware_realizable\" ]]"
                echo "Comparison passed"
            fi

            storing_bdd_time=$(sanitize "$(grep "^Storing BDD time:" original_log | awk '{print $NF}' || echo "")")
            loading_bdd_time=$(sanitize "$(grep "^Loading BDD time:" evolution_aware_log | awk '{print $NF}' || echo "")")

            z_iterations_evolution=$(sanitize "$(grep "^z iterations =" evolution_log | head -n1 | cut -d'=' -f2 || echo "")")
            y_iterations_evolution=$(sanitize "$(grep "^y iterations =" evolution_log | head -n1 | cut -d'=' -f2 || echo "")")
            x_iterations_evolution=$(sanitize "$(grep "^x iterations =" evolution_log | head -n1 | cut -d'=' -f2 || echo "")")

            z_iterations_evolution_aware=$(sanitize "$(grep "^z iterations =" evolution_aware_log | head -n1 | cut -d'=' -f2 || echo "")")
            y_iterations_evolution_aware=$(sanitize "$(grep "^y iterations =" evolution_aware_log | head -n1 | cut -d'=' -f2 || echo "")")
            x_iterations_evolution_aware=$(sanitize "$(grep "^x iterations =" evolution_aware_log | head -n1 | cut -d'=' -f2 || echo "")")

            running_time_evolution=$(sanitize "$(grep "^RunningTime (ms):" evolution_log | awk '{print $NF}' || echo "")")
            running_time_evolution_aware=$(sanitize "$(grep "^RunningTime (ms):" evolution_aware_log | awk '{print $NF}' || echo "")")

            game_comparison_time=$(sanitize "$(grep "^Game Comparison Time:" evolution_aware_log | cut -d':' -f2 || echo "")")
            game_comparison_result=$(sanitize "$(grep "^GameComparisonResult: " evolution_aware_log | cut -d':' -f2 || echo "")")
            loading_prev_gamemodel_time=$(sanitize "$(grep "^Loading Prev GameModel Time:" evolution_aware_log | cut -d':' -f2 || echo "")")
            loading_current_gamemodel_time=$(sanitize "$(grep "^Loading Current GameModel Time:" evolution_aware_log | cut -d':' -f2 || echo "")")

            if grep -q "Justices were reordered" evolution_aware_log; then
                justices_reordered=true
            else
                justices_reordered=false
            fi

            echo "$file1,$file2,$original_duration,$is_original_realizable,$evolution_duration,$is_evolution_realizable,$evolution_aware_duration,$applied_heuristic,$is_evolution_aware_realizable,$justices_reordered,$storing_bdd_time,$loading_bdd_time,$z_iterations_evolution,$y_iterations_evolution,$x_iterations_evolution,$z_iterations_evolution_aware,$y_iterations_evolution_aware,$x_iterations_evolution_aware,$running_time_evolution,$running_time_evolution_aware,$game_comparison_time,$loading_prev_gamemodel_time,$loading_current_gamemodel_time,$game_comparison_result" >> "$output_csv"

        done
    done < "$input_file"
}

if [[ -z "$1" || -z "$2" || -z "$3" || -z "$4" ]]; then
    echo "Usage: $0 <input_file> <original_storing_location> <evolution_storing_location> <output_csv_file>"
    exit 1
fi

echo "File1,File2,Original ExecutionTime(ms),IsOriginalRealizable,Evolution ExecutionTime(ms),IsEvolutionRealizable,Evolution-Aware ExecutionTime (ms),AppliedHeuristic,IsEvolutionAwareRealizable,JusticesReordered,StoringBDDTime,LoadingBDDTime,zIterationsEvolution,yIterationsEvolution,xIterationsEvolution,zIterationsEvolutionAware,yIterationsEvolutionAware,xIterationsEvolutionAware,FixedPointRunningTimeEvolution,FixedPointRunningTimeEvolutionAware,GameComparisonTime,LoadingPrevGameModelTime,LoadingCurrentGameModelTime,system.INI_STRENGTHENED,system.SAFETY_STRENGTHENED,system.JUSTICE_STRENGTHENED,system.INI_WEAKENED,system.SAFETY_WEAKENED,system.JUSTICE_WEAKENED,environment.INI_STRENGTHENED,environment.SAFETY_STRENGTHENED,environment.JUSTICE_STRENGTHENED,environment.INI_WEAKENED,environment.SAFETY_WEAKENED,environment.JUSTICE_WEAKENED" > "$4"

process_file_pairs "$1" "$2" "$3" "$4"
