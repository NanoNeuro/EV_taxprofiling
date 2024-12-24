





# INVESTIGATE THE DIFFERENT MODES FOR EACH PROFILER TO ADJUST THE SENSITIVITY!!!
# 1 (very sensitive) to 9 (not sensitive)
## KAIJU
#      - 1: E = 0.001 | m = 43 | e = 2
#      - 2: E = 0.001 | m = 39 | e = 2
#      - 3: E = 0.01  | m = 35 | e = 3
#      - 4: E = 0.01  | m = 31 | e = 3
#      - 5: E = 0.01  | m = 27 | e = 4
#      - 6: E = 0.05  | m = 23 | e = 4
#      - 7: E = 0.05  | m = 19 | e = 4
#      - 8: E = 0.1   | m = 15 | e = 5
#      - 9: E = 0.1   | m = 11 | e = 5

for MODE in {1..9}; do
     source src/run_profilers/run_kaiju.sh --mode $MODE --pass 2 --basename ARTIFICIAL \
          --f1 ${RESULTS_BOWTIE2_DATA}/artificial/ARTIFICIAL.unmapped.fastq.1.gz \
          --f2 ${RESULTS_BOWTIE2_DATA}/artificial/ARTIFICIAL.unmapped.fastq.2.gz

     source src/run_profilers/run_kaiju.sh --mode $MODE --pass 0 --basename ARTIFICIAL \
          --f1 $CWD_DATA/data/artificial/artificial_reads_R1.fastq.gz \
          --f2 $CWD_DATA/data/artificial/artificial_reads_R2.fastq.gz
done

MODE=5
PASS=2
for NAME in 'ACIDOLA' 'BLACTIS'; do
     source /scratch/alexmascension/TAXPROF/src/run_profilers/run_kaiju.sh --mode $MODE --pass $PASS --basename $NAME \
               --f1 ${RESULTS_BOWTIE2_DATA}/controls/$NAME.unmapped.fastq.1.gz \
               --f2 ${RESULTS_BOWTIE2_DATA}/controls/$NAME.unmapped.fastq.2.gz
done

for POOLN in {1..12}; do
     NAME="POOL${POOLN}"
     echo $NAME
     source /scratch/alexmascension/TAXPROF/src/run_profilers/run_kaiju.sh --mode $MODE --pass $PASS --basename $NAME \
               --f1 ${RESULTS_BOWTIE2_DATA}/pools/$NAME.unmapped.fastq.1.gz \
               --f2 ${RESULTS_BOWTIE2_DATA}/pools/$NAME.unmapped.fastq.2.gz
done



## GANON
#      - 1: --rel-cutoff 0.90  | --rel-filter 0.4
#      - 2: --rel-cutoff 0.90  | --rel-filter 0.35
#      - 3: --rel-cutoff 0.80  | --rel-filter 0.3
#      - 4: --rel-cutoff 0.80  | --rel-filter 0.25
#      - 5: --rel-cutoff 0.70  | --rel-filter 0.2
#      - 6: --rel-cutoff 0.70  | --rel-filter 0.15
#      - 7: --rel-cutoff 0.60  | --rel-filter 0.1
#      - 8: --rel-cutoff 0.60  | --rel-filter 0.05
#      - 9: --rel-cutoff 0.50  | --rel-filter 0

for MODE in {1..9}; do
    source src/run_profilers/run_ganon_classify.sh --mode $MODE --pass 2 --basename ARTIFICIAL \
         --f1 ${RESULTS_BOWTIE2_DATA}/artificial/ARTIFICIAL.unmapped.fastq.1.gz \
         --f2 ${RESULTS_BOWTIE2_DATA}/artificial/ARTIFICIAL.unmapped.fastq.2.gz

    source src/run_profilers/run_ganon_classify.sh --mode $MODE --pass 0 --basename ARTIFICIAL \
         --f1 $CWD_DATA/data/artificial/artificial_reads_R1.fastq.gz \
         --f2 $CWD_DATA/data/artificial/artificial_reads_R2.fastq.gz
done


MODE=5
PASS=2
for NAME in 'ACIDOLA' 'BLACTIS'; do
     source /scratch/alexmascension/TAXPROF/src/run_profilers/run_ganon_classify.sh --mode $MODE --pass $PASS --basename $NAME \
               --f1 ${RESULTS_BOWTIE2_DATA}/controls/$NAME.unmapped.fastq.1.gz \
               --f2 ${RESULTS_BOWTIE2_DATA}/controls/$NAME.unmapped.fastq.2.gz
done

for POOLN in {1..12}; do
     NAME="POOL${POOLN}"
     echo $NAME
     source /scratch/alexmascension/TAXPROF/src/run_profilers/run_ganon_classify.sh --mode $MODE --pass $PASS --basename $NAME \
               --f1 ${RESULTS_BOWTIE2_DATA}/pools/$NAME.unmapped.fastq.1.gz \
               --f2 ${RESULTS_BOWTIE2_DATA}/pools/$NAME.unmapped.fastq.2.gz
done





## KMCP SEARCH
#      - 1: --min-query-cov 0.75 | --max-fpr 0.001 | --min-query-len 43 
#      - 2: --min-query-cov 0.70 | --max-fpr 0.001 | --min-query-len 39 
#      - 3: --min-query-cov 0.65 | --max-fpr 0.01  | --min-query-len 35 
#      - 4: --min-query-cov 0.60 | --max-fpr 0.01  | --min-query-len 31 
#      - 5: --min-query-cov 0.55 | --max-fpr 0.01  | --min-query-len 27 
#      - 6: --min-query-cov 0.50 | --max-fpr 0.05  | --min-query-len 23 
#      - 7: --min-query-cov 0.45 | --max-fpr 0.05  | --min-query-len 19 
#      - 8: --min-query-cov 0.40 | --max-fpr 0.1   | --min-query-len 15
#      - 9: --min-query-cov 0.35 | --max-fpr 0.1   | --min-query-len 11 

## KMCP PROFILE
#      - 1: --mode 0 | --max-fpr 0.001 | --min-query-cov 0.75
#      - 2: --mode 0 | --max-fpr 0.001 | --min-query-cov 0.70
#      - 3: --mode 1 | --max-fpr 0.01  | --min-query-cov 0.65
#      - 4: --mode 2 | --max-fpr 0.01  | --min-query-cov 0.60
#      - 5: --mode 3 | --max-fpr 0.01  | --min-query-cov 0.55
#      - 6: --mode 3 | --max-fpr 0.05  | --min-query-cov 0.50
#      - 7: --mode 4 | --max-fpr 0.05  | --min-query-cov 0.45
#      - 8: --mode 4 | --max-fpr 0.1   | --min-query-cov 0.40
#      - 9: --mode 5 | --max-fpr 0.1   | --min-query-cov 0.35


for MODE in {1..9}; do
    source src/run_profilers/run_kmcp_search.sh --mode $MODE --pass 2 --basename ARTIFICIAL \
         --f1 ${RESULTS_BOWTIE2_DATA}/artificial/ARTIFICIAL.unmapped.fastq.1.gz \
         --f2 ${RESULTS_BOWTIE2_DATA}/artificial/ARTIFICIAL.unmapped.fastq.2.gz

    source src/run_profilers/run_kmcp_profile.sh --mode $MODE --pass 2 --basename ARTIFICIAL 


    source src/run_profilers/run_kmcp_search.sh --mode $MODE --pass 0 --basename ARTIFICIAL \
         --f1 $CWD_DATA/data/artificial/artificial_reads_R1.fastq.gz \
         --f2 $CWD_DATA/data/artificial/artificial_reads_R2.fastq.gz

    source src/run_profilers/run_kmcp_profile.sh --mode $MODE --pass 0 --basename ARTIFICIAL 
done


MODE=5
PASS=2
for NAME in 'ACIDOLA' 'BLACTIS'; do
     source /scratch/alexmascension/TAXPROF/src/run_profilers/run_ganon_classify.sh --mode $MODE --pass $PASS --basename $NAME \
               --f1 ${RESULTS_BOWTIE2_DATA}/controls/$NAME.unmapped.fastq.1.gz \
               --f2 ${RESULTS_BOWTIE2_DATA}/controls/$NAME.unmapped.fastq.2.gz
done

for POOLN in {1..12}; do
     NAME="POOL${POOLN}"
     echo $NAME
     source /scratch/alexmascension/TAXPROF/src/run_profilers/run_kmcp_search.sh --mode $MODE --pass $PASS --basename $NAME \
               --f1 ${RESULTS_BOWTIE2_DATA}/pools/$NAME.unmapped.fastq.1.gz \
               --f2 ${RESULTS_BOWTIE2_DATA}/pools/$NAME.unmapped.fastq.2.gz
     source src/run_profilers/run_kmcp_profile.sh --mode $MODE --pass $PASS --basename $NAME
done




# CENTRIFUGE
#      - 1: --min-hitlen 51
#      - 2: --min-hitlen 47
#      - 3: --min-hitlen 43
#      - 4: --min-hitlen 39 
#      - 5: --min-hitlen 35
#      - 6: --min-hitlen 31
#      - 7: --min-hitlen 27
#      - 8: --min-hitlen 23
#      - 9: --min-hitlen 19


CPUS=4

for MODE in {1..9}; do
     source src/run_profilers/run_centrifuge.sh --mode $MODE --pass 2 --basename ARTIFICIAL \
          --f1 ${RESULTS_BOWTIE2_DATA}/artificial/ARTIFICIAL.unmapped.fastq.1.gz \
          --f2 ${RESULTS_BOWTIE2_DATA}/artificial/ARTIFICIAL.unmapped.fastq.2.gz

     source src/run_profilers/run_centrifuge.sh --mode $MODE --pass 0 --basename ARTIFICIAL \
          --f1 $CWD_DATA/data/artificial/artificial_reads_R1.fastq.gz \
          --f2 $CWD_DATA/data/artificial/artificial_reads_R2.fastq.gz
done


MODE=5
PASS=2
for NAME in 'ACIDOLA' 'BLACTIS'; do
     source /scratch/alexmascension/TAXPROF/src/run_profilers/run_centrifuge.sh --mode $MODE --pass $PASS --basename $NAME \
               --f1 ${RESULTS_BOWTIE2_DATA}/controls/$NAME.unmapped.fastq.1.gz \
               --f2 ${RESULTS_BOWTIE2_DATA}/controls/$NAME.unmapped.fastq.2.gz
done

for POOLN in {1..12}; do
     NAME="POOL${POOLN}"
     echo $NAME
     source /scratch/alexmascension/TAXPROF/src/run_profilers/run_centrifuge.sh --mode $MODE --pass $PASS --basename $NAME \
               --f1 ${RESULTS_BOWTIE2_DATA}/pools/$NAME.unmapped.fastq.1.gz \
               --f2 ${RESULTS_BOWTIE2_DATA}/pools/$NAME.unmapped.fastq.2.gz
done


# KRAKENUNIQ
#      - 1: --hll-precision 18
#      - 2: --hll-precision 17
#      - 3: --hll-precision 16
#      - 4: --hll-precision 15
#      - 5: --hll-precision 14
#      - 6: --hll-precision 13
#      - 7: --hll-precision 12 
#      - 8: --hll-precision 11
#      - 9: --hll-precision 10

for MODE in {1..9}; do
    source src/run_profilers/run_krakenuniq.sh --mode $MODE --pass 2 --basename ARTIFICIAL \
         --f1 ${RESULTS_BOWTIE2_DATA}/artificial/ARTIFICIAL.unmapped.fastq.1.gz \
         --f2 ${RESULTS_BOWTIE2_DATA}/artificial/ARTIFICIAL.unmapped.fastq.2.gz

     source src/run_profilers/run_krakenuniq.sh --mode $MODE --pass 0 --basename ARTIFICIAL \
         --f1 $CWD_DATA/data/artificial/artificial_reads_R1.fastq.gz \
          --f2 $CWD_DATA/data/artificial/artificial_reads_R2.fastq.gz
done

MODE=5
PASS=2
for NAME in 'ACIDOLA' 'BLACTIS'; do
     source /scratch/alexmascension/TAXPROF/src/run_profilers/run_krakenuniq.sh --mode $MODE --pass $PASS --basename $NAME \
               --f1 ${RESULTS_BOWTIE2_DATA}/controls/$NAME.unmapped.fastq.1.gz \
               --f2 ${RESULTS_BOWTIE2_DATA}/controls/$NAME.unmapped.fastq.2.gz
done

for POOLN in {1..12}; do
     NAME="POOL${POOLN}"
     echo $NAME
     source /scratch/alexmascension/TAXPROF/src/run_profilers/run_krakenuniq.sh --mode $MODE --pass $PASS --basename $NAME \
               --f1 ${RESULTS_BOWTIE2_DATA}/pools/$NAME.unmapped.fastq.1.gz \
               --f2 ${RESULTS_BOWTIE2_DATA}/pools/$NAME.unmapped.fastq.2.gz
done

# KRAKEN2
#      - 1: --confidence 0.9
#      - 2: --confidence 0.85
#      - 3: --confidence 0.8
#      - 4: --confidence 0.75
#      - 5: --confidence 0.7
#      - 6: --confidence 0.65
#      - 7: --confidence 0.6
#      - 8: --confidence 0.55
#      - 9: --confidence 0.5

for MODE in {1..9}; do
    source src/run_profilers/run_kraken2.sh --mode $MODE --pass 2 --basename ARTIFICIAL \
         --f1 ${RESULTS_BOWTIE2_DATA}/artificial/ARTIFICIAL.unmapped.fastq.1.gz \
         --f2 ${RESULTS_BOWTIE2_DATA}/artificial/ARTIFICIAL.unmapped.fastq.2.gz

     source src/run_profilers/run_kraken2.sh --mode $MODE --pass 0 --basename ARTIFICIAL \
         --f1 $CWD_DATA/data/artificial/artificial_reads_R1.fastq.gz \
          --f2 $CWD_DATA/data/artificial/artificial_reads_R2.fastq.gz
done


for NAME in 'ACIDOLA' 'BLACTIS'; do
     source /scratch/alexmascension/TAXPROF/src/run_profilers/run_kraken2.sh --mode $MODE --pass $PASS --basename $NAME \
               --f1 ${RESULTS_BOWTIE2_DATA}/controls/$NAME.unmapped.fastq.1.gz \
               --f2 ${RESULTS_BOWTIE2_DATA}/controls/$NAME.unmapped.fastq.2.gz
done

MODE=5
PASS=2
for POOLN in {1..12}; do
     NAME="POOL${POOLN}"
     echo $NAME
     source /scratch/alexmascension/TAXPROF/src/run_profilers/run_kraken2.sh --mode $MODE --pass $PASS --basename $NAME \
               --f1 ${RESULTS_BOWTIE2_DATA}/pools/$NAME.unmapped.fastq.1.gz \
               --f2 ${RESULTS_BOWTIE2_DATA}/pools/$NAME.unmapped.fastq.2.gz
done