VERSION_ENSEMBLE_GENOME=109
CWD='/data/Proyectos/EVs'
RESULTS_RNASEQ="$CWD/results_rnaseq"
RESULTS_PROFILING="$CWD/results_profiling"
DATABASE_DIR="$CWD/database"
NUM_CPUS=10
NUM_RAM='120.GB'
MAX_TIME='500.h'
KRAKEN2_CONDIFENDE=0.85

POOL_NAME='POOL3'
MINIMUM_LENGTH=35
E_VALUE=0.001


# RNA SEQ PIPELINE - para mappear a humano
# 1) -profile  usar docker y, como last resort, conda
# 2) Incluir --star_index cuando se haya indexado por primera vez (HAY QUE MOVER EL ÍNDICE A LA CARPETA!!!)
# We skip qualimap becau it gets to a timeout error and it is not really necessary for the analysis

cd $CWD

nextflow run \
    nf-core/rnaseq \
    -r 3.12.0 \
    -profile docker \
    -resume \
    --input $CWD/samples_rnaseq.csv \
    --outdir $RESULTS_RNASEQ \
    --aligner star_salmon \
    --skip_bbsplit \
    --star_index $DATABASE_DIR/genome/index/star \
    --salmon_index $DATABASE_DIR/genome/index/salmon \
    --minAssignedFrags 3 \
    --rsem_index $DATABASE_DIR/genome/rsem \
    --save_unaligned \
    --skip_qualimap \
    --max_cpus $NUM_CPUS \
    --max_memory $NUM_RAM \
    --max_time $MAX_TIME \
    --fasta $DATABASE_DIR/genome/Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa \
    --gtf $DATABASE_DIR/genome/Homo_sapiens.GRCh38.$VERSION_ENSEMBLE_GENOME.gtf \
    --save_reference


# 2nd RNA SEQ PIPELINE USING BOWTIE2 AND CHM13
bowtie2-build -f $DATABASE_DIR/genome/GCF_009914755.1_T2T-CHM13v2.0_genomic.fna $DATABASE_DIR/genome/index/bowtie2-chm13
for POOL_NAME in $(cat "$CWD/samples_profiling.txt")
do 
    echo "ALIGNING $POOL_NAME WITH BOWTIE2!"
done









# RUN GENERICO - No lo usamos porque (1) los reads están ya procesados, (2) algunos programas no funcionan o (3) sus versiones son antiguas
nextflow run \
    nf-core/taxprofiler \
    -r 1.1.1 \
    -profile docker \
    --input samples_taxprofiler_prueba.csv \
    --outdir results_taxprofiling \
    --databases database.csv \
    --run_kraken2 --run_bracken --run_metaphlan3





# KAIJU (uno es de refseq y otro de fungi, veremos como juntarlos jejeje)
mkdir -p $RESULTS_PROFILING/kaiju

for POOL_NAME in $(cat "$CWD/samples_profiling.txt")
do 
    echo "DOING SAMPLE $POOL_NAME WITH KAIJU!"
    kaiju  -t $DATABASE_DIR/kaiju/nodes.dmp \
       -f $DATABASE_DIR/kaiju/kaiju_db_refseq.fmi \
       -i $RESULTS_RNASEQ/star_salmon/unmapped/$POOL_NAME.unmapped_1.fastq.gz \
       -j $RESULTS_RNASEQ/star_salmon/unmapped/$POOL_NAME.unmapped_2.fastq.gz \
       -z $NUM_CPUS -E $E_VALUE -m $MINIMUM_LENGTH \
       -o $RESULTS_PROFILING/kaiju/$POOL_NAME.refseq.out 

    kaiju  -t $DATABASE_DIR/kaiju/nodes.dmp \
        -f $DATABASE_DIR/kaiju/kaiju_db_fungi.fmi \
        -i $RESULTS_RNASEQ/star_salmon/unmapped/$POOL_NAME.unmapped_1.fastq.gz \
        -j $RESULTS_RNASEQ/star_salmon/unmapped/$POOL_NAME.unmapped_2.fastq.gz \
        -z $NUM_CPUS -E $E_VALUE -m $MINIMUM_LENGTH\
        -o $RESULTS_PROFILING/kaiju/$POOL_NAME.fungi.out 

    sort -k2,2 $RESULTS_PROFILING/kaiju/$POOL_NAME.refseq.out > $RESULTS_PROFILING/kaiju/$POOL_NAME.refseq.sorted.out
    sort -k2,2 $RESULTS_PROFILING/kaiju/$POOL_NAME.fungi.out > $RESULTS_PROFILING/kaiju/$POOL_NAME.fungi.sorted.out

    kaiju-mergeOutputs -i $RESULTS_PROFILING/kaiju/$POOL_NAME.refseq.sorted.out \
                    -j $RESULTS_PROFILING/kaiju/$POOL_NAME.fungi.sorted.out \
                    -c 'lca' -t $DATABASE_DIR/kaiju/nodes.dmp \
                    -o $RESULTS_PROFILING/kaiju/$POOL_NAME.merged.out

    rm $RESULTS_PROFILING/kaiju/$POOL_NAME.refseq.out $RESULTS_PROFILING/kaiju/$POOL_NAME.fungi.out \
       $RESULTS_PROFILING/kaiju/$POOL_NAME.refseq.sorted.out $RESULTS_PROFILING/kaiju/$POOL_NAME.fungi.sorted.out

    kaiju2table -t $DATABASE_DIR/kaiju/nodes.dmp \
                -n $DATABASE_DIR/kaiju/names.dmp \
                -r species \
                -c 10 \
                -e \
                -p \
                -o $RESULTS_PROFILING/kaiju/$POOL_NAME.summary.tsv \
                $RESULTS_PROFILING/kaiju/$POOL_NAME.merged.out 
done



# KRAKEN 2
mkdir -p $RESULTS_PROFILING/kraken_2

for POOL_NAME in $(cat "$CWD/samples_profiling.txt")
do 
    echo "DOING SAMPLE $POOL_NAME WITH KRAKEN2!"
    kraken2 -db $DATABASE_DIR/kraken_2 \
            --threads $NUM_CPUS \
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
done



# CENTRIFUGE
mkdir -p $RESULTS_PROFILING/centrifuge

for POOL_NAME in $(cat "$CWD/samples_profiling.txt")
do 
    echo "DOING SAMPLE $POOL_NAME WITH CENTRIFUGE!"
    centrifuge \
            -x $DATABASE_DIR/centrifuge/p+h+v \
            -1 $RESULTS_RNASEQ/star_salmon/unmapped/$POOL_NAME.unmapped_1.fastq.gz \
            -2 $RESULTS_RNASEQ/star_salmon/unmapped/$POOL_NAME.unmapped_2.fastq.gz \
            -S  $RESULTS_PROFILING/centrifuge/$POOL_NAME.classification \
            --report-file  $RESULTS_PROFILING/centrifuge/$POOL_NAME.report.txt \
            --threads $NUM_CPUS --qc-filter --min-hitlen $MINIMUM_LENGTH 

    centrifuge-kreport \
        -x $DATABASE_DIR/centrifuge/p+h+v \
        --min-length $MINIMUM_LENGTH \
        $RESULTS_PROFILING/centrifuge/$POOL_NAME.classification >> $RESULTS_PROFILING/centrifuge/$POOL_NAME.kreport
done


for POOL_NAME in $(cat "$CWD/samples_profiling.txt")
do 

done


# KRAKENUNIQ
mkdir -p $RESULTS_PROFILING/krakenuniq

for POOL_NAME in $(cat "$CWD/samples_profiling.txt")
do 
    echo "DOING SAMPLE $POOL_NAME WITH KRAKENUNIQ!"
    krakenuniq  -db $DATABASE_DIR/krakenuniq \
                --preload \
                --threads 8 \
                --report-file $RESULTS_PROFILING/krakenuniq/$POOL_NAME.report \
                --classified-out $RESULTS_PROFILING/krakenuniq/$POOL_NAME.classified.fastq \
                --unclassified-out $RESULTS_PROFILING/krakenuniq/$POOL_NAME.unclassified.fastq \
                --output $RESULTS_PROFILING/krakenuniq/$POOL_NAME.output \
                --paired --hll-precision 14\
                $RESULTS_RNASEQ/star_salmon/unmapped/$POOL_NAME.unmapped_1.fastq.gz \
                $RESULTS_RNASEQ/star_salmon/unmapped/$POOL_NAME.unmapped_2.fastq.gz 
    
    gzip $RESULTS_PROFILING/krakenuniq/$POOL_NAME.classified.fastq \
        $RESULTS_PROFILING/krakenuniq/$POOL_NAME.unclassified.fastq 
done




## Metaphlan
mkdir -p $RESULTS_PROFILING/metaphlan

for POOL_NAME in $(cat "$CWD/samples_profiling.txt")
do 
    echo "DOING SAMPLE $POOL_NAME WITH METAPHLAN!"
    metaphlan  $RESULTS_RNASEQ/star_salmon/unmapped/$POOL_NAME.unmapped_1.fastq.gz,$RESULTS_RNASEQ/star_salmon/unmapped/$POOL_NAME.unmapped_2.fastq.gz \
            --input_type fastq \
            --index mpa_vOct22_CHOCOPhlAnSGB_202212 \
            -t rel_ab_w_read_stats \
            -o $RESULTS_PROFILING/metaphlan/$POOL_NAME.report.txt \
            --nproc $NUM_CPUS \
            --bowtie2out $RESULTS_PROFILING/metaphlan/$POOL_NAME.bt2.out \
            --bowtie2db $DATABASE_DIR/metaphlan \
            --add_viruses 
done







# TAXPASTA

## Metaphlan - Taxpasta fails


for POOL_NAME in $(cat "$CWD/samples_profiling.txt")
do
    # KRAKEN 2
    taxpasta standardise -p kraken2 --add-name --add-lineage --summarise-at genus --taxonomy $DATABASE_DIR/taxpasta \
            -o $RESULTS_PROFILING/kraken_2/$POOL_NAME.report.standardised --output-format tsv \
            $RESULTS_PROFILING/kraken_2/$POOL_NAME.report 

    # KRAKENUNIQ
    ## Remove a species that gives an error
    grep -v "2927082" $RESULTS_PROFILING/krakenuniq/$POOL_NAME.report > $RESULTS_PROFILING/krakenuniq/$POOL_NAME.report.pretaxpasta
    taxpasta standardise -p krakenuniq --add-name --add-lineage --summarise-at genus --taxonomy $DATABASE_DIR/taxpasta \
            -o $RESULTS_PROFILING/krakenuniq/$POOL_NAME.report.standardised --output-format tsv \
            $RESULTS_PROFILING/krakenuniq/$POOL_NAME.report.pretaxpasta 

    # KAIJU
    taxpasta standardise -p kaiju --add-name --add-lineage --summarise-at genus --taxonomy $DATABASE_DIR/taxpasta \
            -o $RESULTS_PROFILING/kaiju/$POOL_NAME.report.standardised --output-format tsv \
            $RESULTS_PROFILING/kaiju/$POOL_NAME.summary.tsv 
done

for POOL_NAME in $(cat "$CWD/samples_profiling.txt")
do
    grep -vE "119065|578822|186813|210592|78537|670506|663587" $RESULTS_PROFILING/centrifuge/$POOL_NAME.kreport > $RESULTS_PROFILING/centrifuge/$POOL_NAME.kreport.pretaxpasta
    taxpasta standardise -p centrifuge --add-name --add-lineage --summarise-at genus --taxonomy $DATABASE_DIR/taxpasta \
            -o $RESULTS_PROFILING/centrifuge/$POOL_NAME.report.standardised --output-format tsv \
            $RESULTS_PROFILING/centrifuge/$POOL_NAME.kreport.pretaxpasta
done