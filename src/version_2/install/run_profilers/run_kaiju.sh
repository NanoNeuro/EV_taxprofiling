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
        E=0.001; m=39; e=3 ;;
    2)
        E=0.001; m=35; e=3 ;;
    3)
        E=0.01;  m=35; e=3 ;;
    4)
        E=0.01;  m=31; e=3 ;;
    5)
        E=0.01;  m=27; e=4 ;;
    6)
        E=0.05;  m=27; e=4 ;;
    7)
        E=0.05;  m=23; e=4 ;;
    8)
        E=0.1;   m=23; e=4 ;;
    9)
        E=0.1;   m=19; e=4 ;;
    *)
        echo "Error: Invalid mode specified. Please use a mode between 1 and 9."
        exit 1 ;;
esac

echo "Running Kaiju with mode $MODE"

mkdir -p $RESULTS_PROFILING/kaiju/pass${PASS}/$RESULTSPREFIXMODE

kaiju  -t ${BASEDIR_PROFILER_DB}/GENERAL/taxonomy/nodes.dmp \
       -f ${BASEDIR_PROFILER_DB_DATA}/KAIJU/proteins.fmi \
       -i $FILE1 \
       -j $FILE2 \
       -z $CPUS -E $E -m $m -e $e \
       -o $RESULTS_PROFILING/kaiju/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.out 

kaiju2table -t ${BASEDIR_PROFILER_DB}/GENERAL/taxonomy/nodes.dmp \
                -n ${BASEDIR_PROFILER_DB}/GENERAL/taxonomy/names.dmp \
                -r species \
                -c 10 \
                -e \
                -p \
                -o $RESULTS_PROFILING/kaiju/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.results  \
                $RESULTS_PROFILING/kaiju/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.out 


taxpasta standardise -p kaiju --add-name --add-lineage --summarise-at genus --taxonomy $DATABASE_DIR/profiler/GENERAL/taxonomy \
                    -o $RESULTS_PROFILING/kaiju/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.results.standardised.genus --output-format tsv \
                    $RESULTS_PROFILING/kaiju/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.results

taxpasta standardise -p kaiju --add-name --add-lineage --summarise-at species --taxonomy $DATABASE_DIR/profiler/GENERAL/taxonomy \
                    -o $RESULTS_PROFILING/kaiju/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.results.standardised.species --output-format tsv \
                    $RESULTS_PROFILING/kaiju/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.results