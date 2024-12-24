import argparse
import os
from tqdm import tqdm
import pandas as pd
import gzip
import re
import shutil


def create_gcfid2taxid_ganon(genomic_files, output, dict_GCF):
    """
    Generate a TSV file for Ganon with the file path, GCF ID, and taxon ID.
    """
    # Regular expression to capture the GCF identifier from the filename
    gcf_pattern = re.compile(r"^(GCF_\d+\.\d+)_")
    
    # List to store entries for the Ganon table
    ganon_entries = []

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

            # Store the entry for Ganon table
            ganon_entries.append((genomic_file, gcf_id, tax_id))
    
    # Write the Ganon table to output file
    table_file = os.path.join(output, 'input_file.tsv')
    with open(table_file, 'w') as table:
        for file_path, gcf_id, tax_id in ganon_entries:
            # Write each row in the format: file_path, gcf_id, tax_id
            table.write(f"{file_path}\t{gcf_id}\t{tax_id}\n")
    
    print(f"Ganon TSV file created at {table_file}")

def find_genomic_files(input_dir, output, groups=['archaea', 'bacteria', 'human', 'fungi', 'protozoa', 'viral'], masked=False):    
    print(groups)
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

    # Find all files that end with '_genomic.fna.gz' or '_genomic.fna.masked'
    genomic_files = []
    os.makedirs(f'{output}/fasta_files', exist_ok=True)
    for group in groups:
        for root, dirs, files in os.walk(f'{input_dir}/{group}'):
            for file in tqdm(files):
                if file.endswith(mask_file_basis):
                    # Append the full path of the file
                    # file_rename = file.replace('.masked.fna', '.masked.fasta')
                    # if not os.path.exists(os.path.join(output, 'fasta_files/' + file_rename)):
                    #     shutil.copyfile(os.path.join(root, file), os.path.join(output, 'fasta_files/' + file_rename))
                    # genomic_files.append(os.path.join(output, 'fasta_files/' + file_rename))
                    genomic_files.append(os.path.join(root, file))

    print(f"Found {len(genomic_files)} genomic files.")
    
    # Generate the Ganon TSV file
    create_gcfid2taxid_ganon(genomic_files, output, dict_GCF)

def main():
    # Set up argument parsing
    parser = argparse.ArgumentParser(description="Generate Ganon TSV file with genomic file paths, GCF IDs, and taxon IDs.")
    parser.add_argument("--input_dir", help="Path to the input directory")
    parser.add_argument("--output_dir", help="Path to the output ganon files")
    parser.add_argument("--groups", help="Comma-separated list of groups", type=lambda s: s.split(','))
    parser.add_argument("--masked", help="Option to include masked sequences", action="store_true")

    args = parser.parse_args()
    
    # Run the function
    find_genomic_files(args.input_dir, args.output_dir, args.groups, args.masked)

if __name__ == "__main__":
    main()
