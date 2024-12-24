# setting up the conda environment

# RUN VARS 
source src/list_vars.sh


# Download human genomes for nf-core
source src/0_download_nfcore_resources.sh


# Download genome files for profiler DBs, and build each DB
source src/1A_build_profiler_dbs.sh
source src/1B_create_artificial_reads.sh

# Run nf-core/rnaseq to do the first pass
# We will run with human samples, controls and artificial reads separately
mkdir $DB_INDEXES_NFCORE/star
mkdir $DB_INDEXES_NFCORE/salmon
mkdir $DB_INDEXES_NFCORE/rsem

source src/2A_run_nfcore.sh "$CWD/data/samples_rnaseq_pools.csv" "$RESULTS_RNASEQ/pools"
source src/2A_run_nfcore.sh "$CWD/data/samples_rnaseq_controls.csv" "$RESULTS_RNASEQ/controls"
source src/2A_run_nfcore.sh "$CWD/data/samples_rnaseq_artificial.csv"  "$RESULTS_RNASEQ/artificial"


source src/2B_run_bowtie.sh $RESULTS_RNASEQ/pools $RESULTS_BOWTIE2/pools
source src/2B_run_bowtie.sh $RESULTS_RNASEQ/controls $RESULTS_BOWTIE2/controls
source src/2B_run_bowtie.sh $RESULTS_RNASEQ/artificial $RESULTS_BOWTIE2/artificial

# Move mapping results and remove temporal files
rm -rf "$CWD/work"
mv $CWD/data $CWD_DATA//data