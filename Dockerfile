FROM ubuntu:bionic

LABEL maintainer="Ricardo B. Lourenco <rblourenco@uchicago.edu>"

# Define analogue to miniconda
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH /opt/conda/bin:$PATH

RUN apt-get update --fix-missing && \
    apt-get install -y wget bzip2 ca-certificates curl git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-4.5.11-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda clean -tipsy && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc

ENV TINI_VERSION v0.16.1
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini

ENTRYPOINT [ "/usr/bin/tini", "--" ]
CMD [ "/bin/bash" ]

#

RUN conda install py4j
RUN apt-get update \
  && apt-get install -y curl unzip \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

#TODO: Ver se ausencia de python dá crash
#RUN apt-get update \
#  && apt-get install -y curl unzip \
#    python3 python3-setuptools \
#  && ln -s /usr/bin/python3 /usr/bin/python \
#  && easy_install3 pip py4j \
#  && apt-get clean \
#  && rm -rf /var/lib/apt/lists/*

#RUN apt-get update
#RUN apt-get install -y curl unzip python3 python3-setuptools python3-pip
#RUN ln -s /usr/bin/python3 /usr/bin/python
#RUN pip install py4j
#RUN apt-get clean
#RUN rm -rf /var/lib/apt/lists/*
#
#ENV PYTHONHASHSEED 0
#ENV PYTHONIOENCODING UTF-8
#ENV PIP_DISABLE_PIP_VERSION_CHECK 1

# JAVA
RUN add-apt-repository ppa:webupd8team/java
RUN apt-get update
RUN apt install oracle-java8-installer
#ARG JAVA_MAJOR_VERSION=8
#ARG JAVA_UPDATE_VERSION=131
#ARG JAVA_BUILD_NUMBER=11
#ENV JAVA_HOME /usr/jdk1.${JAVA_MAJOR_VERSION}.0_${JAVA_UPDATE_VERSION}
#
#ENV PATH $PATH:$JAVA_HOME/bin
#RUN curl -sL --retry 3 --insecure \
#  --header "Cookie: oraclelicense=accept-securebackup-cookie;" \
#  "http://download.oracle.com/otn-pub/java/jdk/${JAVA_MAJOR_VERSION}u${JAVA_UPDATE_VERSION}-b${JAVA_BUILD_NUMBER}/d54c1d3a095b4ff2b6607d096fa80163/server-jre-${JAVA_MAJOR_VERSION}u${JAVA_UPDATE_VERSION}-linux-x64.tar.gz" \
#  | gunzip \
#  | tar x -C /usr/ \
#  && ln -s $JAVA_HOME /usr/java \
#  && rm -rf $JAVA_HOME/man

# HADOOP
ENV HADOOP_VERSION 2.8.3
ENV HADOOP_HOME /usr/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV PATH $PATH:$HADOOP_HOME/bin
RUN curl -sL --retry 3 \
  "http://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" \
  | gunzip \
  | tar -x -C /usr/ \
 && rm -rf $HADOOP_HOME/share/doc \
 && chown -R root:root $HADOOP_HOME

# SPARK
ENV SPARK_VERSION 2.4.1
ENV SPARK_PACKAGE spark-${SPARK_VERSION}-bin-without-hadoop
ENV SPARK_HOME /usr/spark-${SPARK_VERSION}
ENV SPARK_DIST_CLASSPATH="$HADOOP_HOME/etc/hadoop/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/tools/lib/*"
ENV PATH $PATH:${SPARK_HOME}/bin
RUN curl -sL --retry 3 \
  "https://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename=spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz" \
  | gunzip \
  | tar x -C /usr/ \
 && mv /usr/$SPARK_PACKAGE $SPARK_HOME \
 && chown -R root:root $SPARK_HOME

WORKDIR $SPARK_HOME