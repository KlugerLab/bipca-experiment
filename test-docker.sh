#!/usr/bin/env bash
set -euo pipefail

IMAGE=${1:-bipca-experiment:latest}
CONTAINER=bipca-test-$$

echo "=== Testing image: $IMAGE ==="

cleanup() {
    echo ""
    echo "=== Cleaning up ==="
    docker stop $CONTAINER 2>/dev/null || true
    docker rm $CONTAINER 2>/dev/null || true
}
trap cleanup EXIT

echo ""
echo "--- Starting container ---"
docker run -d --gpus all -p 18787:8787 -p 18888:8888 --name $CONTAINER $IMAGE
sleep 5
docker logs $CONTAINER

echo ""
echo "--- torch + CUDA ---"
docker exec $CONTAINER /opt/conda/envs/bipca-experiment/bin/python -c "
import torch
print('torch:', torch.__version__)
print('CUDA available:', torch.cuda.is_available())
if torch.cuda.is_available():
    print('GPU:', torch.cuda.get_device_name(0))
"

echo ""
echo "--- bioinformatics CLI tools ---"
docker exec $CONTAINER bash -c "bedtools --version && plink --version && plink2 --version"

echo ""
echo "--- pip packages ---"
docker exec $CONTAINER /opt/conda/envs/bipca-experiment/bin/python -c "
import scanpy, leidenalg, igraph, numba, tables, scipy, sklearn, pandas, numpy
print('scanpy:', scanpy.__version__)
print('leidenalg:', leidenalg.version)
print('numba:', numba.__version__)
print('all imports ok')
"

echo ""
echo "--- bipca package ---"
docker exec $CONTAINER /opt/conda/envs/bipca-experiment/bin/python -c "import bipca; print('bipca:', bipca.__version__)"

echo ""
echo "--- bipca unit tests ---"
docker exec $CONTAINER bash -c "cd /bipca && /opt/conda/envs/bipca-experiment/bin/python -m pytest python/tests/ -x -q"

echo ""
echo "=== All tests passed ==="
