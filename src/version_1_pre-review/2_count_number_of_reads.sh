CWD='/data/Proyectos/EVs'
RESULTS_RNASEQ="$CWD/results_rnaseq"
RESULTS_BOWTIE2="$CWD/results_bowtie2"
RESULTS_PROFILING="$CWD/results_profiling"



cd $CWD


for POOL_NAME in $(find data -type f -name "*R1_001.fastq.gz")
    do
        n_reads_base=$(zcat $CWD/$POOL_NAME | wc -l)
        
        echo "Número de reads base en $POOL_NAME" $(( n_reads_base / 4 ))
    done





for POOL_NAME in $(cat "$CWD/samples_profiling.txt")
    do
        n_reads_nfcore=$(zcat $RESULTS_RNASEQ/star_salmon/unmapped/$POOL_NAME.unmapped_1.fastq.gz | wc -l)
        n_reads_bowtie=$(zcat $RESULTS_BOWTIE2/$POOL_NAME.unaligned.fastq.1.gz | wc -l)
        
        echo "Número de reads nfcore en $POOL_NAME" $(( n_reads_nfcore / 4 ))
        echo "Número de reads bowtie en $POOL_NAME" $(( n_reads_bowtie / 4 ))
    done
