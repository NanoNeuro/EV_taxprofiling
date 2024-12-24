MODE=""
BASENAME=""
PASS=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --mode)
            MODE="$2"
            shift 2 ;;
        --basename)
            BASENAME="$2"
            shift 2 ;;
       --pass)
            PASS="$2"
            shift 2 ;;
        *)
            echo "Unknown parameter: $1"
            exit 1 ;;
    esac
done

RESULTSPREFIXMODE="${BASENAME}_mode${MODE}"

# Set E, m, and e based on MODE
case "$MODE" in
        1)
            PARAM_MODE=5; MAX_FPR=0.001; MIN_QUERY_COV=0.75 ;;
        2)
            PARAM_MODE=5; MAX_FPR=0.001; MIN_QUERY_COV=0.7 ;;
        3)
            PARAM_MODE=4; MAX_FPR=0.01;  MIN_QUERY_COV=0.65 ;;
        4)
            PARAM_MODE=4; MAX_FPR=0.01;  MIN_QUERY_COV=0.6 ;;
        5)
            PARAM_MODE=3; MAX_FPR=0.01;  MIN_QUERY_COV=0.55 ;;
        6)
            PARAM_MODE=3; MAX_FPR=0.05;  MIN_QUERY_COV=0.5 ;;
        7)
            PARAM_MODE=2; MAX_FPR=0.05;  MIN_QUERY_COV=0.45 ;;
        8)
            PARAM_MODE=2; MAX_FPR=0.1;   MIN_QUERY_COV=0.4 ;;
        9)
            PARAM_MODE=1; MAX_FPR=0.1;   MIN_QUERY_COV=0.35 ;;
        *)
            echo "Invalid mode: $MODE"
            exit 1 ;;
    esac

echo "Running KMCP profile with mode $MODE"

kmcp profile --mode $PARAM_MODE \
             --threads $CPUS \
             --max-fpr $MAX_FPR \
             --min-query-cov $MIN_QUERY_COV \
             --no-amb-corr \
             --taxid-map ${BASEDIR_PROFILER_DB_DATA}/KMCP/input_file.tsv \
             --taxdump ${BASEDIR_PROFILER_DB}/GENERAL/taxonomy \
             --out-file $RESULTS_PROFILING/kmcp/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.profile.gz \
             $RESULTS_PROFILING/kmcp/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.search.tsv.gz


gzip -d $RESULTS_PROFILING/kmcp/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.profile.gz

taxpasta standardise -p kmcp --add-name --add-lineage --summarise-at genus --taxonomy $DATABASE_DIR/profiler/GENERAL/taxonomy \
                    -o $RESULTS_PROFILING/kmcp/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.profile.standardised.genus --output-format tsv \
                    $RESULTS_PROFILING/kmcp/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.profile

taxpasta standardise -p kmcp --add-name --add-lineage --summarise-at species --taxonomy $DATABASE_DIR/profiler/GENERAL/taxonomy \
                    -o $RESULTS_PROFILING/kmcp/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.profile.standardised.species --output-format tsv \
                    $RESULTS_PROFILING/kmcp/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.profile