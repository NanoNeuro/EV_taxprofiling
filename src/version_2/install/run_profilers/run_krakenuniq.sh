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

#      - 1: --hll-precision 18
#      - 2: --hll-precision 17
#      - 3: --hll-precision 16
#      - 4: --hll-precision 15
#      - 5: --hll-precision 14
#      - 6: --hll-precision 13
#      - 7: --hll-precision 12 
#      - 8: --hll-precision 11
#      - 9: --hll-precision 10

case "$MODE" in
    1)
        HLL=18 ;;
    2)
        HLL=17 ;;
    3)
        HLL=16 ;;
    4)
        HLL=15 ;;
    5)
        HLL=14 ;;
    6)
        HLL=13 ;;
    7)
        HLL=12 ;;
    8)
        HLL=11 ;;
    9)
        HLL=10 ;;
    *)
        echo "Error: Invalid mode specified. Please use a mode between 1 and 9."
        exit 1 ;;
esac

echo "Running Krakenuniq with mode $MODE and hll-precision $HLL"

mkdir -p $RESULTS_PROFILING/krakenuniq/pass${PASS}/$RESULTSPREFIXMODE

krakenuniq -db ${BASEDIR_PROFILER_DB_DATA}/KRAKENUNIQ \
            --threads $CPUS \
            --report $RESULTS_PROFILING/krakenuniq/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.report \
            --classified-out $RESULTS_PROFILING/krakenuniq/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.classified.fastq \
            --unclassified-out $RESULTS_PROFILING/krakenuniq/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.unclassified.fastq \
            --output $RESULTS_PROFILING/krakenuniq/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.output \
            --hll-precision $HLL \
            --paired \
            $FILE1 \
            $FILE2

gzip $RESULTS_PROFILING/krakenuniq/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.classified.fastq \
        $RESULTS_PROFILING/krakenuniq/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.unclassified.fastq


taxpasta standardise -p krakenuniq --add-name --add-lineage --summarise-at genus --taxonomy $DATABASE_DIR/profiler/GENERAL/taxonomy \
                    -o $RESULTS_PROFILING/krakenuniq/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.report.standardised.genus --output-format tsv \
                    $RESULTS_PROFILING/krakenuniq/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.report

taxpasta standardise -p krakenuniq --add-name --add-lineage --summarise-at species --taxonomy $DATABASE_DIR/profiler/GENERAL/taxonomy \
                    -o $RESULTS_PROFILING/krakenuniq/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.report.standardised.species --output-format tsv \
                    $RESULTS_PROFILING/krakenuniq/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.report