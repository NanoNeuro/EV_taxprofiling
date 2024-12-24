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
            REL_CUTOFF=0.90; REL_FILTER=0.4 ;;
        2)
            REL_CUTOFF=0.90; REL_FILTER=0.35 ;;
        3)
            REL_CUTOFF=0.80; REL_FILTER=0.3 ;;
        4)
            REL_CUTOFF=0.80; REL_FILTER=0.25 ;;
        5)
            REL_CUTOFF=0.70; REL_FILTER=0.2 ;;
        6)
            REL_CUTOFF=0.70; REL_FILTER=0.15 ;;
        7)
            REL_CUTOFF=0.60; REL_FILTER=0.1 ;;
        8)
            REL_CUTOFF=0.60; REL_FILTER=0.05 ;;
        9)
            REL_CUTOFF=0.50; REL_FILTER=0 ;;
        *)
            echo "Invalid mode: $MODE"
            exit 1 ;;
    esac


echo "Running Ganon search with mode $MODE"

mkdir -p $RESULTS_PROFILING/ganon/pass${PASS}/$RESULTSPREFIXMODE

ganon-classify --ibf ${BASEDIR_PROFILER_DB_DATA}/GANON/db.ibf \
               --tax ${BASEDIR_PROFILER_DB_DATA}/GANON/db.tax \
               --threads $CPUS \
               --output-all --output-unclassified \
               --paired-reads $FILE1,$FILE2 \
               --verbose \
               --rel-cutoff $REL_CUTOFF --rel-filter $REL_FILTER \
               --output-prefix $RESULTS_PROFILING/ganon/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE

ganon report --db-prefix ${BASEDIR_PROFILER_DB_DATA}/GANON/db \
             --input $RESULTS_PROFILING/ganon/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.rep \
             --output-prefix $RESULTS_PROFILING/ganon/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE 

# The 5 qnd 6 colums are all 0 and taxpasta seems to use these columns
awk -F'\t' 'BEGIN{OFS="\t"} {$5=$7; $6=$7; print}' $RESULTS_PROFILING/ganon/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.tre > \
        $RESULTS_PROFILING/ganon/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.pretraxpasta.tre

taxpasta standardise -p ganon --add-name --add-lineage --summarise-at genus --taxonomy $DATABASE_DIR/profiler/GENERAL/taxonomy \
                    -o $RESULTS_PROFILING/ganon/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.report.standardised.genus --output-format tsv \
                    $RESULTS_PROFILING/ganon/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.pretraxpasta.tre

taxpasta standardise -p ganon --add-name --add-lineage --summarise-at species --taxonomy $DATABASE_DIR/profiler/GENERAL/taxonomy \
                    -o $RESULTS_PROFILING/ganon/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.report.standardised.species --output-format tsv \
                    $RESULTS_PROFILING/ganon/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.pretraxpasta.tre

gzip $RESULTS_PROFILING/ganon/pass${PASS}/$RESULTSPREFIXMODE/$RESULTSPREFIXMODE.all