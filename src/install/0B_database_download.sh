#!/bin/bash
CWD='/data/Proyectos/EVs'
DATABASE_DIR="$CWD/database"

VERSION=109
wget -L ftp://ftp.ensembl.org/pub/release-$VERSION/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa.gz -P $DATABASE_DIR
wget -L ftp://ftp.ensembl.org/pub/release-$VERSION/gtf/homo_sapiens/Homo_sapiens.GRCh38.$VERSION.gtf.gz -P $DATABASE_DIR

NUM_CPUS=20



# Human CHM13 genome
cd $DATABASE_DIR/genome
curl -OJX GET "https://api.ncbi.nlm.nih.gov/datasets/v2alpha/genome/accession/GCF_009914755.1/download?include_annotation_type=GENOME_FASTA&filename=GCF_009914755.1.zip" -H "Accept: application/zip"
# Extract the .fna file!
unzip $DATABASE_DIR/genome/GCF_009914755.1.zip -d $DATABASE_DIR/genome
mv $DATABASE_DIR/genome/ncbi_dataset/data/GCF_009914755.1/GCF_009914755.1_T2T-CHM13v2.0_genomic.fna $DATABASE_DIR/genome/GCF_009914755.1_T2T-CHM13v2.0_genomic.fna
rm -r $DATABASE_DIR/genome/ncbi_dataset




# Kaiju [DOES NOT CONTAIN HUMAN]
mkdir -p $DATABASE_DIR/kaiju
cd $DATABASE_DIR/kaiju
wget -L https://kaiju-idx.s3.eu-central-1.amazonaws.com/2023/kaiju_db_refseq_2023-05-23.tgz -O $DATABASE_DIR/kaiju/kaiju_refseq.tgz
tar xzvf $DATABASE_DIR/kaiju/kaiju_refseq.tgz -C $DATABASE_DIR/kaiju
wget -L https://kaiju-idx.s3.eu-central-1.amazonaws.com/2023/kaiju_db_fungi_2023-05-26.tgz -O $DATABASE_DIR/kaiju/kaiju_fungi.tgz
tar xzvf $DATABASE_DIR/kaiju/kaiju_fungi.tgz -C $DATABASE_DIR/kaiju





# Kaiju [WITH HUMAN - FROM BATCH]
mkdir -p $DATABASE_DIR/kaiju
cd $DATABASE_DIR/kaiju
ncbi_param_r=10
ncbi-genome-download -F protein-fasta -p $NUM_CPUS -r $ncbi_param_r -P archaea,bacteria,fungi,protozoa,viral
ncbi-genome-download -F protein-fasta -p $NUM_CPUS -r $ncbi_param_r -P vertebrate_mammalian -t "9606,10090"

## Merge the faa files [Non-parallelised]
zcat refseq/*.faa.gz > combined_faa.faa

## Merge the faa files [Parallelised]
# Iterate through all .faa files and run zcat processes in parallel  [HACER ESTO BIEN!!!]
for file in $(find . -type f -name "*.faa.gz"); do
    zcat "$file" >> "combined.faa" &
done
wait

## Download taxdump files
wget -P . https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/new_taxdump/new_taxdump.tar.gz
tar xvf new_taxdump.tar.gz

# 3.5 RUN KAIJU TO MOUNT THE INDEX
kaiju-mkbwt -n 5 -a ACDEFGHIKLMNPQRSTVWY -infilename combined.faa -o kaiju_combined
kaiju-mkfmi kaiju_combined






# Kraken 2  FROM https://benlangmead.github.io/aws-indexes/k2  [HUMAN | ARCHAEA | BACTERIA | VIRAL | PLASMID | PROTOZOA | FUNGI]
mkdir -p $DATABASE_DIR/kraken_2
wget -L https://genome-idx.s3.amazonaws.com/kraken/k2_pluspf_20230314.tar.gz -O $DATABASE_DIR/kraken_2/kraken_2_db.tar.gz
wget -L https://genome-idx.s3.amazonaws.com/kraken/pluspf_20230314/inspect.txt -O $DATABASE_DIR/kraken_2/kraken_2_db_inspect.txt
tar xvf $DATABASE_DIR/kraken_2/kraken_2_db.tar.gz -C $DATABASE_DIR/kraken_2






# Krakenuniq https://github.com/fbreitwieser/krakenuniq  [HUMAN | ARCHAEA | BACTERIA | VIRAL | UNIVEC_CORE]
mkdir -p $DATABASE_DIR/krakenuniq
aws s3 cp s3://genome-idx/kraken/uniq/krakendb-2022-06-16-STANDARD/kuniq_standard_minus_kdb.20220616.tgz $DATABASE_DIR/krakenuniq/kuniq_standard_minus_kdb.20220616.tgz
aws s3 cp s3://genome-idx/kraken/uniq/krakendb-2022-06-16-STANDARD/database.kdb $DATABASE_DIR/krakenuniq/database.kdb
tar xvf $DATABASE_DIR/krakenuniq/kuniq_standard_minus_kdb.20220616.tgz -C $DATABASE_DIR/krakenuniq






# Centrifuge FROM https://ccb.jhu.edu/software/centrifuge/  [HUMAN | ARCHAEA? | BACTERIA | VIRAL | FUNGI?] - NCBI nucleotide non-redundant sequences
mkdir -p $DATABASE_DIR/centrifuge
aws s3 cp s3://genome-idx/centrifuge/nt_2018_3_3.tar.gz $DATABASE_DIR/centrifuge/nt_2018_3_3.tar.gz
tar -xvf $DATABASE_DIR/centrifuge/nt_2018_3_3.tar.gz -C $DATABASE_DIR/centrifuge






# THIS CODE BELOW WAS EXTREMELY SLOW AND I WAS NOT SURE THAT THE DATABASE WOULD FIT IN RAM
# # Centrifuge is built with the same components as krakenuniq. So, we are going to run first krakenuniq and the use their files
# # to build the centrifuge databe. Also, the download of some of the elements from centrifuge failed, so we make sure that this
# # one goes well to do it.

# cd $DATABASE_DIR/krakenuniq/library
# find . -type f -name "*.fna" -exec cat {} \; > $DATABASE_DIR/centrifuge/input-sequences.fna

# ## build centrifuge index 
# centrifuge-build -p 20 --bmax 83886080 \
#                  --conversion-table $DATABASE_DIR/krakenuniq/seqid2taxid.map \
#                  --taxonomy-tree $DATABASE_DIR/krakenuniq/taxonomy/nodes.dmp \
#                  --name-table $DATABASE_DIR/krakenuniq/taxonomy/names.dmp \
#                  $DATABASE_DIR/centrifuge/input-sequences.fna abv

#After the index building, all but the *.[123].cf index files may be removed. I.e. the files in the library/ and taxonomy/ directories are no longer needed.





# MetaPhlan 
# WARNING!! This configuration may probably fail (not be recognised by metaphlan), although the running configuration 
# seems to work.
mkdir -p $DATABASE_DIR/metaphlan
mkdir -p $DATABASE_DIR/metaphlan/bowtie2

wget -L http://cmprod1.cibio.unitn.it/biobakery4/metaphlan_databases/bowtie2_indexes/mpa_vOct22_CHOCOPhlAnSGB_202212_bt2.md5 \
     -O $DATABASE_DIR/metaphlan/bowtie2/mpa_vOct22_CHOCOPhlAnSGB_202212_bt2.md5
wget -L http://cmprod1.cibio.unitn.it/biobakery4/metaphlan_databases/bowtie2_indexes/mpa_vOct22_CHOCOPhlAnSGB_202212_bt2.tar \
        -O $DATABASE_DIR/metaphlan/bowtie2/mpa_vOct22_CHOCOPhlAnSGB_202212_bt2.tar

wget -L http://cmprod1.cibio.unitn.it/biobakery4/metaphlan_databases/mpa_vOct22_CHOCOPhlAnSGB_202212.md5 \
        -O $DATABASE_DIR/metaphlan/mpa_vOct22_CHOCOPhlAnSGB_202212.md5
wget -L http://cmprod1.cibio.unitn.it/biobakery4/metaphlan_databases/mpa_vOct22_CHOCOPhlAnSGB_202212.tar \
        -O $DATABASE_DIR/metaphlan/mpa_vOct22_CHOCOPhlAnSGB_202212.tar
wget -L http://cmprod1.cibio.unitn.it/biobakery4/metaphlan_databases/mpa_vOct22_CHOCOPhlAnSGB_202212_marker_info.txt.bz2 \
        -O $DATABASE_DIR/metaphlan/mpa_vOct22_CHOCOPhlAnSGB_202212_marker_info.txt.bz2
wget -L http://cmprod1.cibio.unitn.it/biobakery4/metaphlan_databases/mpa_vOct22_CHOCOPhlAnSGB_202212_species.txt.bz2 \
        -O $DATABASE_DIR/metaphlan/mpa_vOct22_CHOCOPhlAnSGB_202212_species.txt.bz2

tar xf $DATABASE_DIR/metaphlan/bowtie2/mpa_vOct22_CHOCOPhlAnSGB_202212_bt2.tar -C $DATABASE_DIR/metaphlan/bowtie2



# Bracken
# We have tried to build bracken databases with all programs (krakenuniq-build, braken2-build) 
# but there is always some point where it fails. So, considering that bracken2 is not a metaprofiler per se
# but a "corrector" of metaprofiling results, we will not use it.



# TAXPASTA
# Download .dmp files
mkdir -p $DATABASE_DIR/taxpasta
wget ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz -O $DATABASE_DIR/taxpasta/taxdump.tar.gz

tar xvf $DATABASE_DIR/taxpasta/taxdump.tar.gz -C $DATABASE_DIR/taxpasta/
