FROM python:3.6-stretch
#FROM jupyter/minimal-notebook

#ARG NB_USER="nbuser"
#ARG NB_UID="1000"
#ARG NB_GID="100"

#ENV TINI_VERSION v0.6.0
#ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
#RUN chmod +x /usr/bin/tini
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get update && apt-get remove ipython && apt-get install -y \
        python3-dev \
        ca-certificates \
        curl \
    	gpg \
	    libgdal-dev \
        nodejs

# The gosu and entrypoint magic is used to create an unprivileged user
# at `docker run`-time with the same uid as the host user. Thus, the mounted
# host volume has the correct uid:guid permissions. For details:
# https://denibertovic.com/posts/handling-permissions-with-docker-volumes/
# Note: the --no-tty is necessary due to a bug
# https://github.com/nodejs/docker-node/issues/922
RUN gpg --no-tty --keyserver pgp.mit.edu --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
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
RUN pip install --global-option=build_ext --global-option="-I/usr/include/gdal" GDAL==$(gdal-config --version | awk -F'[.]' '{print $1"."$2}')

# Install what's in requirements.txt
COPY requirements.txt /tmp/
RUN pip install -r /tmp/requirements.txt && \
    pip install --force-reinstall --no-cache-dir jupyter && \
    pip freeze && \
    jupyter labextension install @jupyterlab/geojson-extension

WORKDIR /home/user

EXPOSE 8888
#CMD ["jupyter", "notebook", "--port=8888", "--no-browser", "--ip=0.0.0.0"]
CMD ["jupyter", "lab", "--port=8888", "--no-browser", "--ip=0.0.0.0"]

