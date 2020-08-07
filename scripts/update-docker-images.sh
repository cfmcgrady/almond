#!/usr/bin/env bash
set -e

SCALA212_VERSION="$(grep -oP '(?<=def scala212 = ")[^"]*(?<!")' project/Settings.scala)"
SCALA213_VERSION="$(grep -oP '(?<=def scala213 = ")[^"]*(?<!")' project/Settings.scala)"

ALMOND_VERSION="$(git describe --tags --abbrev=0 --match 'v*' | sed 's/^v//')"

DOCKER_REPO=almond-test

if [[ ${TRAVIS_TAG} != v* ]]; then
  echo "Not on a git tag, creating snapshot image"
  ALMOND_VERSION=${ALMOND_VERSION%.*}.$((${ALMOND_VERSION##*.} + 1))-SNAPSHOT
  IMAGE_NAME=${DOCKER_REPO}:snapshot
  docker build --build-arg ALMOND_VERSION=${ALMOND_VERSION} \
    --build-arg SCALA_VERSIONS="$SCALA213_VERSION $SCALA212_VERSION" -t ${IMAGE_NAME} .
else
  echo "Creating release images for almond ${ALMOND_VERSION}"
  IMAGE_NAME=${DOCKER_REPO}:${ALMOND_VERSION}
  docker build --build-arg ALMOND_VERSION=${ALMOND_VERSION} \
    --build-arg SCALA_VERSIONS="$SCALA213_VERSION $SCALA212_VERSION" -t ${IMAGE_NAME} .
  docker build --build-arg ALMOND_VERSION=${ALMOND_VERSION} \
    --build-arg SCALA_VERSIONS="$SCALA213_VERSION" -t ${IMAGE_NAME}-scala-${SCALA213_VERSION} .
  docker build --build-arg ALMOND_VERSION=${ALMOND_VERSION} \
    --build-arg SCALA_VERSIONS="$SCALA212_VERSION" -t ${IMAGE_NAME}-scala-${SCALA212_VERSION} .

  docker tag ${IMAGE_NAME} ${DOCKER_REPO}:latest
fi


