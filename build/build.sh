#!/bin/bash

set -exu
platform=${1:-linux/arm64}

ENV="${ENV:-development}"

DOCKER_REGISTRY=${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com

RELEASE="${RELEASE:-false}"
RELEASE_OPT=""
if [ "${RELEASE}" == "true" ]; then
  RELEASE_OPT="--push"
fi

DOCKER_FILE_PATH="${DIR}/Dockerfile"
# frontend と backend の docker build context は異なる
if [ "${NAME}" == "frontend" ] ; then
  cd "${DIR}"
  DOCKER_FILE_PATH="Dockerfile"
fi

docker buildx build ${RELEASE_OPT} \
  --platform="${platform}" \
  --progress=plain \
  --tag "${DOCKER_REGISTRY}"/"${ENV}"/fcdemo/"${NAME}":"${IMAGE_TAG}" \
  -f "${DOCKER_FILE_PATH}" \
  .
