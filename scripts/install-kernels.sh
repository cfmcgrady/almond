#!/usr/bin/env bash
set -eu

# SCALA_VERSIONS=(2.12.12 2.13.3)
ALMOND_VERSION=0.10.3

[ -z "$SCALA_VERSIONS" ] && { echo "SCALA_VERSIONS is empty" ; exit 1; }
[ -z "$ALMOND_VERSION" ] && { echo "ALMOND_VERSION is empty" ; exit 1; }
for SCALA_FULL_VERSION in ${SCALA_VERSIONS}; do
  # remove patch version
  SCALA_MAJOR_VERSION=${SCALA_FULL_VERSION%.*}
  # remove all dots for the kernel id
  SCALA_MAJOR_VERSION_TRIMMED=$(echo ${SCALA_MAJOR_VERSION} | tr -d .)
  echo Installing almond ${ALMOND_VERSION} for Scala ${SCALA_FULL_VERSION}
  EXTRA_ARGS=()
  if [[ ${ALMOND_VERSION} == *-SNAPSHOT ]]; then
    EXTRA_ARGS+=('--standalone')
  fi
  coursier bootstrap \
      --standalone \
      --no-default \
      -r http://maven.aliyun.com/nexus/content/groups/public \
      -r http://nexus.k8s.uc.host.dxy/repository/maven-public/ \
      -r jitpack \
      -r https://repo1.maven.org/maven2/ \
      -i user -I user:sh.almond:scala-kernel-api_${SCALA_FULL_VERSION}:${ALMOND_VERSION} \
      sh.almond:scala-kernel_${SCALA_FULL_VERSION}:${ALMOND_VERSION} \
      --default=true --sources \
      -o almond ${EXTRA_ARGS[@]}
  ./almond --install --log info --metabrowse --id scala${SCALA_MAJOR_VERSION_TRIMMED} --display-name "Scala ${SCALA_MAJOR_VERSION}"
  cp ./almond /tmp/a
  rm -f almond
done
echo Installation was successful
