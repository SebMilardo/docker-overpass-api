FROM ubuntu:bionic

MAINTAINER Sebastiano Milardo <milardo@mit.edu>

# no tty
ARG DEBIAN_FRONTEND=noninteractive
ARG PLANET_FILE=planet.osm.bz2

ARG OSM_VER=0.7.54
ENV EXEC_DIR=/srv/osm3s
ENV DB_DIR=/srv/osm3s/db

RUN build_deps="g++ make expat libexpat1-dev zlib1g-dev curl" \
  && set -x \
  && echo "#!/bin/sh\nexit 0" >/usr/sbin/policy-rc.d \
  && apt-get update \
  && apt-get install -y --force-yes --no-install-recommends \
       $build_deps \
       fcgiwrap \
       nginx \
       python3-pip \
       gzip \
       bzip2 \
  && rm /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default \
  && rm -rf /var/lib/apt/lists/* \
  && curl -o osm-3s_v$OSM_VER.tar.gz http://dev.overpass-api.de/releases/osm-3s_v$OSM_VER.tar.gz \
  && tar -zxvf osm-3s_v${OSM_VER}.tar.gz \
  && cd osm-3s_v* \
  && ./configure CXXFLAGS="-O3" --prefix="$EXEC_DIR" \
  && make install \
  && cd .. \
  && rm -rf osm-3s_v*

WORKDIR /usr/src/app

COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

COPY bbox.csv bbox.csv
COPY download_osm_data.py download_osm_data.py
RUN python3 download_osm_data.py

RUN gunzip planet.osm.gz
RUN bzip2 planet.osm

RUN apt-get purge -y --auto-remove $build_deps

RUN /srv/osm3s/bin/init_osm3s.sh "$PLANET_FILE" "$DB_DIR" "$EXEC_DIR" \
  && rm -f "$PLANET_FILE"

COPY nginx.conf /etc/nginx/nginx.conf
COPY overpass /etc/init.d
COPY docker-start /usr/local/sbin

CMD ["/usr/local/sbin/docker-start"]

EXPOSE 8081
