import argparse
import os
from tqdm import tqdm
import pandas as pd
import gzip
import re

def merge_genomic_files(genomic_files, output_dir, dict_GCF):
    """
    Merge genomic files into one file with modified headers and return a list of modified headers and tax IDs.
    """
    # Output file path for merged FNA
    merged_fna_file = os.path.join(output_dir, "library.fna")

    # Regular expression to capture the GCF identifier from the filename
    gcf_pattern = re.compile(r"^(GCF_\d+\.\d+)_")
    
    # List to store header entries for the taxid table
    header_taxid_pairs = []

    with open(merged_fna_file, 'w') as merged_file:
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
                            # Modify the header line with the new format
                            header_entry = line.split()[0].replace('>', '').replace('_', '-').replace('|', '-').replace(':', '-')  # Extract the header ID and substitute all posible characters by -
                            new_header = f">kraken:taxid|{tax_id}|{header_entry}\n"
                            merged_file.write(new_header)
                        else:
                            # Write the rest of the lines as they are
                            merged_file.write(line)
    
    print(f"All genomic files have been merged into {merged_fna_file}")
    return header_taxid_pairs


def create_taxid_table(header_taxid_pairs, output_dir):
    """
    Create a taxid table file from the list of header-taxid pairs.
    """
    table_file = os.path.join(output_dir, "prelim_map.txt")
    with open(table_file, 'w') as table:
        for tax_id, header in header_taxid_pairs:
            # Write each row in the format: TAXID, header, tax_id
            table.write(f"TAXID\t{header}\t{tax_id}\n")
    
    print(f"TaxID table created at {table_file}")


def find_genomic_files(input_dir, output_dir, groups=['archaea', 'bacteria', 'human', 'fungi', 'protozoa', 'viral'], masked=False):
    os.makedirs(output_dir, exist_ok=True)
    
    # Build the GCF table
    list_groups = []
    for group in groups:
        list_groups.append(pd.read_csv(f'{input_dir}/{group}/table_{group}.txt', sep='\t')[['assembly_accession', 'taxid']])

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

    # For the output we will generate two files:
    #   library.fna: 
    #       It contains all the sequences. If a sequence starts with 
    #           > NC_002607.1 Halobacterium salinarum NRC-1, complete sequence
    #       Then the output will be:
    #           >kraken:taxid|64091|NC_002607.1 Halobacterium salinarum NRC-1, complete sequence
    #       To generate this output we will need the assembly_summary.txt from each species. 
    #
    #   prelim_map.txt
    #           TAXID	kraken:taxid|64091|NC_002607.1	64091
    #           TAXID	kraken:taxid|64091|NC_001869.1	64091
    #           TAXID	kraken:taxid|64091|NC_002608.1	64091
    #           TAXID	kraken:taxid|273057|NC_002754.1	273057
    #           TAXID	kraken:taxid|192952|NC_003901.1	192952
    #       To create this table we will need to map each name in this renewed fna with its taxonomic ID. 
    #       In this case it is easy because the ID is already in the name.

    header_taxid_pairs = merge_genomic_files(genomic_files, output_dir, dict_GCF)
    create_taxid_table(header_taxid_pairs, output_dir)


def main():
    # Set up argument parsing
    parser = argparse.ArgumentParser(description="Find genomic files in input directory and save the list to output directory.")
    parser.add_argument("--input_dir", help="Path to the input directory")
    parser.add_argument("--output_dir", help="Path to the output directory")
    parser.add_argument("--groups", help="Comma-separated list of groups", type=lambda s: s.split(','))
    parser.add_argument("--masked", help="Option to include masked sequences", action="store_true")

    args = parser.parse_args()
    
    # Run the function
    find_genomic_files(args.input_dir, args.output_dir, args.groups, args.masked)

if __name__ == "__main__":
    main()