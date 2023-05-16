#! /bin/bash
DIR_EVS='/media/seth/SETH_DATA/Biodonostia_David/EVs'
DIR_PROGRAMS='~/Programs'
DIR_DOWNLOADS='~/Downloads'


# Install apt programs
apt install openjdk-17-jre-headless # En sí igual no es necesario para el procesamiento porque desde conda se instala la versión 11.0.9
apt install samtools
apt install trim-galore


# Install centrifuge | instalamos desde source porque desde conda entra en conflicto con la version de python que requiere de otros paquetes.
DIR_CENTRIFUGE="$DIR_PROGRAMS/centrifuge"

cd $DIR_DOWNLOADS
git clone https://github.com/infphilo/centrifuge
cd centrifuge
make
sudo make install prefix=$DIR_CENTRIFUGE


## Add path to bashrc to make the dir recognisable
export PATH="$DIR_CENTRIFUGE/bin:$PATH"
source ~/.bashrc


# Añadir los cambios de conda
conda deactivate
conda remove --name EVs --all -y
mamba env create --file EVs_env.yml

cd $DIR_EVS
conda activate EVs
~/nextflow run nf-core/rnaseq -r 3.11.2 -profile test --outdir pruebas_rnaseq/ -resume
~/nextflow run nf-core/taxprofiler -r 1.0.1 -profile test --outdir pruebas_taxprofiler -resume
