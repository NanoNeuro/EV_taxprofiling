SAMPLES_FILE=$1
RESULTS_RNASEQ=$2

CPUS=8
MAX_RAM=64

echo "CPUS " $CPUS

nextflow run \
    nf-core/rnaseq \
    -r 3.14.0 \
    -profile apptainer \
    -resume \
    --input $SAMPLES_FILE \
    --outdir $RESULTS_RNASEQ \
    --aligner star_salmon \
    --skip_bbsplit \
    --star_index $DB_INDEXES_NFCORE/star \
    --salmon_index $DB_INDEXES_NFCORE/salmon \
    --extra_salmon_quant_args " --minAssignedFrags 1" \
    --save_unaligned \
    --skip_qualimap \
    --skip_pseudo_alignment \
    --max_cpus $CPUS \
    --max_memory "$MAX_RAM".GB \
    --max_time $MAX_TIME \
    --fasta $DB_GENOMES_NFCORE/GCF_000001405.40_GRCh38.p14_genomic.fna \
    --gtf $DB_GENOMES_NFCORE/GCF_000001405.40_GRCh38.p14_genomic.gtf \
    --save_reference 