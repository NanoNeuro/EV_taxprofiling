
# DIRECTORIES
PROJECT_NAME='artificial_reads'
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
    --input $SAMPLES_FILE \
    --outdir $RESULTS_RNASEQ \
    --aligner star_salmon \
    --skip_bbsplit \
    --star_index $DATABASE_DIR/genome/index/star \
    --salmon_index $DATABASE_DIR/genome/index/salmon \
    --extra_salmon_quant_args "--minAssignedFrags 1" \
    --rsem_index $DATABASE_DIR/genome/rsem \
    --save_unaligned \
    --skip_qualimap \
    --skip_pseudo_alignment \
    --max_cpus $NUM_CPUS \
    --max_memory "$MAX_RAM".GB \
    --max_time $MAX_TIME \
    --fasta $DATABASE_DIR/genome/Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa \
    --gtf $DATABASE_DIR/genome/Homo_sapiens.GRCh38.$VERSION_ENSEMBLE_GENOME.gtf \
    --save_reference 


# 2nd RNA SEQ PIPELINE USING BOWTIE2 AND CHM13
mkdir $RESULTS_BOWTIE2

for POOL_NAME in $(cat "$POOLS_FILE")
do 
    echo "ALIGNING $POOL_NAME WITH BOWTIE2!"
    bowtie2 -x $DATABASE_DIR/genome/index/bowtie2-chm13/bowtie2-chm13 -1 $RESULTS_RNASEQ/star_salmon/unmapped/$POOL_NAME.unmapped_1.fastq.gz -2 $RESULTS_RNASEQ/star_salmon/unmapped/$POOL_NAME.unmapped_2.fastq.gz --very-sensitive -p $NUM_CPUS -S $RESULTS_BOWTIE2/$POOL_NAME.aligned.sam --un-conc-gz $RESULTS_BOWTIE2/$POOL_NAME.unaligned.fastq.gz
done



# RUN GENERICO - No lo usamos porque (1) los reads están ya procesados, (2) algunos programas no funcionan o (3) sus versiones son antiguas
nextflow run \
    nf-core/taxprofiler \
    -r 1.1.2 \
    -profile docker,test \
    --input samples_taxprofiler_prueba.csv \
    --outdir results_taxprofiling \
    --databases database.csv \
    --run_kraken2 --run_bracken --run_metaphlan3






# KAIJU 
mkdir -p $RESULTS_PROFILING/kaiju
for POOL_NAME in $(cat "$POOLS_FILE")
do 
    echo "DOING SAMPLE $POOL_NAME WITH KAIJU!"

    # Refseq
    kaiju  -t $DATABASE_DIR/taxpasta/nodes.dmp \
       -f $DATABASE_DIR/kaiju/kaiju_refseq.fmi \
       -i $RESULTS_BOWTIE2/$POOL_NAME.unaligned.fastq.1.gz \
       -j $RESULTS_BOWTIE2/$POOL_NAME.unaligned.fastq.2.gz \
       -z $NUM_CPUS -E $E_VALUE -m $MINIMUM_LENGTH \
       -o $RESULTS_PROFILING/kaiju/$POOL_NAME.refseq.out 

    # Fungi
    kaiju  -t $DATABASE_DIR/taxpasta/nodes.dmp \
       -f $DATABASE_DIR/kaiju/kaiju_fungi.fmi \
       -i $RESULTS_BOWTIE2/$POOL_NAME.unaligned.fastq.1.gz \
       -j $RESULTS_BOWTIE2/$POOL_NAME.unaligned.fastq.2.gz \
       -z $NUM_CPUS -E $E_VALUE -m $MINIMUM_LENGTH \
       -o $RESULTS_PROFILING/kaiju/$POOL_NAME.fungi.out 

    # Plasmid
    kaiju  -t $DATABASE_DIR/taxpasta/nodes.dmp \
       -f $DATABASE_DIR/kaiju/kaiju_plasmids.fmi \
       -i $RESULTS_BOWTIE2/$POOL_NAME.unaligned.fastq.1.gz \
       -j $RESULTS_BOWTIE2/$POOL_NAME.unaligned.fastq.2.gz \
       -z $NUM_CPUS -E $E_VALUE -m $MINIMUM_LENGTH \
       -o $RESULTS_PROFILING/kaiju/$POOL_NAME.plasmid.out 

    # Human
    kaiju  -t $DATABASE_DIR/taxpasta/nodes.dmp \
       -f $DATABASE_DIR/kaiju/kaiju_human.fmi \
       -i $RESULTS_BOWTIE2/$POOL_NAME.unaligned.fastq.1.gz \
       -j $RESULTS_BOWTIE2/$POOL_NAME.unaligned.fastq.2.gz \
       -z $NUM_CPUS -E $E_VALUE -m $MINIMUM_LENGTH \
       -o $RESULTS_PROFILING/kaiju/$POOL_NAME.human.out 

    echo "Sorting entries of $POOL_NAME..."
    sort -k2,2 $RESULTS_PROFILING/kaiju/$POOL_NAME.refseq.out > $RESULTS_PROFILING/kaiju/$POOL_NAME.refseq.sorted.out
    sort -k2,2 $RESULTS_PROFILING/kaiju/$POOL_NAME.fungi.out > $RESULTS_PROFILING/kaiju/$POOL_NAME.fungi.sorted.out
    sort -k2,2 $RESULTS_PROFILING/kaiju/$POOL_NAME.plasmid.out > $RESULTS_PROFILING/kaiju/$POOL_NAME.plasmid.sorted.out
    sort -k2,2 $RESULTS_PROFILING/kaiju/$POOL_NAME.human.out > $RESULTS_PROFILING/kaiju/$POOL_NAME.human.sorted.out

    echo "Merging entries of $POOL_NAME..."
    kaiju-mergeOutputs -i $RESULTS_PROFILING/kaiju/$POOL_NAME.refseq.sorted.out \
                    -j $RESULTS_PROFILING/kaiju/$POOL_NAME.fungi.sorted.out \
                    -c 'lca' -t $DATABASE_DIR/taxpasta/nodes.dmp \
                    -o $RESULTS_PROFILING/kaiju/$POOL_NAME.refseq-fungi.out

    kaiju-mergeOutputs -i $RESULTS_PROFILING/kaiju/$POOL_NAME.plasmid.sorted.out \
                    -j $RESULTS_PROFILING/kaiju/$POOL_NAME.human.sorted.out \
                    -c 'lca' -t $DATABASE_DIR/taxpasta/nodes.dmp \
                    -o $RESULTS_PROFILING/kaiju/$POOL_NAME.human-plasmid.out


    kaiju-mergeOutputs -i $RESULTS_PROFILING/kaiju/$POOL_NAME.human-plasmid.out \
                    -j $RESULTS_PROFILING/kaiju/$POOL_NAME.refseq-fungi.out \
                    -c 'lca' -t $DATABASE_DIR/taxpasta/nodes.dmp \
                    -o $RESULTS_PROFILING/kaiju/$POOL_NAME.merged.out


    echo "Creating table of $POOL_NAME..."
    kaiju2table -t $DATABASE_DIR/taxpasta/nodes.dmp \
                -n $DATABASE_DIR/taxpasta/names.dmp \
                -r species \
                -c 10 \
                -e \
                -p \
                -o $RESULTS_PROFILING/kaiju/$POOL_NAME.summary.tsv \
                $RESULTS_PROFILING/kaiju/$POOL_NAME.merged.out 

    echo "Removing .out files of $POOL_NAME..."
    rm $RESULTS_PROFILING/kaiju/$POOL_NAME.*.out
   
done









# KRAKEN 2
mkdir -p $RESULTS_PROFILING/kraken_2

for POOL_NAME in $(cat "$POOLS_FILE")
do 
    echo "DOING SAMPLE $POOL_NAME WITH KRAKEN2!"
    kraken2 -db $DATABASE_DIR/kraken_2 \
            --threads $NUM_CPUS \
            --report $RESULTS_PROFILING/kraken_2/$POOL_NAME.report \
            --classified-out $RESULTS_PROFILING/kraken_2/$POOL_NAME.classified#.fastq \
            --unclassified-out $RESULTS_PROFILING/kraken_2/$POOL_NAME.unclassified#.fastq \
            --output $RESULTS_PROFILING/kraken_2/$POOL_NAME.output \
            --confidence $KRAKEN2_CONFIDENCE \
            --gzip-compressed \
            --paired \
            $RESULTS_BOWTIE2/$POOL_NAME.unaligned.fastq.1.gz \
            $RESULTS_BOWTIE2/$POOL_NAME.unaligned.fastq.2.gz

    gzip $RESULTS_PROFILING/kraken_2/$POOL_NAME.classified_1.fastq \
        $RESULTS_PROFILING/kraken_2/$POOL_NAME.classified_2.fastq \
        $RESULTS_PROFILING/kraken_2/$POOL_NAME.unclassified_1.fastq \
        $RESULTS_PROFILING/kraken_2/$POOL_NAME.unclassified_2.fastq
done




# KRAKENUNIQ
mkdir -p $RESULTS_PROFILING/krakenuniq
MAX_RAM=100
for POOL_NAME in $(cat "$POOLS_FILE")
do 
    echo "DOING SAMPLE $POOL_NAME WITH KRAKENUNIQ!"
    krakenuniq  -db $DATABASE_DIR/krakenuniq \
                --preload-size "$MAX_RAM"G \
                --threads $NUM_CPUS \
                --report-file $RESULTS_PROFILING/krakenuniq/$POOL_NAME.report \
                --classified-out $RESULTS_PROFILING/krakenuniq/$POOL_NAME.classified.fastq \
                --unclassified-out $RESULTS_PROFILING/krakenuniq/$POOL_NAME.unclassified.fastq \
                --output $RESULTS_PROFILING/krakenuniq/$POOL_NAME.output \
                --paired --hll-precision $HLL_PRECISION \
                $RESULTS_BOWTIE2/$POOL_NAME.unaligned.fastq.1.gz \
                $RESULTS_BOWTIE2/$POOL_NAME.unaligned.fastq.2.gz 
    
    gzip $RESULTS_PROFILING/krakenuniq/$POOL_NAME.classified.fastq \
        $RESULTS_PROFILING/krakenuniq/$POOL_NAME.unclassified.fastq 
done






# CENTRIFUGE
mkdir -p $RESULTS_PROFILING/centrifuge
NUM_CPUS=10
for POOL_NAME in $(cat "$POOLS_FILE")
do 
    echo "DOING SAMPLE $POOL_NAME WITH CENTRIFUGE!"
    
    echo "PHV"
    centrifuge \
            -x $DATABASE_DIR/centrifuge/p+h+v \
            -1 $RESULTS_BOWTIE2/$POOL_NAME.unaligned.fastq.1.gz \
            -2 $RESULTS_BOWTIE2/$POOL_NAME.unaligned.fastq.2.gz \
            -S  $RESULTS_PROFILING/centrifuge/$POOL_NAME.classification_HABV \
            --report-file  $RESULTS_PROFILING/centrifuge/$POOL_NAME.report.txt \
            --threads $NUM_CPUS --mm --qc-filter --min-hitlen $MINIMUM_LENGTH
    
    echo "FP"
    centrifuge \
            -x $DATABASE_DIR/centrifuge/f+p \
            -1 $RESULTS_BOWTIE2/$POOL_NAME.unaligned.fastq.1.gz \
            -2 $RESULTS_BOWTIE2/$POOL_NAME.unaligned.fastq.2.gz \
            -S  $RESULTS_PROFILING/centrifuge/$POOL_NAME.classification_FP \
            --report-file  $RESULTS_PROFILING/centrifuge/$POOL_NAME.report.txt \
            --threads $NUM_CPUS --mm --qc-filter --min-hitlen $MINIMUM_LENGTH

    echo "KREPORT"
    centrifuge-kreport \
        -x $DATABASE_DIR/centrifuge/nt \
        --min-length $MINIMUM_LENGTH \
        $RESULTS_PROFILING/centrifuge/$POOL_NAME.classification_HABV \
        $RESULTS_PROFILING/centrifuge/$POOL_NAME.classification_FP >> $RESULTS_PROFILING/centrifuge/$POOL_NAME.kreport
done



# TAXPASTA
for POOL_NAME in $(cat "$POOLS_FILE")
do
    # KRAKEN 2
    grep -vE "2952263|2627207|2952264" $RESULTS_PROFILING/kraken_2/$POOL_NAME.report > $RESULTS_PROFILING/kraken_2/$POOL_NAME.report.pretaxpasta
    taxpasta standardise -p kraken2 --add-name --add-lineage --summarise-at genus --taxonomy $DATABASE_DIR/taxpasta \
            -o $RESULTS_PROFILING/kraken_2/$POOL_NAME.report.standardised --output-format tsv \
            $RESULTS_PROFILING/kraken_2/$POOL_NAME.report.pretaxpasta

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

    # CENTRIFUGE 
    grep -vE "2627207|2952263|3031663|10213|2081514|640869|293847|1696033|197513|417449|1379869|537876|268309|1539973|578825|600669|55798|1823762|537875|543054|1940210|1920812|373436|1503934|33263|188782|297283|497890|137601|232365|1955842|119065|578822|186813|210592|78537|670506|663587|883878|548256|272201|2072718|227348|1540081|1652079|37811|186825|192420|40306|298052|211564|33260|187686|406602|1912917|218055|159511|406635|288398|3152|215449|33277|116167|6342|44327|80844|132680|404745|1937812|1955852|71241" \
    $RESULTS_PROFILING/centrifuge/$POOL_NAME.kreport > $RESULTS_PROFILING/centrifuge/$POOL_NAME.kreport.pretaxpasta
    taxpasta standardise -p centrifuge --add-name --add-lineage --summarise-at genus --taxonomy $DATABASE_DIR/taxpasta \
            -o $RESULTS_PROFILING/centrifuge/$POOL_NAME.report.standardised --output-format tsv \
            $RESULTS_PROFILING/centrifuge/$POOL_NAME.kreport.pretaxpasta
done