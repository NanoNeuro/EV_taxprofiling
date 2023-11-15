#!/bin/bash
CWD='/data/Proyectos/EVs'
DATABASE_DIR="$CWD/database"
NUM_CPUS=20

VERSION=109
wget -L ftp://ftp.ensembl.org/pub/release-$VERSION/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa.gz -P $DATABASE_DIR
wget -L ftp://ftp.ensembl.org/pub/release-$VERSION/gtf/homo_sapiens/Homo_sapiens.GRCh38.$VERSION.gtf.gz -P $DATABASE_DIR




# Human CHM13 genome
cd $DATABASE_DIR/genome
curl -OJX GET "https://api.ncbi.nlm.nih.gov/datasets/v2alpha/genome/accession/GCF_009914755.1/download?include_annotation_type=GENOME_FASTA&filename=GCF_009914755.1.zip" -H "Accept: application/zip"
# Extract the .fna file!
unzip $DATABASE_DIR/genome/GCF_009914755.1.zip -d $DATABASE_DIR/genome
mv $DATABASE_DIR/genome/ncbi_dataset/data/GCF_009914755.1/GCF_009914755.1_T2T-CHM13v2.0_genomic.fna $DATABASE_DIR/genome/GCF_009914755.1_T2T-CHM13v2.0_genomic.fna
rm -r $DATABASE_DIR/genome/ncbi_dataset




# Kaiju [HUMAN | ARCHAEA | BACTERIA | VIRAL | PLASMID | PROTOZOA? | FUNGI]
## We will download specific databases (we tried to create one from scratch, but the identifiers in the FASTAs were not the taxon ID but the protein IDs and was a PITA to do the changes), 
## and we will also create a human one.
mkdir -p $DATABASE_DIR/kaiju
cd $DATABASE_DIR/kaiju
wget -L https://kaiju-idx.s3.eu-central-1.amazonaws.com/2023/kaiju_db_refseq_2023-05-23.tgz -O $DATABASE_DIR/kaiju/kaiju_refseq.tgz
tar xzvf $DATABASE_DIR/kaiju/kaiju_refseq.tgz -C $DATABASE_DIR/kaiju
mv $DATABASE_DIR/kaiju/kaiju_db_refseq.fmi $DATABASE_DIR/kaiju/kaiju_refseq.fmi 

wget -L https://kaiju-idx.s3.eu-central-1.amazonaws.com/2023/kaiju_db_fungi_2023-05-26.tgz -O $DATABASE_DIR/kaiju/kaiju_fungi.tgz
tar xzvf $DATABASE_DIR/kaiju/kaiju_fungi.tgz -C $DATABASE_DIR/kaiju
mv $DATABASE_DIR/kaiju/kaiju_db_fungi.fmi $DATABASE_DIR/kaiju/kaiju_fungi.fmi 

wget -L https://kaiju-idx.s3.eu-central-1.amazonaws.com/2023/kaiju_db_plasmids_2023-05-26.tgz -O $DATABASE_DIR/kaiju/kaiju_plasmids.tgz
tar xzvf $DATABASE_DIR/kaiju/kaiju_plasmids.tgz -C $DATABASE_DIR/kaiju
mv $DATABASE_DIR/kaiju/kaiju_db_plasmids.fmi $DATABASE_DIR/kaiju/kaiju_plasmids.fmi 

## Create human database
ncbi_param_r=10
ncbi-genome-download -F protein-fasta -p $NUM_CPUS -r $ncbi_param_r -P vertebrate_mammalian -t "9606" -R reference

# Change headers of fasta to NCBI taxon ID (9606)
zcat $(find refseq -type f -name '*.faa.gz') | sed 's/^>.*$/>9606/' > combined.faa

kaiju-mkbwt -n $NUM_CPUS -a ACDEFGHIKLMNPQRSTVWY -infilename combined.faa -o kaiju_human
kaiju-mkfmi kaiju_human




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






# Centrifuge FROM https://ccb.jhu.edu/software/centrifuge/  [HUMAN | ARCHAEA | BACTERIA | VIRAL | FUNGI | PLASMID] - NCBI nucleotide non-redundant sequences
# For this profiler, we are going to download/build three different indexes:
# 1) p+h+v: it contains archea, bacteria, virus and human sequences
# 2) f+g: it contains fungi and protozoa sequences
# These two indexes are downloaded to run them separately. We decided not to build this index from scratch because the database
# was too large to fit in memory
# We will download a third index, the nt_2018 index, which contains several sequences from the NCBI nucleotide database. This index
# will be used to create the kraken-like report by combining the classification reports using the 1) and 2) indexes separately.
# We use this third index because it contains many taxons that are already in 1) and 2); but we don't use it for classification
# because the index was sometimes too big to fit in the memory (depending on the number of CPUs), and it took too long to run.


mkdir -p $DATABASE_DIR/centrifuge
# THIS INDEX WAS TOO BIG
aws s3 cp s3://genome-idx/centrifuge/nt_2018_3_3.tar.gz $DATABASE_DIR/centrifuge/nt_2018_3_3.tar.gz
tar -xvf $DATABASE_DIR/centrifuge/nt_2018_3_3.tar.gz -C $DATABASE_DIR/centrifuge

# We are going to download the human + archaea + bacteria + viral, and create a new index with fungi and protozoa
aws s3 cp s3://genome-idx/centrifuge/p+h+v.tar.gz $DATABASE_DIR/centrifuge/p+h+v.tar.gz
tar -xvf $DATABASE_DIR/centrifuge/p+h+v.tar.gz -C $DATABASE_DIR/centrifuge

centrifuge-download -o taxonomy taxonomy
centrifuge-download -o library -P $NUM_CPUS -m -d "fungi,protozoa" -a Any refseq > seqid2taxid.map

cat library/*/*.fna > input-sequences.fna

centrifuge-build -p $NUM_CPUS --conversion-table seqid2taxid.map \
                 --taxonomy-tree taxonomy/nodes.dmp --name-table taxonomy/names.dmp \
                 input-sequences.fna f+p



# TAXPASTA
# Download .dmp files
mkdir -p $DATABASE_DIR/taxpasta
wget ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz -O $DATABASE_DIR/taxpasta/taxdump.tar.gz

tar xvf $DATABASE_DIR/taxpasta/taxdump.tar.gz -C $DATABASE_DIR/taxpasta/
