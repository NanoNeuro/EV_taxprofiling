VERSION_ENSEMBLE_GENOME=109
CWD='/media/seth/SETH_DATA/Biodonostia_David/EVs'
RESULTS_RNASEQ="$CWD/results_rnaseq"
RESULTS_PROFILING="$CWD/results_profiling"
DATABASE_DIR="$CWD/database"
NUM_CPUS=35
NUM_RAM='364.GB'
MAX_TIME='500.h'
POOL_NAME='POOL3'
KRAKEN2_CONDIFENDE=0.7


# 1) -profile  usar docker y, como last resort, conda
# 2) --
# 3) Incluir --star_index cuando se haya indexado por primera vez (HAY QUE MOVER EL ÍNDICE A LA CARPETA!!!)
# We skip qualimap becau it gets to a timeout error and it is not really necessary for the analysis


nextflow run \
    nf-core/rnaseq \
    -r 3.11.2 \
    -profile docker \
    -resume \
    --input $CWD/samples_rnaseq.csv \
    --outdir $RESULTS_RNASEQ \
    --aligner star_salmon \
    --skip_bbsplit \
    --star_index $DATABASE_DIR/genome/index/star \
    --salmon_index $DATABASE_DIR/genome/index/salmon \
    --rsem_index $DATABASE_DIR/genome/rsem \
    --save_unaligned \
    --skip_qualimap \
    --max_cpus $NUM_CPUS \
    --max_memory $NUM_RAM \
    --max_time $MAX_TIME \
    --fasta $DATABASE_DIR/Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa.gz \
    --gtf $DATABASE_DIR/Homo_sapiens.GRCh38.$VERSION_ENSEMBLE_GENOME.gtf.gz \
    --save_reference 


# RUN GENERICO - No lo usamos porque (1) los reads están ya procesados, (2) algunos programas no funcionan o (3) sus versiones son antiguas
nextflow run \
    nf-core/taxprofiler \
    -r 1.0.1 \
    -profile docker \
    --input samples_taxprofiler_prueba.csv \
    --outdir results_taxprofiling \
    --databases database.csv \
    --run_kraken2 --run_bracken --run_metaphlan3

mkdir -p $RESULTS_PROFILING/kraken_2
kraken2 -db $DATABASE_DIR/kraken_2 \
        --threads 8 \
        --report $RESULTS_PROFILING/kraken_2/$POOL_NAME.report \
        --classified-out $RESULTS_PROFILING/kraken_2/$POOL_NAME.classified#.fastq \
        --unclassified-out $RESULTS_PROFILING/kraken_2/$POOL_NAME.unclassified#.fastq \
        --output $RESULTS_PROFILING/kraken_2/$POOL_NAME.output \
        --confidence $KRAKEN2_CONDIFENDE \
        --gzip-compressed \
        --paired \
        $RESULTS_RNASEQ/star_salmon/unmapped/$POOL_NAME.unmapped_1.fastq.gz \
        $RESULTS_RNASEQ/star_salmon/unmapped/$POOL_NAME.unmapped_2.fastq.gz 

gzip $RESULTS_PROFILING/kraken_2/$POOL_NAME.classified_1.fastq \
     $RESULTS_PROFILING/kraken_2/$POOL_NAME.classified_2.fastq \
     $RESULTS_PROFILING/kraken_2/$POOL_NAME.unclassified_1.fastq \
     $RESULTS_PROFILING/kraken_2/$POOL_NAME.unclassified_2.fastq
        


## Metaphlan
mkdir -p $RESULTS_PROFILING/metaphlan
metaphlan  $RESULTS_RNASEQ/star_salmon/unmapped/$POOL_NAME.unmapped_1.fastq.gz,$RESULTS_RNASEQ/star_salmon/unmapped/$POOL_NAME.unmapped_2.fastq.gz \
           --input_type fastq \
           --index $DATABASE_DIR/metaphlan/mpa_vOct22_CHOCOPhlAnSGB_202212 \
           -t rel_ab_w_read_stats \
           -o $RESULTS_PROFILING/metaphlan/$POOL_NAME.report.txt \
           --nproc 5 \
           --bowtie2out $RESULTS_PROFILING/metaphlan/bowtie2out \
           --bowtie2db $DATABASE_DIR/metaphlan/mpa_vOct22_CHOCOPhlAnSGB_202212 \
           --mpa3 \
           --add_viruses

metaphlan  $RESULTS_RNASEQ/star_salmon/unmapped/$POOL_NAME.unmapped_1.fastq.gz \
           --input_type fastq \
           --index $DATABASE_DIR/metaphlan/mpa_v31_CHOCOPhlAn_201901 \
           -t rel_ab_w_read_stats \
           -o $RESULTS_PROFILING/metaphlan/$POOL_NAME.report.txt \
           --nproc 5 \
           --bowtie2out $RESULTS_PROFILING/metaphlan/bowtie2out \
           --bowtie2db $DATABASE_DIR/metaphlan/mpa_v31_CHOCOPhlAn_201901 

# Centrigfuge  #IGUAL HAY QUE METER SAMPLE SHEET
# prepare sheet file
echo -e "2\t$RESULTS_RNASEQ/star_salmon/unmapped/$POOL_NAME.unmapped_1.fastq.gz\
           \t$RESULTS_RNASEQ/star_salmon/unmapped/$POOL_NAME.unmapped_2.fastq.gz\
           \t$RESULTS_PROFILING/metaphlan/$POOL_NAME.classification\
           \t$RESULTS_PROFILING/metaphlan/$POOL_NAME.report.txt" >> $CWD/centrifuge.config


centrifuge \
        -x $DATABASE_DIR/centrifuge/phv/phv \
        -m1 $RESULTS_RNASEQ/star_salmon/unmapped/$POOL_NAME.unmapped_1.fastq.gz \
        -m2 $RESULTS_RNASEQ/star_salmon/unmapped/$POOL_NAME.unmapped_2.fastq.gz \
        -S  $RESULTS_PROFILING/metaphlan/$POOL_NAME.classification \
        --report-file  $RESULTS_PROFILING/metaphlan/$POOL_NAME.report.txt \
        --threads 8 



