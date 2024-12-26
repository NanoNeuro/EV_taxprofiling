source src/list_vars.sh

# Create an empty TAXIDS and LENGTHS arrays
TAXIDS=()
LENGTHS=()

# Parse the Table_taxID.csv file to populate TAXIDS and LENGTHS
while IFS=';' read -r species taxid n_reads
do
    # Strip any trailing carriage return from each field
    taxid=$(echo "$taxid" | tr -d '\r' | xargs)
    n_reads=$(echo "$n_reads" | tr -d '\r' | xargs)
    
    # Add taxid and n_reads to arrays if they are non-empty
    if [[ -n "$taxid" && -n "$n_reads" ]]; then
        TAXIDS+=("$taxid")
        LENGTHS+=("$n_reads")
    else
        echo "Warning: Skipping invalid line with missing fields: species=\"$species\", taxid=\"$taxid\", n_reads=\"$n_reads\""
    fi
done < <(tr -d '\r' < $CWD/src/table_artificial_taxid.csv)  # Ensure all lines are cleaned

for ((i = 0; i < ${#TAXIDS[@]}; i++)); do
    TAXID=${TAXIDS[i]}
    LENGTH=${LENGTHS[i]}
    echo $TAXID $LENGTH
done



# Step 1: Download genomes and generate FASTA files for each TAXID
for ((i = 0; i < ${#TAXIDS[@]}; i++)); do
    TAXID=${TAXIDS[i]}
    LENGTH=${LENGTHS[i]}

    echo "Downloading genome for TaxID: $TAXID"
    ncbi-genome-download -F fasta -p $CPUS -r 10 -t "$TAXID" -o $ARTIFICIAL_READ_DIR/artificial_reads_genomes/$TAXID --flat-output all # For some IDs -T works and for other -t
    ncbi-genome-download -F fasta -p $CPUS -r 10 -T "$TAXID" -o $ARTIFICIAL_READ_DIR/artificial_reads_genomes/$TAXID --flat-output all
    zcat $ARTIFICIAL_READ_DIR/artificial_reads_genomes/$TAXID/*.fna.gz > $ARTIFICIAL_READ_DIR/artificial_reads_genomes/$TAXID.fna
    rm -rf $ARTIFICIAL_READ_DIR/artificial_reads_genomes/$TAXID  # Clean up downloaded compressed files
done
# Step 2: Generate reads using ISS for each TAXID and LENGTH
# Ensure the output directory exists
mkdir -p $ARTIFICIAL_READ_DIR/artificial_reads_fasta
for ((i = 0; i < ${#TAXIDS[@]}; i++)); do
    TAXID=${TAXIDS[i]}
    LENGTH=${LENGTHS[i]}
    mkdir $ARTIFICIAL_READ_DIR/artificial_reads_fasta/$TAXID
    echo CREATING GENOME FOR $TAXID
    iss generate --genomes $ARTIFICIAL_READ_DIR/artificial_reads_genomes/$TAXID.fna --model hiseq --cpus $CPUS \
                 --output $ARTIFICIAL_READ_DIR/artificial_reads_fasta/$TAXID/"$TAXID"_reads --n_reads $(($LENGTH * 2))
done


# Step 3: Concatenate R1 and R2 fastq files and compress
OUTPUT_R1="$ARTIFICIAL_READ_DIR/artificial_reads_R1.fastq.gz"
OUTPUT_R2="$ARTIFICIAL_READ_DIR/artificial_reads_R2.fastq.gz"

# Temporary files for concatenation and shuffling
TMP_R1="$ARTIFICIAL_READ_DIR/artificial_reads_R1.tmp"
TMP_R2="$ARTIFICIAL_READ_DIR/artificial_reads_R2.tmp"
SHUFFLED_R1="$ARTIFICIAL_READ_DIR/artificial_reads_R1.shuffled.tmp"
SHUFFLED_R2="$ARTIFICIAL_READ_DIR/artificial_reads_R2.shuffled.tmp"

# Function to count the number of reads in a FASTQ file
count_reads() {
  local file=$1
  if [[ $file == *.gz ]]; then
    zcat "$file" | wc -l | awk '{print $1/4}'
  else
    wc -l < "$file" | awk '{print $1/4}'
  fi
}

# Sort and pair files
R1_FILES=$(find "$ARTIFICIAL_READ_DIR" -name "*_reads_R1.fastq" | sort)
R2_FILES=$(find "$ARTIFICIAL_READ_DIR" -name "*_reads_R2.fastq" | sort)

# Ensure the number of files match
if [[ $(echo "$R1_FILES" | wc -l) -ne $(echo "$R2_FILES" | wc -l) ]]; then
  echo "Error: Mismatch in number of R1 and R2 files!" >&2
  exit 1
fi

# Process file pairs
paste <(echo "$R1_FILES") <(echo "$R2_FILES") | while IFS=$'\t' read -r R1_FILE R2_FILE; do
  # Verify the number of reads match
  R1_COUNT=$(count_reads "$R1_FILE")
  R2_COUNT=$(count_reads "$R2_FILE")
  echo $R1_FILE $R1_COUNT $R2_COUNT
  if [[ $R1_COUNT -ne $R2_COUNT ]]; then
    echo "Error: Mismatch in read counts between $R1_FILE ($R1_COUNT) and $R2_FILE ($R2_COUNT)!" >&2
    exit 1
  fi

  # Append to temporary files
  if [[ $R1_FILE == *.gz ]]; then
    zcat "$R1_FILE" >> "$TMP_R1"
  else
    cat "$R1_FILE" >> "$TMP_R1"
  fi

  if [[ $R2_FILE == *.gz ]]; then
    zcat "$R2_FILE" >> "$TMP_R2"
  else
    cat "$R2_FILE" >> "$TMP_R2"
  fi
done

# Shuffle the sequences while preserving FASTQ format
paste - - - - < "$TMP_R1"  | shuf --random-source=<(yes 42) | tr '\t' '\n' > "$SHUFFLED_R1"
paste - - - - < "$TMP_R2"  | shuf --random-source=<(yes 42) | tr '\t' '\n' > "$SHUFFLED_R2"


    
# Compress the shuffled outputs
gzip -c "$SHUFFLED_R1" > "$OUTPUT_R1"
gzip -c "$SHUFFLED_R2" > "$OUTPUT_R2"

# Clean up temporary files
rm "$TMP_R1" "$TMP_R2" "$SHUFFLED_R1" "$SHUFFLED_R2"

echo "Shuffled and merged R1 reads into $OUTPUT_R1"
echo "Shuffled and merged R2 reads into $OUTPUT_R2"





