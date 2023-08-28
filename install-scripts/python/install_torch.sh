CUDA_VERSION=$1
echo "CUDA ${CUDA_VERSION}"
SCRIPTPATH=$(dirname "$0")
sed -i 's,CUDA_VERSION,'"${CUDA_VERSION}"',' "$SCRIPTPATH/gpu_environment.yml"

if [ -z $CUDA_VERSION ]; then
    conda env create -f "$SCRIPTPATH/cpu_environment.yml"
else
    conda env create -f "$SCRIPTPATH/gpu_environment.yml"
fi