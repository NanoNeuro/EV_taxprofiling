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

#      - 1: --confidence 0.9
#      - 2: --confidence 0.85
#      - 3: --confidence 0.8
#      - 4: --confidence 0.75
#      - 5: --confidence 0.7
#      - 6: --confidence 0.65
#      - 7: --confidence 0.6
#      - 8: --confidence 0.55
#      - 9: --confidence 0.5

case "$MODE" in
    1)
        CONFIDENCE=0.9 ;;
    2)
        CONFIDENCE=0.85 ;;
    3)
        CONFIDENCE=0.8 ;;
    4)
        CONFIDENCE=0.75 ;;
    5)
        CONFIDENCE=0.7 ;;
    6)
        CONFIDENCE=0.65 ;;
    7)
        CONFIDENCE=0.6 ;;
    8)
        CONFIDENCE=0.55 ;;
    9)
        CONFIDENCE=0.5 ;;
    *)
        echo "Error: Invalid mode specified. Please use a mode between 1 and 9."
        exit 1 ;;
esac

echo "Running Kraken2 with mode $MODE"
mkdir -p $RESULTS_PROFILING/kraken2/pass${PASS}/$RESULTSPREFIXMODE

kraken2 -db ${BASEDIR_PROFILER_DB_DATA}/KRAKEN2 \
            --threads $CPUS \
            --report $RESULTS_PROFILING/kraken2/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.report \
            --classified-out $RESULTS_PROFILING/kraken2/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.classified#.fastq \
            --unclassified-out $RESULTS_PROFILING/kraken2/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.unclassified#.fastq \
            --output $RESULTS_PROFILING/kraken2/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.output \
            --confidence $CONFIDENCE \
            --gzip-compressed \
            --paired \
            $FILE1 \
            $FILE2

gzip $RESULTS_PROFILING/kraken2/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.classified_1.fastq \
        $RESULTS_PROFILING/kraken2/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.classified_2.fastq \
        $RESULTS_PROFILING/kraken2/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.unclassified_1.fastq \
        $RESULTS_PROFILING/kraken2/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.unclassified_2.fastq


taxpasta standardise -p kraken2 --add-name --add-lineage --summarise-at genus --taxonomy $DATABASE_DIR/profiler/GENERAL/taxonomy \
                    -o $RESULTS_PROFILING/kraken2/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.report.standardised.genus --output-format tsv \
                    $RESULTS_PROFILING/kraken2/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.report

taxpasta standardise -p kraken2 --add-name --add-lineage --summarise-at species --taxonomy $DATABASE_DIR/profiler/GENERAL/taxonomy \
                    -o $RESULTS_PROFILING/kraken2/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.report.standardised.species --output-format tsv \
                    $RESULTS_PROFILING/kraken2/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.report