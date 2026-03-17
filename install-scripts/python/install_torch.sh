CUDA_VERSION=$1
echo "CUDA ${CUDA_VERSION}"
SCRIPTPATH=$(dirname "$0")

if [ -z $CUDA_VERSION ]; then
    mamba env create -f "$SCRIPTPATH/cpu_environment.yml"
else
    # Convert "11.8" -> "cu118" for PyTorch pip wheel URLs
    CUDA_SHORT=$(echo "$CUDA_VERSION" | tr -d '.')
    sed -i 's,CUDA_VERSION_SHORT,'"cu${CUDA_SHORT}"',' "$SCRIPTPATH/gpu_environment.yml"
    mamba env create -f "$SCRIPTPATH/gpu_environment.yml"
fi
