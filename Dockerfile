#==========================================================
# PALMID BASE CONTAINER ===================================
#==========================================================
# Docker Base: amazon linux2
FROM amazonlinux:2 AS serratus-base

## Build/test container for palmid
# sudo yum install -y docker git
# sudo service docker start
# git clone https://github.com/ababaian/palmid.git; cd palmid
#
# sudo docker build -t palmid:local
#

## Push to dockerhub
# sudo docker login
# 
#
# sudo docker build \
#  -t serratusbio/palmid 
#  -t serratusbio/palmid:0.0.0
#  -t palmid:latest .
#
# sudo docker push serratusbio/palmid

## Dev testing to enter enter
# sudo docker run --rm --entrypoint /bin/bash -it palmid:latest

#==========================================================
# Container Meta-data =====================================
#==========================================================
# Set working directory
# RUN adduser palmid
ARG BASEDIR=/home/palmid
ENV BASEDIR=/home/palmid
WORKDIR /home/palmid

# Container Information
ARG PROJECT='palmid'
ARG TYPE='base'
ARG VERSION='0.0.0'

# Software Versions (pass to shell)
#ENV SAMTOOLSVERSION='1.10'
ENV SEQKITVERSION='0.16.1'
ENV PALMSCANVERSION='1.0'
ENV R='4'

# Additional Metadata
LABEL author="ababaian"
LABEL container.base.image="amazonlinux:2"
LABEL project.name=${PROJECT}
LABEL project.website="https://github.com/ababaian/serratus"
LABEL container.type=${TYPE}
LABEL container.version=${VERSION}
LABEL container.description="palmid-base image"
LABEL software.license="GPLv3"
LABEL tags="palmscan, R"

#==========================================================
# palmid Initialize =======================================
#==========================================================
# scripts + test data
COPY scripts/* ./
COPY data/* data/
RUN chmod 755 palmid.sh &&\
    chmod 755 fev2tsv.py &&\

#==========================================================
# Dependencies ============================================
#==========================================================
# Update Core
RUN yum -y update
RUN yum -y install tar wget gzip which sudo shadow-utils \
           util-linux byacc git

# For development
RUN yum -y install vim htop less

# htslib/samtools
RUN yum -y install gcc make \
    unzip bzip2 bzip2-devel xz-devel zlib-devel \
    curl-devel openssl-devel \
    ncurses-devel

# Python3
RUN yum -y install python3 python3-devel
RUN alias python=python3
RUN curl -O https://bootstrap.pypa.io/get-pip.py &&\
    python3 get-pip.py &&\
    rm get-pip.py

# AWS S3
RUN pip install boto3 awscli
RUN yum -y install jq

# R
RUN yum -y install libxml2-devel

#==========================================================
# Install Software ========================================
#==========================================================

# SeqKit ========================================
RUN wget https://github.com/shenwei356/seqkit/releases/download/v${SEQKITVERSION}/seqkit_linux_amd64.tar.gz &&\
  tar -xvf seqkit* && mv seqkit /usr/local/bin/ &&\
  rm seqkit_linux*

# SAMTOOLS ====================================== (opt?)
## Download
# RUN wget -O /samtools-${SAMTOOLSVERSION}.tar.bz2 \
#   https://github.com/samtools/samtools/releases/download/${SAMTOOLSVERSION}/samtools-${SAMTOOLSVERSION}.tar.bz2 &&\
#   tar xvjf /samtools-${SAMTOOLSVERSION}.tar.bz2 &&\
#   rm /samtools-${SAMTOOLSVERSION}.tar.bz2 &&\
#   cd samtools-${SAMTOOLSVERSION} && make && make install &&\
#   cd .. && rm -rf samtools-${SAMTOOLSVERSION}


# PALMSCAN ======================================
RUN wget -O /usr/local/bin/palmscan \
  https://github.com/ababaian/palmscan/releases/download/v${PALMSCANVERSION}/palmscan-v${PALMSCANVERSION} &&\
  chmod 755 /usr/local/bin/palmscan

# R 4.0 =========================================
# Install R and packages
# Note: 1 GB install
# - devtools
# - palmid
RUN amazon-linux-extras install R4 &&\
  R -e 'install.packages("devtools", repos = "http://cran.us.r-project.org")' &&\
  R -e 'library("devtools"); install_github("ababaian/palmid")'

#==========================================================
# Resource Files ==========================================
#==========================================================
# Sequence resources / databases for analysis
# RUN cd /home/palmid/ &&\
#   git clone https://github.com/rcedgar/palmdb.git &&\
#   gzip -dr palmdb/*

# Increase the default chunksize for `aws s3 cp`.  By default it is 8MB,
# which results in a very high number of PUT and POST requests.  These
# numbers have NOT been experimented on, but chosen to be just below the
# max size for a single-part upload (5GB).  I haven't pushed it higher
# because I don't want to test the edge cases where a filesize is around
# the part limit.
# RUN aws configure set default.s3.multipart_threshold 4GB \
#  && aws configure set default.s3.multipart_chunksize 4GB

#==========================================================
# palmid-R initialize =====================================
#==========================================================
# Copy palmidR R package
#COPY R ./
#COPY DESCRIPTION ./
#COPY NAMESPACE ./
#COPY man ./

#==========================================================
# ENTRYPOINT ==============================================
#==========================================================
ENTRYPOINT ["/home/palmid/palmid.sh"]