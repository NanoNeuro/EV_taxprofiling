source src/list_vars.sh

# GENERAL - This will be the main downloading point
# In general we are going to use complete and chromosome because the number of species retrieve is very high in general.
# However, in fungi the number of species is quite low, and most are assembled in the scaffold category, so we are going to use it also
ncbi-genome-download -F protein-fasta,fasta -p ${CPUS} -r 10 -P -t "9606"  -l complete -o ${BASEDIR_PROFILER_DB}/GENERAL/human --flat-output -m ${BASEDIR_PROFILER_DB}/GENERAL/human/table_human.txt vertebrate_mammalian 
ncbi-genome-download -F protein-fasta,fasta -p ${CPUS} -r 10 -P -l complete,chromosome -o ${BASEDIR_PROFILER_DB}/GENERAL/archaea  --flat-output -m ${BASEDIR_PROFILER_DB}/GENERAL/archaea/table_archaea.txt  archaea
ncbi-genome-download -F protein-fasta,fasta -p ${CPUS} -r 10 -P -l complete,chromosome -o ${BASEDIR_PROFILER_DB}/GENERAL/bacteria --flat-output -m ${BASEDIR_PROFILER_DB}/GENERAL/bacteria/table_bacteria.txt bacteria
ncbi-genome-download -F protein-fasta,fasta -p ${CPUS} -r 10 -P  -l complete,chromosome,scaffold -o ${BASEDIR_PROFILER_DB}/GENERAL/fungi --flat-output -m ${BASEDIR_PROFILER_DB}/GENERAL/fungi/table_fungi.txt fungi
ncbi-genome-download -F protein-fasta,fasta -p ${CPUS} -r 10 -P  -l complete,chromosome -o ${BASEDIR_PROFILER_DB}/GENERAL/protozoa --flat-output -m ${BASEDIR_PROFILER_DB}/GENERAL/protozoa/table_protozoa.txt protozoa
ncbi-genome-download -F protein-fasta,fasta -p ${CPUS} -r 10 -P  -l complete,chromosome -o ${BASEDIR_PROFILER_DB}/GENERAL/viral --flat-output -m ${BASEDIR_PROFILER_DB}/GENERAL/viral/table_viral.txt viral

# univec (WE HAVE TRIED BUT IT FAILS TO BE DETECTED WHEN RUNNING THE PROFILERS)
# mkdir ${BASEDIR_PROFILER_DB}/GENERAL/univec
# wget -O "${BASEDIR_PROFILER_DB}/GENERAL/univec/GCF_000000000.0_univec_genomic.fna.masked" --quiet --show-progress "ftp://ftp.ncbi.nlm.nih.gov/pub/UniVec/UniVec" 
# echo -e "assembly_accession\ttaxid\nGCF_000000000.0\t81077" > ${BASEDIR_PROFILER_DB}/GENERAL/univec/table_univec.txt
# # we are going to translate all the sequences from univec to the possible ORFs. This is because some aligners require protein sequences
# # and this method ensures that all DBs are equal across profilers
# python $CWD/src/translate_univec_fasta.py ${BASEDIR_PROFILER_DB}/GENERAL/univec/GCF_000000000.0_univec_genomic.fna.masked ${BASEDIR_PROFILER_DB}/GENERAL/univec/GCF_000000000.0_univec_protein.faa.masked


# Download the taxonomy
mkdir -p ${BASEDIR_PROFILER_DB}/GENERAL/taxonomy
wget https://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz -P ${BASEDIR_PROFILER_DB}/GENERAL/taxonomy
gzip -d ${BASEDIR_PROFILER_DB}/GENERAL/taxonomy/taxdump.tar.gz
tar -xvf ${BASEDIR_PROFILER_DB}/GENERAL/taxonomy/taxdump.tar
rm ${BASEDIR_PROFILER_DB}/GENERAL/taxdump.tar.gz


wget  https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/nucl_gb.accession2taxid.gz -P ${BASEDIR_PROFILER_DB}/GENERAL/taxonomy
gzip -d ${BASEDIR_PROFILER_DB}/GENERAL/taxonomy/nucl_gb.accession2taxid.gz
rm ${BASEDIR_PROFILER_DB}/GENERAL/nucl_gb.accession2taxid.gz

wget  https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.gz  -P ${BASEDIR_PROFILER_DB}/GENERAL/taxonomy
gzip -d ${BASEDIR_PROFILER_DB}/GENERAL/taxonomy/prot.accession2taxid.gz
rm ${BASEDIR_PROFILER_DB}/GENERAL/prot.accession2taxid.gz




# Mask the fna files
folder="${BASEDIR_PROFILER_DB}/GENERAL/"

# Count total files to process for progress tracking
total_files=$(find "$folder" -type f \( -name "*_genomic.fna.gz" -o -name "*_protein.faa.gz" \) | wc -l)
current_file=0

# Process each file found
find "$folder" -type f \( -name "*_genomic.fna.gz" -o -name "*_protein.faa.gz" \) | while read -r file; do
    # Update the file counter
    current_file=$((current_file + 1))

    # Unzip the file
    unzipped_file="${file%.gz}"
    gzip -d "$file"
    
    # Check if unzipping was successful
    if [[ ! -f "$unzipped_file" ]]; then
        echo "[$current_file/$total_files] Error: Failed to unzip $file. Skipping this file."
        continue
    fi

    # Determine the output file based on file type
    if [[ "$file" == *_genomic.fna.gz ]]; then
        output_file="${unzipped_file%.fna}.masked.fna"
        dustmasker -in "$unzipped_file" -out "$output_file" -outfmt fasta
    elif [[ "$file" == *_protein.faa.gz ]]; then
        output_file="${unzipped_file%.faa}.masked.faa"
        segmasker -in "$unzipped_file" -out "$output_file" -outfmt fasta
    fi
    
    # Check if the masking step was successful
    if [[ -f "$output_file" ]]; then
        echo "[$current_file/$total_files] Masking completed: $output_file"
    else
        echo "[$current_file/$total_files] Error: Masking failed for $unzipped_file."
    fi

    # Clean up the unzipped file
    # echo "[$current_file/$total_files] Removing temporary file: $unzipped_file"
    rm "$unzipped_file"
    
    gzip $output_file

done

echo "Processing completed for all files in $folder."









# KAIJU
mkdir ${BASEDIR_PROFILER_DB}/KAIJU

python $CWD/src/build_pys/build_kaiju.py --input_dir ${BASEDIR_PROFILER_DB}/GENERAL --output ${BASEDIR_PROFILER_DB}/KAIJU --groups archaea,bacteria,human,fungi,protozoa,viral --masked

kaiju-mkbwt -n 5 -a ACDEFGHIKLMNPQRSTVWY -o ${BASEDIR_PROFILER_DB}/KAIJU/proteins ${BASEDIR_PROFILER_DB}/KAIJU/library.faa
kaiju-mkfmi ${BASEDIR_PROFILER_DB}/KAIJU/proteins

rm ${BASEDIR_PROFILER_DB}/KAIJU/library.faa ${BASEDIR_PROFILER_DB}/KAIJU/proteins.sa ${BASEDIR_PROFILER_DB}/KAIJU/proteins.bwt







# GANON
mkdir -p ${BASEDIR_PROFILER_DB}/GANON

python $CWD/src/build_pys/build_ganon.py --input_dir ${BASEDIR_PROFILER_DB}/GENERAL --output ${BASEDIR_PROFILER_DB}/GANON --groups archaea,bacteria,human,fungi,protozoa,viral --masked
ganon build-custom --input-file ${BASEDIR_PROFILER_DB}/GANON/input_file.tsv --taxonomy-files ${BASEDIR_PROFILER_DB}/GENERAL/taxonomy/nodes.dmp ${BASEDIR_PROFILER_DB}/GENERAL/taxonomy/names.dmp \
    --db-prefix ${BASEDIR_PROFILER_DB}/GANON/db --threads ${DB_BUILD_CPUS} --input-extension fna.gz

rm -rf ${BASEDIR_PROFILER_DB}/GANON/fasta_files





mkdir -p ${BASEDIR_PROFILER_DB}/GANON_FUNGI

python $CWD/src/build_pys/build_ganon.py --input_dir ${BASEDIR_PROFILER_DB}/GENERAL --output ${BASEDIR_PROFILER_DB}/GANON_FUNGI --groups fungi --masked
ganon build-custom --input-file ${BASEDIR_PROFILER_DB}/GANON_FUNGI/input_file.tsv --taxonomy-files ${BASEDIR_PROFILER_DB}/GENERAL/taxonomy/nodes.dmp ${BASEDIR_PROFILER_DB}/GENERAL/taxonomy/names.dmp \
    --db-prefix ${BASEDIR_PROFILER_DB}/GANON_FUNGI/db --threads ${CPUS} --input-extension fna.gz

rm -rf ${BASEDIR_PROFILER_DB}/GANON_FUNGI/fasta_files







# KMCP
mkdir -p ${BASEDIR_PROFILER_DB}/KMCP

python $CWD/src/build_pys/build_kmcp.py --input_dir ${BASEDIR_PROFILER_DB}/GENERAL --output ${BASEDIR_PROFILER_DB}/KMCP --groups archaea,bacteria,human,fungi,protozoa,viral --masked
kmcp compute --in-dir ${BASEDIR_PROFILER_DB}/GENERAL \
    --kmer $KMER \
    --threads ${DB_BUILD_CPUS} \
    --out-dir ${BASEDIR_PROFILER_DB}/${KMCPDIR}KMERS

kmcp index -I ${BASEDIR_PROFILER_DB}/${KMCPDIR}KMERS \
    --threads ${DB_BUILD_CPUS} \
    --force \
    --false-positive-rate 0.3 \
    --out-dir ${BASEDIR_PROFILER_DB}/KMCP

# We run it again because we force overwrite with the index command
python $CWD/src/build_pys/build_kmcp.py --input_dir ${BASEDIR_PROFILER_DB}/GENERAL --output ${BASEDIR_PROFILER_DB}/KMCP --groups archaea,bacteria,human,fungi,protozoa,viral --masked

rm -rf ${BASEDIR_PROFILER_DB}/${KMCPDIR}KMERS





# KRAKEN2
mkdir ${BASEDIR_PROFILER_DB}/KRAKEN2

kraken2-build --download-taxonomy --db ${BASEDIR_PROFILER_DB}/KRAKEN2
python $CWD/src/build_kraken2_db.py --input_dir ${BASEDIR_PROFILER_DB}/GENERAL --output_dir ${BASEDIR_PROFILER_DB}/${KRAKEN2DIR}_FNAS --groups archaea,bacteria,human,fungi,protozoa,viral  --masked
kraken2-build --add-to-library ${BASEDIR_PROFILER_DB}/${KRAKEN2DIR}_FNAS/library.fna --db ${BASEDIR_PROFILER_DB}/KRAKEN2
kraken2-build --build --kmer-len $KMER --threads ${DB_BUILD_CPUS} --db ${BASEDIR_PROFILER_DB}/KRAKEN2
rm -rf ${BASEDIR_PROFILER_DB}/${KRAKEN2DIR}_FNAS
rm -rf ${BASEDIR_PROFILER_DB}/KRAKEN2/library






# CENTRIFUGE 
mkdir ${BASEDIR_PROFILER_DB}/CENTRIFUGE

python $CWD/src/build_pys/build_centrifuge.py --input_dir ${BASEDIR_PROFILER_DB}/GENERAL --output ${BASEDIR_PROFILER_DB}/CENTRIFUGE/seqid2taxid.map --groups archaea,bacteria,human,fungi,protozoa,viral --masked
find "${BASEDIR_PROFILER_DB}/GENERAL/" -name "*_genomic.masked.fna.gz" -print0 | xargs -0 zcat > "${BASEDIR_PROFILER_DB}/${CENTRIFUGEDIR}/sequences.fa"
centrifuge-build --conversion-table ${BASEDIR_PROFILER_DB}/CENTRIFUGE/seqid2taxid.map \
                --taxonomy-tree ${BASEDIR_PROFILER_DB}/GENERAL/taxonomy/nodes.dmp    \
                --name-table ${BASEDIR_PROFILER_DB}/GENERAL/taxonomy/names.dmp \
                -p ${DB_BUILD_CPUS} \
                ${BASEDIR_PROFILER_DB}/CENTRIFUGE/sequences.fa ${BASEDIR_PROFILER_DB}/CENTRIFUGE/customdb
rm ${BASEDIR_PROFILER_DB}/CENTRIFUGE/library/sequences.fa 






# KRAKENUNIQ
mkdir ${BASEDIR_PROFILER_DB}/KRAKENUNIQ

krakenuniq-download --db ${BASEDIR_PROFILER_DB}/KRAKENUNIQ taxonomy
python $CWD/src/build_pys/build_centrifuge.py --input_dir ${BASEDIR_PROFILER_DB}/GENERAL --output ${BASEDIR_PROFILER_DB}/KRAKENUNIQ/library/seqid2taxid.map --groups archaea,bacteria,human,fungi,protozoa,viral --masked
find "${BASEDIR_PROFILER_DB}/GENERAL/" -name "*_genomic.masked.fna.gz" -print0 | xargs -0 zcat > "${BASEDIR_PROFILER_DB}/${KRAKENUNIQDIR}/library/sequences.fa"
krakenuniq-build --db ${BASEDIR_PROFILER_DB}/KRAKENUNIQ --threads ${DB_BUILD_CPUS} --kmer-len $KMER --jellyfish-bin $(which jellyfish)
rm ${BASEDIR_PROFILER_DB}/KRAKENUNIQ/library/sequences.fa 


