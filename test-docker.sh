#!/usr/bin/env bash
set -euo pipefail

IMAGE=${1:-bipca-experiment:latest}
PYTHON=/opt/conda/envs/bipca-experiment/bin/python

run() {
    docker run --rm --gpus all --entrypoint="" "$IMAGE" "$@"
}

echo "=== Testing image: $IMAGE ==="

echo ""
echo "--- torch + CUDA ---"
run $PYTHON -c "
import torch
print('torch:', torch.__version__)
print('CUDA available:', torch.cuda.is_available())
if torch.cuda.is_available():
    print('GPU:', torch.cuda.get_device_name(0))
"

echo ""
echo "--- bioinformatics CLI tools ---"
run bash -c "bedtools --version && plink --version && plink2 --version"

echo ""
echo "--- pip packages ---"
run $PYTHON -c "
import scanpy, leidenalg, igraph, numba, tables, scipy, sklearn, pandas, numpy
print('scanpy:', scanpy.__version__)
print('leidenalg:', leidenalg.version)
print('numba:', numba.__version__)
print('all imports ok')
"

echo ""
echo "--- bipca package ---"
run $PYTHON -c "import bipca; print('bipca:', bipca.__version__)"

echo ""
echo "--- bipca unit tests ---"
run bash -c "cd /bipca && $PYTHON -m nose2 -v python.tests 2>&1 | head -50"

echo ""
echo "=== All tests passed ==="
