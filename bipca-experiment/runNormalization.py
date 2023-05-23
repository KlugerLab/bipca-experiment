# a python wrapper to run normalization methods 
# including log1p, sctransform (analytical pearson residuals), alra, and sanity
import os, errno
import scanpy as sc
from bipca.experiments.experiments import log1p
#!pip install git+https://github.com/pavlin-policar/ALRA.git
#!python ALRA/setup.py install
from ALRA import ALRA
import scipy
import numpy as np
import pandas as pd
from scipy.io import mmwrite
import subprocess
from scipy import sparse


def runNormalization(adata_path,output_path,output_adata,n_threads=10,no=[]):
    """
    adata_path: path to the input anndata file which stores the raw count as adata.X
    output_path: path to store the output adata that will store the normalized data matrices, 
                 and a tmp folder that store the intermediate files from sanity
    output_adata: output name for the normalized adata
    n_threads: number of threads to run Sanity Default: 10
    no: a array of which methods not to run, including log1p, sctransform, alra, sanity Default: empty array
    """

    # Mounted to where sanity is installed
    sanity_installation_path = "/Sanity/bin/Sanity"
    # Specify the temporary folder that will store the output from intermediate outputs from Sanity
    tmp_path_sanity = output_path + "/tmp/"

    # convert to sparse matrix
    if sparse.issparse(adata.X):
        X = adata.X
    else:
        X = sparse.csr_matrix(adata.X)
    
    # Read data
    print("Loading count data ...\n")
    try:
        adata = sc.read_h5ad(adata_path)
    except FileNotFoundError:
        print("Error: Unable to find the h5ad file")

        
    
    # If no, else run log1p  
    if ('log' in no) | ('log1p' in no) | ('logtransform' in no):
        pass
    else:
        print("Running log normalization ...\n")
        adata.layers['log1p'] = log1p(X.toarray())

    # If no, else run sctransform
    if 'sct' in no:
        pass
    else:
        print("Running analytical pearson residuals ...\n")
        result_dict = sc.experimental.pp.normalize_pearson_residuals(adata,inplace=False)
        adata.layers['sct'] = result_dict['X']
    # If no, else run alra
    if 'alra' in no:
        pass
    else:
        print("Running ALRA ...\n")
        adata.layers['ALRA'] = ALRA.ALRA(X)

    # If no, else run sanity
    if 'sanity' in no:
        pass
    else:
        print("Running Sanity ...\n")
        
        try:
            os.makedirs(tmp_path_sanity)
        except OSError:
            print("Error: Unable to create new tmp folder for Sanity")
        # write intermediate files from sanity
        mmwrite((tmp_path_sanity + "/count.mtx"),X.T)
        pd.Series(adata.obs_names).to_csv((tmp_path_sanity + "/barcodes.tsv"),sep='\t',index=False,header=None)
        pd.Series(adata.var_names).to_csv((tmp_path_sanity + "/genes.tsv"),sep='\t',index=False,header=None)
        
        # hack the count mtx because sanity can't handle 2nd % from mmwrite
        #with open((tmp_path_sanity + "/count_tmp.mtx"), "r") as file_input:
        #    file_orig = file_input.readlines()
        #    file_rev = file_orig[::-1]
        #    with open((tmp_path_sanity + "/count.mtx"), "w") as output: 
        #        output.write(file_orig[0])
        #        output.write(file_orig[2])
        #        for i,line in enumerate(file_rev[:-3]):
        #                output.write(line)
         
        sanity_command = sanity_installation_path+" -f "+tmp_path_sanity+"/count.mtx "+"-mtx_genes "+ \
                           tmp_path_sanity+"/genes.tsv "+\
                           "-mtx_cells "+tmp_path_sanity+"/barcodes.tsv "+\
                           "-d "+tmp_path_sanity + " -n "+str(n_threads)
        runSanitypy(sanity_command)
        
        #print(error)
        adata.layers['Sanity'] = pd.read_csv(tmp_path_sanity+"/log_transcription_quotients.txt",sep="\t",index_col=0).to_numpy().T
        
    
    adata.write(output_path+output_adata)
    
def runSanitypy(sanity_command):
    #sanity_process = subprocess.Popen(sanity_command.split(), stdout=subprocess.PIPE)
    subprocess.run(
            sanity_command.split()
        )
        