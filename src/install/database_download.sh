#!/bin/bash
DATABASE_DIR='database'

VERSION=109
wget -L ftp://ftp.ensembl.org/pub/release-$VERSION/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa.gz -P $DATABASE_DIR
wget -L ftp://ftp.ensembl.org/pub/release-$VERSION/gtf/homo_sapiens/Homo_sapiens.GRCh38.$VERSION.gtf.gz -P $DATABASE_DIR



# Kraken 2  FROM https://benlangmead.github.io/aws-indexes/k2
wget -L https://genome-idx.s3.amazonaws.com/kraken/k2_pluspf_20230314.tar.gz -O $DATABASE_DIR/kraken_2_db.tar.gz
wget -L https://genome-idx.s3.amazonaws.com/kraken/pluspf_20230314/inspect.txt -O $DATABASE_DIR/kraken_2_db_inspect.txt




# Centrifuge FROM https://ccb.jhu.edu/software/centrifuge/
wget -L https://genome-idx.s3.amazonaws.com/centrifuge/p%2Bh%2Bv.tar.gz -O $DATABASE_DIR/centrifuge.tar.gz

centrifuge-download -o $DATABASE_DIR/centrifuge/taxonomy taxonomy
centrifuge-download -o $DATABASE_DIR/centrifuge/library -m -d "archaea,bacteria,viral,fungi" refseq > $DATABASE_DIR/centrifuge/seqid2taxid.map
centrifuge-download -o $DATABASE_DIR/centrifugelibrary -d "vertebrate_mammalian" -a "Chromosome" -t 9606,10090 -c 'reference genome' >> $DATABASE_DIR/centrifuge/seqid2taxid.map

cat $DATABASE_DIR/library/*/*.fna > $DATABASE_DIR/centrifuge/input-sequences.fna

## build centrifuge index with 4 threads
centrifuge-build -p 4 --conversion-table $DATABASE_DIR/centrifuge/seqid2taxid.map \
                 --taxonomy-tree $DATABASE_DIR/taxonomy/nodes.dmp --name-table $DATABASE_DIR/taxonomy/names.dmp \
                 $DATABASE_DIR/centrifuge/input-sequences.fna abv

#After the index building, all but the *.[123].cf index files may be removed. I.e. the files in the library/ and taxonomy/ directories are no longer needed.



# MetaPhlan creates the index on the run, so no download is needed!?
metaphlan --install --bowtie2db $DATABASE_DIR/metaphlan
