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
            MIN_HITLEN=51 ;;
        2)
            MIN_HITLEN=47 ;;
        3)
            MIN_HITLEN=43 ;;
        4)
            MIN_HITLEN=39 ;;
        5)
            MIN_HITLEN=35 ;;
        6)
            MIN_HITLEN=31 ;;
        7)
            MIN_HITLEN=27 ;;
        8)
            MIN_HITLEN=23 ;;
        9)
            MIN_HITLEN=19 ;;
        *)
            echo "Invalid mode: $MODE"
            exit 1 ;;
    esac


echo "Running Centrifuge search with mode $MODE"

mkdir -p $RESULTS_PROFILING/centrifuge/pass${PASS}/$RESULTSPREFIXMODE

centrifuge \
            -x ${BASEDIR_PROFILER_DB_DATA}/CENTRIFUGE/customdb \
            -1 $FILE1 \
            -2 $FILE2 \
            -S  $RESULTS_PROFILING/centrifuge/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.classification \
            --report-file  $RESULTS_PROFILING/centrifuge/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.report.txt \
            --threads $CPUS --mm  --min-hitlen ${MIN_HITLEN}

echo "Running kreport"
centrifuge-kreport \
               -x ${BASEDIR_PROFILER_DB_DATA}/CENTRIFUGE/customdb \
               --min-length ${MIN_HITLEN} \
               $RESULTS_PROFILING/centrifuge/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.classification >  \
                    $RESULTS_PROFILING/centrifuge/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.kreport

echo "Running taxpasta"
taxpasta standardise -p centrifuge --add-name --add-lineage --summarise-at genus --taxonomy $DATABASE_DIR/profiler/GENERAL/taxonomy \
                    -o $RESULTS_PROFILING/centrifuge/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.kreport.standardised.genus --output-format tsv \
                    $RESULTS_PROFILING/centrifuge/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.kreport

taxpasta standardise -p centrifuge --add-name --add-lineage --summarise-at species --taxonomy $DATABASE_DIR/profiler/GENERAL/taxonomy \
                    -o $RESULTS_PROFILING/centrifuge/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.kreport.standardised.species --output-format tsv \
                    $RESULTS_PROFILING/centrifuge/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.kreport