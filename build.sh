#!/usr/bin/env bash
DEFAULTPAT=''
GITHUB_PAT=${GITHUB_PAT:-$DEFAULTPAT}
DEFAULTSTAGE='final'
STAGE=${STAGE:=final}
dockerfile_version=${dockerfile_version:=''}
dockerfile="bipca-base$dockerfile_version.dockerfile"
dockerfile_path=${dockerfile_path:='dockerfiles/'}
dockerfile="${dockerfile_path}bipca-base$dockerfile_version.dockerfile"
BIPCA_VERSION=${BIPCA_VERSION:=}
CACHE=${CACHE:=TRUE}
CUDA_VERSION=${CUDA_VERSION:='11.7'}

echo "Building version $BIPCA_VERSION to stage $STAGE from $dockerfile"
if [ "$CACHE" == "TRUE" ]; then
    docker build -t bipca-experiment:${BIPCA_VERSION}_cuda_${CUDA_VERSION} --build-arg BIPCA_VERSION=$BIPCA_VERSION --build-arg GITHUB_PAT=$GITHUB_PAT --build-arg CUDA_VERSION=${CUDA_VERSION} --target=$STAGE -f $dockerfile  . > bipca-experiment:${BIPCA_VERSION}_cuda_${CUDA_VERSION}.log && echo "Build completed"
    docker build -t bipca-experiment:${BIPCA_VERSION}_cpu --build-arg BIPCA_VERSION=$BIPCA_VERSION --build-arg GITHUB_PAT=$GITHUB_PAT --target=$STAGE -f $dockerfile  . > bipca-experiment:${BIPCA_VERSION}_cpu.log && echo "Build completed"
else
    docker build --no-cache -t bipca-experiment:$BIPCA_VERSION --build-arg BIPCA_VERSION=$BIPCA_VERSION --build-arg GITHUB_PAT=$GITHUB_PAT --target=$STAGE -f $dockerfile  . > bipca-experiment:${BIPCA_VERSION}_cpu.log && echo "Build completed"
    docker build --no-cache -t bipca-experiment:${BIPCA_VERSION}_cuda_${CUDA_VERSION} --build-arg BIPCA_VERSION=$BIPCA_VERSION --build-arg GITHUB_PAT=$GITHUB_PAT --build-arg CUDA_VERSION=${CUDA_VERSION} --target=$STAGE -f $dockerfile  . > bipca-experiment:${BIPCA_VERSION}_cuda_${CUDA_VERSION}.log && echo "Build completed"
fi

