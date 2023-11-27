#!/bin/bash
# TODO! : METER REFS DE STAR; RSEM Y SALMON


CWD='/data/Proyectos/EVs'
DATABASE_DIR="$CWD/database"
NUM_CPUS=20

mkdir -p $DATABASE_DIR/genome

# Human hg38 genome for nf-core/rnaseq
VERSION=109
wget -L ftp://ftp.ensembl.org/pub/release-$VERSION/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa.gz -P $DATABASE_DIR/genome
wget -L ftp://ftp.ensembl.org/pub/release-$VERSION/gtf/homo_sapiens/Homo_sapiens.GRCh38.$VERSION.gtf.gz -P $DATABASE_DIR/genome
gzip -d $DATABASE_DIR/genome/Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa.gz
gzip -d $DATABASE_DIR/genome/Homo_sapiens.GRCh38.$VERSION.gtf.gz



# Human CHM13 genome
cd $DATABASE_DIR/genome
curl -OJX GET "https://api.ncbi.nlm.nih.gov/datasets/v2alpha/genome/accession/GCF_009914755.1/download?include_annotation_type=GENOME_FASTA&filename=GCF_009914755.1.zip" -H "Accept: application/zip"
# Extract the .fna file!
unzip $DATABASE_DIR/genome/GCF_009914755.1.zip -d $DATABASE_DIR/genome
mv $DATABASE_DIR/genome/ncbi_dataset/data/GCF_009914755.1/GCF_009914755.1_T2T-CHM13v2.0_genomic.fna $DATABASE_DIR/genome/GCF_009914755.1_T2T-CHM13v2.0_genomic.fna
rm -r $DATABASE_DIR/genome/ncbi_dataset $DATABASE_DIR/genome/GCF_009914755.1.zip

mkdir -p $DATABASE_DIR/genome/index/bowtie2-chm13
bowtie2-build -f $DATABASE_DIR/genome/GCF_009914755.1_T2T-CHM13v2.0_genomic.fna $DATABASE_DIR/genome/index/bowtie2-chm13/bowtie2-chm13





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





# CREATE RANDOM READ FASTQ FILES
# We are going to create random reads using an artificial read generator, using reads from different species, as well as humans. 

KINGDOM	    GENUS	SPECIES	                TAXID	RELATIVE ABUNDANCE (95% is human)	N READS
Animal	    Homo	sapiens	                9606	0.95	47500000
Bacteria	Cutibacterium	acnes	        1747	0.0075	375000
Bacteria	Dietzia	maris	                37915	0.005	250000
Bacteria	Bifidobacterium	bifidum	        1681	0.005	250000
Bacteria	Lactobacillus	acidophilus	    1579	0.0025	125000
Bacteria	Bacteroides	fragilis	        817 	0.0025	125000
Bacteria	Roseburia	intestinalis	    166486	0.0025	125000
Bacteria	Stenotrophomonas	maltophilia	40324	0.0015	75000
Bacteria	Sphingomonas	paucimobilis	13689	0.0015	75000
Bacteria	Taylorella	equigenitalis	    29575	0.001	50000
Bacteria	Kinneretia	asaccharophila	    582607	0.0005	25000
Fungi	    Aspergillus	chevalieri	        182096	0.005	250000
Fungi	    Malassezia	restricta	        76775	0.0025	125000
Fungi	    Saccharomyces	cerevisiae	    4932	0.0025	125000
Fungi	    Plenodomus	lingam	            5022	0.0015	75000
Fungi	    Alternaria	alternata	        5599	0.0015	75000
Virus	    Burzaovirus	intestinihominis 	2955562	0.0025	125000
Virus	    Elvirus	EL	                    1984787	0.0015	75000
Virus	    Lentivirus	HIV1	            11676	0.0015	75000
Virus	    Nickievirus	nickie	            2560688	0.0015	75000
Virus	    Lymphocryptovirus	humangamma4	3050299	0.0005	25000




ncbi-genome-download -F fasta -p $NUM_CPUS -r 10 -T "9606" -o $DATABASE_DIR/artificial_reads_genomes/9606 -R reference --flat-output all
zcat $DATABASE_DIR/artificial_reads_genomes/9606/*.fna.gz > $DATABASE_DIR/artificial_reads_genomes/9606.fna

for TAXID in "1747" "37915" "1681" "1579" "817" "166486" "40324" "13689" "29575" "582607" "182096" "76775" "4932" "5022" "5599" "2955562" "1984787" "11676" "2560688" "3050299"
do  
    echo $TAXID
    ncbi-genome-download -F fasta -p $NUM_CPUS -r 10 -T "$TAXID" -o $DATABASE_DIR/artificial_reads_genomes/$TAXID --flat-output all
    zcat $DATABASE_DIR/artificial_reads_genomes/$TAXID/*.fna.gz > $DATABASE_DIR/artificial_reads_genomes/$TAXID.fna
    rm -rf $DATABASE_DIR/artificial_reads_genomes/$TAXID
done


TAXIDS=("9606" "1747" "37915" "1681" "1579" "817" "166486" "40324" "13689" "29575" "582607" "182096" "76775" "4932" "5022" "5599" "2955562" "1984787" "11676" "2560688" "3050299")
LENGTHS=(47500000 375000 250000 250000 125000 125000 125000 75000 75000 50000 25000 250000 125000 125000 75000 75000 125000 75000 75000 75000 25000)
NUM_CPUS=8
for ((i = 0; i < ${#TAXIDS[@]}; i++)); do
    TAXID="${TAXIDS[i]}"
    LENGTH="${LENGTHS[i]}"
    
    # Perform actions with $NAME and $AGE
    iss generate --genomes $DATABASE_DIR/artificial_reads_genomes/$TAXID.fna --model hiseq --output $DATABASE_DIR/artificial_reads_genomes/"$TAXID"_reads --cpus $NUM_CPUS --compress --n_reads $LENGTH --coverage lognormal
done

zcat $DATABASE_DIR/artificial_reads_genomes/*_reads_R1.fastq.gz > $DATABASE_DIR/artificial_reads_genomes/artificial_reads_R1.fastq
gzip $DATABASE_DIR/artificial_reads_genomes/artificial_reads_R1.fastq
zcat $DATABASE_DIR/artificial_reads_genomes/*_reads_R2.fastq.gz > $DATABASE_DIR/artificial_reads_genomes/artificial_reads_R2.fastq
gzip $DATABASE_DIR/artificial_reads_genomes/artificial_reads_R2.fastq

mkdir -p $CWD/data/artificial_reads
cp $DATABASE_DIR/artificial_reads_genomes/artificial_reads_R1.fastq.gz $CWD/data/artificial_reads/artificial_reads_R1.fastq.gz
cp $DATABASE_DIR/artificial_reads_genomes/artificial_reads_R2.fastq.gz $CWD/data/artificial_reads/artificial_reads_R2.fastq.gz
