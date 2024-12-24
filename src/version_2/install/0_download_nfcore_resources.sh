source src/list_vars.sh

# Download hg38
wget -L https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.40_GRCh38.p14/GCF_000001405.40_GRCh38.p14_genomic.fna.gz -P $DB_GENOMES_NFCORE
wget -L https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.40_GRCh38.p14/GCF_000001405.40_GRCh38.p14_cds_from_genomic.fna.gz -P $DB_GENOMES_NFCORE
wget -L https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.40_GRCh38.p14/GCF_000001405.40_GRCh38.p14_genomic.gtf.gz -P $DB_GENOMES_NFCORE
gzip -d $DB_GENOMES_NFCORE/GCF_000001405.40_GRCh38.p14_genomic.fna.gz
gzip -d $DB_GENOMES_NFCORE/GCF_000001405.40_GRCh38.p14_cds_from_genomic.fna.gz
gzip -d $DB_GENOMES_NFCORE/GCF_000001405.40_GRCh38.p14_genomic.gtf.gz


# Building nf.core indexes
## STAR
STAR \
        --runMode genomeGenerate \
        --genomeDir $DB_INDEXES_NFCORE/star \
        --genomeFastaFiles $DB_GENOMES_NFCORE/GCF_000001405.40_GRCh38.p14_genomic.fna \
        --sjdbGTFfile $DB_GENOMES_NFCORE/GCF_000001405.40_GRCh38.p14_genomic.gtf \
        --runThreadN $CPUS \
        --genomeSAindexNbases 14


## salmon
salmon index \
            -p $CPUS \
            -t $DB_GENOMES_NFCORE/GCF_000001405.40_GRCh38.p14_cds_from_genomic.fna \
            -i $DB_INDEXES_NFCORE/salmon \



# Download CHM13
wget -L https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/009/914/755/GCF_009914755.1_T2T-CHM13v2.0/GCF_009914755.1_T2T-CHM13v2.0_genomic.fna.gz	 -P $DB_GENOMES_NFCORE
gzip -d $DB_GENOMES_NFCORE/GCF_009914755.1_T2T-CHM13v2.0_genomic.fna.gz



mkdir -p $DB_INDEXES_NFCORE/bowtie2-chm13
bowtie2-build --threads $CPUS \
              -f $DB_GENOMES_NFCORE/GCF_009914755.1_T2T-CHM13v2.0_genomic.fna \
              $DB_INDEXES_NFCORE/bowtie2-chm13/bowtie2-chm13

