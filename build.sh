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
echo "Building version $new_version to stage $STAGE from $dockerfile"
docker build -t bipca-experiment:$new_version --build-arg BIPCA_VERSION=$BIPCA_VERSION --build-arg GITHUB_PAT=$GITHUB_PAT --target=$STAGE -f $dockerfile  . > bipca-experiment:$new_version.log && echo "Build completed"


