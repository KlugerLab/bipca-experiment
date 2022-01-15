#!/usr/bin/env r

# take a h5ad file (.X being the count matrix) as input
# run 4 normalization method (lognorm,sctransform,alra,sanity)
# Output: save the 5 normalization matrix into a h5ad file

suppressMessages({
  # library(anndata,lib.loc = "/usr/local/lib/R/site-library/")
  # library(Seurat,lib.loc = "/usr/local/lib/R/site-library/")
  # library(SeuratWrappers,lib.loc = "/usr/local/lib/R/site-library/")
  library(docopt)})
doc<-'Run Normalization.
    take a h5ad file (.X being the count matrix) as input
    run 4 normalization methods (log1p,SCT,Sanity,ALRA)
    Output: save the 5 normalization matrix into a h5ad file
Usage:
  runNormalization.r [-n ALGORITHMS...] <adata_path> <output_adata_path>
  runNormalization.r (-h | --help)
  runNormalization.r --version

Options:
  -h --help           Show this screen.
  -n --no ALGORITHMS  Disable ALGORITHMS in normalization.

' 
opt <-docopt(doc)
print(opt$no)
runNormalization <- function(adata_path,output_adata_path){
  # Mounted to where sanity is installed
  sanity_installation_path <- "/Sanity"
  tmp_path_sanity <- "/tmp"
  
  # read the data from this path
  message("Loading the count data...")
  #anndata::read_h5ad(adata_path)
  adata <- tryCatch(anndata::read_h5ad(adata_path), error = function(c) stop("Error: Unable to open h5ad file: ",adata_path))
  # convert to Seurat: 
  seurat_obj <- Seurat::CreateSeuratObject(counts = t(as.matrix(adata[['X']])),assay = "RNA")
  
  # Log normalization
  message("Running Log normalization...")
  seurat_obj <- Seurat::NormalizeData(seurat_obj)
  adata$layers[['LogNormalization']] <- t(as.matrix(seurat_obj@assays$RNA@data))
  
  # ALRA
  message("Running ALRA...")
  seurat_obj <- SeuratWrappers::RunALRA(object=seurat_obj,assay="RNA",slot="data",setDefaultAssay = FALSE)
  adata$layers[['ALRA']] <- t(as.matrix(seurat_obj@assays$alra@data))
 
  # SCT
  message("Running SCT...")
  seurat_obj <- Seurat::SCTransform(object=seurat_obj, ncells = 5000,assay = "RNA",new.assay.name = "SCT",return.only.var.genes = F,seed.use = 1448145)
  adata$layers[['SCT']] <- t(as.matrix(seurat_obj@assays$SCT@scale.data))
  Seurat::DefaultAssay(seurat_obj) <- "RNA"
  
  # Sanity
  message("Running Sanity...")
  ## first process the data as what Sanity requires
  ## warning if tmp_path_sanity existed
  tryCatch(dir.create(tmp_path_sanity), error = function(c) stop(c))
  Matrix::writeMM(obj = seurat_obj@assays$RNA@counts, file=paste0(tmp_path_sanity,"/count.mtx"))
  write(x = colnames(seurat_obj), file = paste0(tmp_path_sanity,"/barcodes.tsv"))
  write(x = rownames(seurat_obj), file = paste0(tmp_path_sanity,"/genes.tsv"))
  
  sanity_command <- paste0(sanity_installation_path,
                           " -f ",
                           tmp_path_sanity,"/count.mtx ",
                           "-mtx_genes ",
                           tmp_path_sanity,"/genes.tsv ",
                           "-mtx_cells ",
                           tmp_path_sanity,"/barcodes.tsv ",
                           "-d ",
                           tmp_path_sanity)
  cat(sanity_command)
  base::system(command = sanity_command)
  
  sanity_mat <- read.table(file = paste0(tmp_path_sanity,"/log_transcription_quotients.txt"),row.names = 1,header = T)
  colnames(sanity_mat) <- colnames(seurat_obj)
  adata$layers[['Sanity']] <- t(sanity_mat)
  

  # save
  adata$write_h5ad(output_adata_path)
  
}

# pass the parameters
#args <- commandArgs(TRUE)
#runNormalization(adata_path = args[1],output_adata_path =arg[2],tmp_path_sanity = args[3])

