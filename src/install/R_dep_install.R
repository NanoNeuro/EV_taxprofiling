if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

install.packages('jsonlite')
install.packages("KernSmooth")
install.packages("pheatmap")

BiocManager::install("rtracklayer", force = TRUE)
BiocManager::install("GenomicFeatures")
BiocManager::install("ensembldb")
BiocManager::install("dupRadar")
BiocManager::install("tximport")
BiocManager::install("tximeta")
BiocManager::install("DESeq2")



