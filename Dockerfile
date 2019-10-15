FROM ubuntu:18.04
#FROM jupyter/minimal-notebook

#ARG NB_USER="nbuser"
#ARG NB_UID="1000"
#ARG NB_GID="100"

#ENV TINI_VERSION v0.6.0
#ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
#RUN chmod +x /usr/bin/tini
# libxss-dev, libatk-bridge2, libgtk used for drawio-batch (convert drawio to svg)
# libasound used for chrome
#

ENV DEBIAN_FRONTEND noninteractive
ENV DEBIAN_FRONTEND teletype

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get update && apt-get remove ipython && ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
        apt-utils \
        python3-dev \
        python3-pip \
        ca-certificates \
        curl \
        debconf-utils \
        dirmngr \
        gcc \
        git \
        g++ \
    	gpg \
        gpg-agent \
	    libgdal-dev \
        nodejs \
        npm \
        pandoc \
        texlive-xetex \
        libxss-dev \
        libatk-bridge2.0-dev \
        libgtk-3-0 \
        libasound2 \
    && cd /usr/local/bin \
    && ln -s /usr/bin/python3 python \
    && pip3 install --upgrade pip \
    && apt-get clean

# Special treatment for corefonts since we need to autoaccept eula
# https://unix.stackexchange.com/a/106553
RUN echo 'ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula boolean true' | debconf-set-selections \
    && apt-get install -y --no-install-recommends \
        ttf-mscorefonts-installer \
    && apt-get remove -y --purge debconf-utils \
    && apt-get clean

# install pandoc
#RUN wget -o /tmp/pandoc-2.7.1.deb https://github.com/jgm/pandoc/releases/download/2.7.1/pandoc-2.7.1-1-amd64.deb && \
#    dpkg -i /tmp/pandoc-2.7.1.deb && \
#    rm /tmp/pandoc-2.7.1.deb

# Create unprivileged user
# ------------------------
# The gosu and entrypoint magic is used to create an unprivileged user
# at `docker run`-time with the same uid as the host user. Thus, the mounted
# host volume has the correct uid:guid permissions. For details:
# https://denibertovic.com/posts/handling-permissions-with-docker-volumes/
# Note: the --no-tty is necessary due to a bug
# https://github.com/nodejs/docker-node/issues/922
# 
# details on why to use hkp://... : https://superuser.com/a/1250706
#RUN gpg --no-tty --keyserver pgp.mit.edu --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
#RUN gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.4/gosu-$(dpkg --print-architecture)" \
    && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.4/gosu-$(dpkg --print-architecture).asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]


# Install required python dependencies
# ------------------------------------

# Note: the GDAL package version must exactly match the one
# 	    of installed libgdal-dev library version, hence the special treatment
#		https://gis.stackexchange.com/a/119565
RUN pip install setuptools \
    && pip install --global-option=build_ext --global-option="-I/usr/include/gdal" GDAL==$(gdal-config --version | awk -F'[.]' '{print $1"."$2}')

# Install what's in requirements.txt
# and some other extensions:
# - geojson-extension:
# - drawio: create and edit draw.io drawings directly in jupyterlab
# - celltags: tag cells (e.g. with 'hidden' to exclude from export)
COPY requirements.txt /tmp/
RUN pip install -r /tmp/requirements.txt && \
    pip install --force-reinstall --no-cache-dir jupyter && \
    pip freeze
RUN npm list --depth=1 -g && \
    jupyter labextension install @jupyterlab/geojson-extension && \
    jupyter labextension install jupyterlab-drawio && \
    jupyter labextension install @jupyterlab/celltags && \
    jupyter contrib nbextension install --system

# Install drawio-batch
# --------------------
RUN git clone https://github.com/languitar/drawio-batch.git /tmp/drawio-batch \
    && cd /tmp/drawio-batch \
    && npm install && npm install -g


WORKDIR /home/user

EXPOSE 8888
#CMD ["jupyter", "notebook", "--port=8888", "--no-browser", "--ip=0.0.0.0"]
CMD ["jupyter", "lab", "--port=8888", "--no-browser", "--ip=0.0.0.0"]

