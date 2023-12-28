#! /bin/bash --login
CWD='/data/Proyectos/EVs'
cd $CWD

conda activate EVs


# DIRECTORIES
PROJECT_NAME='EM_EVPools'
CWD='/data/Proyectos/EVs'
RESULTS_RNASEQ="$CWD/results_rnaseq/$PROJECT_NAME"
RESULTS_BOWTIE2="$CWD/results_bowtie2/$PROJECT_NAME"
RESULTS_PROFILING="$CWD/results_profiling/$PROJECT_NAME"
SAMPLES_FILE="$CWD/data/$PROJECT_NAME/samples_rnaseq.csv"
POOLS_FILE="$CWD/data/$PROJECT_NAME/samples_profiling.txt"
DATABASE_DIR="$CWD/database"

# VERSIONS AND PC PARAMS
VERSION_ENSEMBLE_GENOME=109
NUM_CPUS=20
MAX_RAM=85
MAX_TIME='500.h'

# QUALITY PARAMS
KRAKEN2_CONFIDENCE=0.90  # Standard: 0 [KRAKEN2]
HLL_PRECISION=16         # Standard: 12 [KRAKENUNIQ]
MINIMUM_LENGTH=41        # Standard: 11 [KAIJU], 22 [CENTRIFUGE]
E_VALUE=0.0001           # Standard: 0.01 [KAIJU]