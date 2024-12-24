INPUT_DIR=$1
OUTPUT_DIR=$2

# Find all files in INPUT_DIR/star_salmon/unmapped that follow the pattern *.unmapped_{1,2}.fastq.gz
# For each pair, run Bowtie2 and output it to OUTPUT_DIR


# Create OUTPUT_DIR if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Find all unmatched_1 files
for file1 in "$INPUT_DIR"/star_salmon/unmapped/*.unmapped_1.fastq.gz; do
    # Get the base name without the suffix
    base=$(basename "$file1" .unmapped_1.fastq.gz)
    
    # Construct the matching file2 name
    file2="$INPUT_DIR/star_salmon/unmapped/$base.unmapped_2.fastq.gz"
    
    # Check if the pair exists
    if [[ -f "$file2" ]]; then
        # Output file
        output_file="$OUTPUT_DIR/${base}.bowtie2_output.sam"
        output_file_unmapped="$OUTPUT_DIR/${base}.unmapped.fastq.gz"

        # Run Bowtie2        
        echo "Processing: $file1 and $file2 -> $output_file"

        bowtie2 --threads $CPUS --very-sensitive \
            -x $DB_INDEXES_NFCORE/bowtie2-chm13/bowtie2-chm13 \
            -1 $file1 \
            -2 $file2 \
            -S $output_file \
            --un-conc-gz $output_file_unmapped 

    else
        echo "Missing pair for: $file1"
    fi
done



    