MODE=""
BASENAME=""
FILE1=""
FILE2=""
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
        --f1)
            FILE1="$2"
            shift 2 ;;
       --f2)
            FILE2="$2"
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
            MIN_QUERY_COV=0.75; MAX_FPR=0.001; MIN_QUERY_LEN=43 ;;
        2)
            MIN_QUERY_COV=0.70; MAX_FPR=0.001; MIN_QUERY_LEN=39 ;;
        3)
            MIN_QUERY_COV=0.65; MAX_FPR=0.01;  MIN_QUERY_LEN=35 ;;
        4)
            MIN_QUERY_COV=0.60; MAX_FPR=0.01;  MIN_QUERY_LEN=31 ;;
        5)
            MIN_QUERY_COV=0.55; MAX_FPR=0.01;  MIN_QUERY_LEN=27 ;;
        6)
            MIN_QUERY_COV=0.50; MAX_FPR=0.05;  MIN_QUERY_LEN=23 ;;
        7)
            MIN_QUERY_COV=0.45; MAX_FPR=0.05;  MIN_QUERY_LEN=19 ;;
        8)
            MIN_QUERY_COV=0.40; MAX_FPR=0.1;   MIN_QUERY_LEN=15 ;;
        9)
            MIN_QUERY_COV=0.35; MAX_FPR=0.1;   MIN_QUERY_LEN=11 ;;
        *)
            echo "Invalid mode: $MODE"
            exit 1 ;;
    esac

echo "Running KMCP search with mode $MODE"

mkdir -p $RESULTS_PROFILING/kmcp/pass${PASS}/$RESULTSPREFIXMODE


kmcp search -w --threads $CPUS \
            --min-query-cov $MIN_QUERY_COV \
            --max-fpr $MAX_FPR \
            --min-query-len $MIN_QUERY_LEN \
            -d ${BASEDIR_PROFILER_DB_DATA}/KMCP \
            --read1 $FILE1 \
            --read2 $FILE2 \
            --out-file $RESULTS_PROFILING/kmcp/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.search.tsv.gz