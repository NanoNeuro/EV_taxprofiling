VERSION_ENSEMBLE_GENOME=109
CWD='/media/seth/SETH_DATA/Biodonostia_David/EVs'
DATABASE_DIR="$CWD/database"
NUM_CPUS=50
NUM_RAM='364.GB'


# 1) -profile  usar docker y, como last resort, conda
# 2) --
# 3) Incluir --star_index cuando se haya indexado por primera vez (HAY QUE MOVER EL ÍNDICE A LA CARPETA!!!)

nextflow run \
    nf-core/rnaseq \
    -r 3.11.2 \
    -profile docker \
    --input $CWD/samples_prueba.csv \
    --outdir results_rnaseq \
    --aligner star_salmon \
    --skip_bbsplit \
    --star_index $DATABASE_DIR/genome/index/star \
    --salmon_index $DATABASE_DIR/genome/index/salmon \
    --rsem_index $DATABASE_DIR/genome/rsem \
    --save_unaligned \
    --max_cpus $NUM_CPUS \
    --max_memory $NUM_RAM \
    -resume \
    --fasta $DATABASE_DIR/Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa.gz \
    --gtf $DATABASE_DIR/Homo_sapiens.GRCh38.$VERSION_ENSEMBLE_GENOME.gtf.gz \
    --save_reference 



    