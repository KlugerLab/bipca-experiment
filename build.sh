#!/usr/bin/env bash
DEFAULTPAT=''
GITHUB_PAT=${GITHUB_PAT:-$DEFAULTPAT}
DEFAULTINCREMENT='true'
INCREMENT=${INCREMENT:-$DEFAULTINCREMENT}
DEFAULTPREFIX='dev'
PREFIX=${PREFIX:-$DEFAULTPREFIX}
DEFAULTSTAGE='final'
STAGE=${STAGE:-$DEFAULTSTAGE}
if [ $INCREMENT = 'true' ]; then
    new_version=$(docker images | awk -v pat=$PREFIX '{if( ($1 == "bipca-experiment") && ( $2 ~ pat )) {  print substr($2, 1, length($2)-1) 1+substr($2, length($2)); exit}}')
else
    new_version=$(docker images | awk -v pat=$PREFIX '{if( ($1 == "bipca-experiment") && ( $2 ~ pat )) {  print $2; exit}}')
fi
echo "Building version $new_version to stage $STAGE"
docker build -t bipca-experiment:$new_version --build-arg GITHUB_PAT=$GITHUB_PAT --target=$STAGE -f dockerfiles/bipca-base.dockerfile  . > bipca-experiment:$new_version.log && echo "Build completed"


