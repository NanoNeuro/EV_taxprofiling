#! /bin/bash
DIR_EVS='/data/Proyectos/EVs'
DIR_PROGRAMS='/home/nanoneuro/Programs'
DIR_DOWNLOADS='/home/nanoneuro/Downloads'


# Install apt programs
apt install openjdk-17-jre-headless # En sí igual no es necesario para el procesamiento porque desde conda se instala la versión 11.0.9
apt install samtools
apt install trim-galore
apt install awscli

# Then you have to access the config file of modify it by 
aws configure
# Then you have to introduce the credentials from https://us-east-1.console.aws.amazon.com/iamv2/home?region=us-east-1#/security_credentials


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

# Install nextflow
cd $DIR_PROGRAMS
wget -qO- https://get.nextflow.io | bash
export PATH="$DIR_PROGRAMS/bin:$PATH"
source ~/.bashrc


# Check nextflow is working (SEARCH MORE RECENT VERSIONS IF NECESSARY!!!)
nextflow run nf-core/rnaseq -r 3.12.0 -profile docker,test --outdir pruebas_rnaseq/ -resume
nextflow run nf-core/taxprofiler -r 1.1.1 -profile docker,test --outdir pruebas_taxprofiler -resume

