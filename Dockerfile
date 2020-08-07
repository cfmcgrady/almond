# Dockerfile with support for creating images with kernels for multiple Scala versions.
# Expects ALMOND_VERSION and SCALA_VERSIONS to be set as build arg, like this:
# docker build --build-arg ALMOND_VERSION=0.3.1 --build-arg SCALA_VERSIONS="2.12.9 2.13.0" .

# Set LOCAL_IVY=yes to have the contents of ivy-local copied into the image.
# Can be used to create an image with a locally built almond that isn't on maven central yet.
ARG LOCAL_IVY=no

FROM jupyter/base-notebook as coursier_base

ENV NB_UID 1000
ENV NB_GID 100
ENV NB_USER jovyan

USER root

RUN apt-get -y update && \
    apt-get install --no-install-recommends -y \
      curl \
      openjdk-8-jre-headless \
      ca-certificates-java && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -Lo /usr/local/bin/coursier https://github.com/coursier/coursier/releases/download/v2.0.0-RC3-2/coursier && \
    chmod +x /usr/local/bin/coursier

USER $NB_UID

FROM almondsh/almond as coursier_runtime

COPY --from=almondsh/almond /home/jovyan/.cache /home/jovyan/.cache
RUN chown -R jovyan /home/jovyan/.cache

# ensure the JAR of the CLI is in the coursier cache, in the image
# ENV COURSIER_REPOSITORIES "ivy2Local|http://nexus.k8s.uc.host.dxy/repository/maven-public/|central|sonatype:releases"
RUN /usr/local/bin/coursier --help

FROM coursier_base as local_ivy_yes
USER $NB_UID
ONBUILD RUN mkdir -p .ivy2/local/
ONBUILD COPY --chown=1000:100 ivy-local/ .ivy2/local/

FROM coursier_base as local_ivy_no

FROM local_ivy_${LOCAL_IVY}
ARG ALMOND_VERSION
# Set to a single Scala version string or list of Scala versions separated by a space.
# i.e SCALA_VERSIONS="2.12.9 2.13.0"
ARG SCALA_VERSIONS
USER $NB_UID
COPY scripts/install-kernels.sh .
COPY --from=almondsh/almond /home/jovyan/.cache /home/jovyan/.cache
USER root
RUN chown -R jovyan /home/jovyan/.cache
USER $NB_UID
RUN ./install-kernels.sh && \
    rm install-kernels.sh && \
    rm -rf .ivy2
