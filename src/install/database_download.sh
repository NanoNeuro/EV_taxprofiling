#!/bin/bash
CWD='/media/seth/SETH_DATA/Biodonostia_David/EVs'
DATABASE_DIR="$CWD/database"

VERSION=109
wget -L ftp://ftp.ensembl.org/pub/release-$VERSION/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa.gz -P $DATABASE_DIR
wget -L ftp://ftp.ensembl.org/pub/release-$VERSION/gtf/homo_sapiens/Homo_sapiens.GRCh38.$VERSION.gtf.gz -P $DATABASE_DIR


# Kaiju
mkdir -p $DATABASE_DIR/kaiju
cd $DATABASE_DIR/kaiju
wget -L https://kaiju.binf.ku.dk/database/kaiju_db_refseq_2022-03-23.tgz -O $DATABASE_DIR/kaiju/kaiju_refseq.tgz
tar xzvf $DATABASE_DIR/kaiju/kaiju_refseq.tgz -C $DATABASE_DIR/kaiju
wget -L https://kaiju.binf.ku.dk/database/kaiju_db_fungi_2022-03-29.tgz -O $DATABASE_DIR/kaiju/kaiju_fungi.tgz
tar xzvf $DATABASE_DIR/kaiju/kaiju_fungi.tgz -C $DATABASE_DIR/kaiju






# Kraken 2  FROM https://benlangmead.github.io/aws-indexes/k2
mkdir -p $DATABASE_DIR/kraken_2
wget -L https://genome-idx.s3.amazonaws.com/kraken/k2_pluspf_20230314.tar.gz -O $DATABASE_DIR/kraken_2/kraken_2_db.tar.gz
wget -L https://genome-idx.s3.amazonaws.com/kraken/pluspf_20230314/inspect.txt -O $DATABASE_DIR/kraken_2/kraken_2_db_inspect.txt
tar xvf $DATABASE_DIR/kraken_2/kraken_2_db.tar.gz -C $DATABASE_DIR/kraken_2







# Krakenuniq https://github.com/fbreitwieser/krakenuniq
mkdir -p $DATABASE_DIR/krakenuniq
aws s3 cp s3://genome-idx/kraken/uniq/krakendb-2022-06-16-STANDARD/kuniq_standard_minus_kdb.20220616.tgz $DATABASE_DIR/krakenuniq/kuniq_standard_minus_kdb.20220616.tgz
aws s3 cp s3://genome-idx/kraken/uniq/krakendb-2022-06-16-STANDARD/database.kdb $DATABASE_DIR/krakenuniq/database.kdb
tar xvf $DATABASE_DIR/krakenuniq/kuniq_standard_minus_kdb.20220616.tgz -C $DATABASE_DIR/krakenuniq






# Centrifuge FROM https://ccb.jhu.edu/software/centrifuge/
mkdir -p $DATABASE_DIR/centrifuge
aws s3 cp s3://genome-idx/centrifuge/p+h+v.tar.gz $DATABASE_DIR/centrifuge/centrifuge.tar.gz

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
