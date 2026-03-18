CUDA_VERSION=$1
echo "CUDA ${CUDA_VERSION}"
SCRIPTPATH=$(dirname "$0")
PIP=/opt/conda/envs/bipca-experiment/bin/pip

if [ -z $CUDA_VERSION ]; then
    mamba env create -f "$SCRIPTPATH/cpu_environment.yml"
    $PIP install torch --index-url https://download.pytorch.org/whl/cpu
else
    # Convert "11.8" -> "cu118" for PyTorch pip wheel URLs
    CUDA_SHORT=$(echo "$CUDA_VERSION" | tr -d '.')
    mamba env create -f "$SCRIPTPATH/gpu_environment.yml"
    $PIP install torch --index-url https://download.pytorch.org/whl/cu${CUDA_SHORT}
fi
