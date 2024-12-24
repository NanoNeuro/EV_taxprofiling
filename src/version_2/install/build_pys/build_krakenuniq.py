import argparse
import os
from tqdm import tqdm
import pandas as pd
import gzip
import re

def create_seqid2taxid_centrifuge(genomic_files, output, dict_GCF):
    """
    Merge genomic files into one file with modified headers and return a list of modified headers and tax IDs.
    """
    # Regular expression to capture the GCF identifier from the filename
    gcf_pattern = re.compile(r"^(GCF_\d+\.\d+)_")
    
    # List to store header entries for the taxid table
    header_taxid_pairs = []

    for genomic_file in tqdm(genomic_files):
        # Extract GCF identifier from the filename
        file_name = os.path.basename(genomic_file)
        match = gcf_pattern.match(file_name)
        if match:
            gcf_id = match.group(1)
            tax_id = dict_GCF.get(gcf_id)
            
            # Skip files if tax ID is not found
            if tax_id is None:
                print(f"Warning: No tax ID found for {gcf_id}. Skipping file {genomic_file}.")
                continue

            # Open and process the genomic file
            open_file = gzip.open(genomic_file, 'rt') if genomic_file.endswith('.gz') else open(genomic_file, 'r')
            
            with open_file as fna_file:
                for line in fna_file:
                    if line.startswith(">"):
                        # Store the modified header and tax ID for the table
                        header_entry = line.split()[0].replace('>', '')   # Extract the header ID
                        header_taxid_pairs.append((tax_id, header_entry))
               
    
    table_file = os.path.join(output)
    with open(table_file, 'w') as table:
        for tax_id, header in header_taxid_pairs:
            # Write each row in the format: TAXID, header, tax_id
            table.write(f"{header}\t{tax_id}\n")
    
    print(f"TaxID table created at {table_file}")




def find_genomic_files(input_dir, output, groups=['archaea', 'bacteria', 'human', 'fungi', 'protozoa', 'viral'], masked=False):    
    print(groups)
    # Build the GCF table
    list_groups = []
    for group in groups:
        list_groups.append(pd.read_csv(f'{input_dir}/{group}/table_{group}.txt', sep='\t')[['assembly_accession', 'taxid', 'organism_name']])

    df_GCF = pd.concat(list_groups)
    df_GCF = df_GCF.drop_duplicates('assembly_accession').set_index('assembly_accession', drop=True)
    dict_GCF = dict(zip(df_GCF.index, df_GCF.taxid.values))

    if masked:
        mask_file_basis = '_genomic.masked.fna.gz'
    else:
        mask_file_basis = '_genomic.fna.gz'

    # Find all files that end with '_genomic.fna.gz'
    genomic_files = []
    for group in groups:
        for root, dirs, files in os.walk(f'{input_dir}/{group}'):
                for file in files:
                    if file.endswith(mask_file_basis):
                        # Append the full path of the file
                        genomic_files.append(os.path.join(root, file))

    print(f"Found {len(genomic_files)} genomic files.")
    # For the output we will generate one file:
    #   seqid2taxid_centrifuge.map: 
    #       It contains all the sequence ID of the fasta files maped to their taxon. Like these
    #           NZ_CP099582.1    110163
    #           NZ_CP017881.1    39664
    #           NZ_CP008822.1    43687
    #           NZ_CP167059.1    1580092
              

    create_seqid2taxid_centrifuge(genomic_files, output, dict_GCF)


def main():
    # Set up argument parsing
    parser = argparse.ArgumentParser(description="Find genomic files in input directory and save the list to output directory.")
    parser.add_argument("--input_dir", help="Path to the input directory")
    parser.add_argument("--output", help="Path to the output seqid2taxid.map")
    parser.add_argument("--groups", help="Comma-separated list of groups", type=lambda s: s.split(','))
    parser.add_argument("--masked", help="Option to include masked sequences", action="store_true")

    args = parser.parse_args()
    
    # Run the function
    find_genomic_files(args.input_dir, args.output, args.groups, args.masked)

if __name__ == "__main__":
    main()