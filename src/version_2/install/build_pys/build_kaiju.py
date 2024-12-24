import argparse
import os
from tqdm import tqdm
import pandas as pd
import gzip
import re

def merge_proteomic_files(proteomic_files, output_dir, dict_GCF):
    """
    Merge  files into one file with modified headers and return a list of modified headers and tax IDs.
    """
    # Output file path for merged FNA
    merged_fna_file = os.path.join(output_dir, "library.faa")

    # Regular expression to capture the GCF identifier from the filename
    gcf_pattern = re.compile(r"^(GCF_\d+\.\d+)_")
    
    # List to store header entries for the taxid table

    with open(merged_fna_file, 'w') as merged_file:
        for proteomic_file in tqdm(proteomic_files):
            # Extract GCF identifier from the filename
            file_name = os.path.basename(proteomic_file)
            match = gcf_pattern.match(file_name)
            if match:
                gcf_id = match.group(1)
                tax_id = dict_GCF.get(gcf_id)
                
                # Skip files if tax ID is not found
                if tax_id is None:
                    print(f"Warning: No tax ID found for {gcf_id}. Skipping file {proteomic_file}.")
                    continue

                # Open and process the genomic file
                open_file = gzip.open(proteomic_file, 'rt') if proteomic_file.endswith('.gz') else open(proteomic_file, 'r')
                
                with open_file as fna_file:
                    for line in fna_file:
                        if line.startswith(">"):
                            # Modify the header line with the new format
                            new_header = line[1:].split()[0].replace('>', '').replace('_', '-')
                        
                            merged_file.write(f">{new_header}_{tax_id}\n")  
                        else:
                            # Write the rest of the lines as they are
                            merged_file.write(line)
    
    print(f"All protein files have been merged into {merged_fna_file}")




def find_proteomic_files(input_dir, output_dir, groups=['archaea', 'bacteria', 'human', 'fungi', 'protozoa', 'viral'], masked=False):
    os.makedirs(output_dir, exist_ok=True)
    
    # Build the GCF table
    list_groups = []
    for group in groups:
        list_groups.append(pd.read_csv(f'{input_dir}/{group}/table_{group}.txt', sep='\t')[['assembly_accession', 'taxid']])

    df_GCF = pd.concat(list_groups)
    df_GCF = df_GCF.drop_duplicates('assembly_accession').set_index('assembly_accession', drop=True)
    dict_GCF = dict(zip(df_GCF.index, df_GCF.taxid.values))

    if masked:
        mask_file_basis = '_protein.masked.faa.gz'
    else:
        mask_file_basis = '_protein.faa.gz'

    # Find all files that end with '_protein.faa.gz'
    proteomic_files = []
    for group in groups:
        for root, dirs, files in os.walk(f'{input_dir}/{group}'):
                for file in files:
                    if file.endswith(mask_file_basis):
                        # Append the full path of the file
                        proteomic_files.append(os.path.join(root, file))

    print(f"Found {len(proteomic_files)} protein files.")

    # For the output we will generate a fasta file with all sequences, which contain the following structure:
    #   >XXX_YYY
    #       XXX is an alphanumeric indicator. We will use the protein identifier.
    #       YYY is the taxon ID

    merge_proteomic_files(proteomic_files, output_dir, dict_GCF)



def main():
    # Set up argument parsing
    parser = argparse.ArgumentParser(description="Find genomic files in input directory and save the list to output directory.")
    parser.add_argument("--input_dir", help="Path to the input directory")
    parser.add_argument("--output_dir", help="Path to the output directory")
    parser.add_argument("--groups", help="Comma-separated list of groups", type=lambda s: s.split(','))
    parser.add_argument("--masked", help="Option to include masked sequences", action="store_true")

    args = parser.parse_args()
    
    # Run the function
    find_proteomic_files(args.input_dir, args.output_dir, args.groups, args.masked)

if __name__ == "__main__":
    main()