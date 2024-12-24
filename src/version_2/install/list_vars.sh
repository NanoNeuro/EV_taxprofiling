#! /bin/bash --login
# Since we are running this code in an HPC, we are going to distinguish two types of resources:
# /scratch is accessed by computing nodes and is a read/write system
# /data is accesed by the login node and onyl available for reading. Teh capcity in data is higher and, in theory,
# all data created in scratch should be moved to /data to reduce the resources. 
# Therefore, once (1) we build the databases and (2) preprocess the reads (map to host) we are going to move the main
# files from there to data. If you don't do this distinction, set CWD and CWD_DATA to be at the same directory.
# In any case, the folder structure between /scratch and /data will be maintained.)

CWD='/scratch/alexmascension/TAXPROF'
cd $CWD

CWD_DATA='/data/alexmascension/TAXPROF'

# DIRECTORIES
DB_GENOMES_NFCORE="$CWD/database/nfcore/genome"
mkdir -p $DB_GENOMES_NFCORE
DB_INDEXES_NFCORE="$CWD/database/nfcore/index"
mkdir -p $DB_INDEXES_NFCORE
BASEDIR_PROFILER_DB="$CWD/database/profiler"
mkdir -p $BASEDIR_PROFILER_DB
ARTIFICIAL_READ_DIR="$CWD/data/artificial"
mkdir -p $ARTIFICIAL_READ_DIR


DB_GENOMES_NFCORE_DATA="$CWD_DATA/database/nfcore/genome"
DB_INDEXES_NFCORE_DATA="$CWD_DATA/database/nfcore/index"
BASEDIR_PROFILER_DB_DATA="$CWD_DATA/database/profiler"
ARTIFICIAL_READ_DIR_DATA="$CWD_DATA/data/artificial"



# NFCORE/BOWTIE/PROFILING COMMON VARS
DATABASE_DIR="$CWD/database"
RESULTS_RNASEQ="$CWD/results/1stmap"
RESULTS_BOWTIE2="$CWD/results/2ndmap"
RESULTS_PROFILING="$CWD/results/profiling"

DATABASE_DIR_DATA="$CWD_DATA/database"
RESULTS_RNASEQ_DATA="$CWD_DATA/results/1stmap"
RESULTS_BOWTIE2_DATA="$CWD_DATA/results/2ndmap"
RESULTS_PROFILING_DATA="$CWD_DATA/results/profiling"

POOLS_FILE="$CWD/data/$PROJECT_NAME/samples_profiling.txt"




# CPU vars
CPUS=8
SAVE_CPUS=4 # The maximum number of cpus allowed for certain profiles that does not exceed the maximum RAM
DB_BUILD_CPUS=6
MAX_RAM=64
MAX_TIME='23.h'

# PROFILING VARS
KMER=31



#  Module load (for nf.core). These are also required in the HPC. If you don't need them, feel free to comment them.
module load Java
module load Apptainer
module load Nextflow
module load Mamba

# LOADING OF COMUDELS
conda activate taxprof

