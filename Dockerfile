# Centos 7 with OpenJDK 11.x and OpenSSL 1.x and Tomcat 9.x / Tomcat Native Library

FROM centos:centos7
MAINTAINER Wolf Paulus <wolf@paulus.com>

ARG OPEN_JDK=11.0.2
ARG OPENSSL_VERSION=1.0.2
ARG TOMCAT_MAJOR=9
ARG TOMCAT_MINOR=9.0.22
ARG TOMCAT_NATIVE=1.2.23

# Install prepare infrastructure
RUN yum -y update && \
 yum -y upgrade && \
 yum -y install wget && \
 yum -y install tar && \
 yum -y install wget && \
 yum -y install perl && \
 yum -y install apr-devel && \
 yum -y install openssl-devel && \
 yum groupinstall -y "Development tools"

# Install OpenJDK 11
ENV OPEN_JDK ${OPEN_JDK}
RUN curl -O https://download.java.net/java/GA/jdk11/9/GPL/openjdk-${OPEN_JDK}_linux-x64_bin.tar.gz && \
    tar zxvf openjdk-${OPEN_JDK}_linux-x64_bin.tar.gz && \
    rm openjdk-${OPEN_JDK}_linux-x64_bin.tar.gz && \
    mv jdk-${OPEN_JDK} /usr/local
ENV JAVA_HOME /usr/local/jdk-${OPEN_JDK}
ENV JRE_HOME /usr/local/jdk-${OPEN_JDK}

# Install OpenSSL
ENV OPENSSL_VERSION ${OPENSSL_VERSION}
RUN curl -#L https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz -o /tmp/openssl.tar.gz
WORKDIR /tmp
RUN tar zxvf openssl.tar.gz && \
    rm openssl.tar.gz && \
    mv openssl-* openssl && \
    cd openssl && \
    ./config shared && \
    make depend && \
    make install && \
    rm -rf /tmp/*

# Install Tomcat
ENV TOMCAT_MAJOR ${TOMCAT_MAJOR}
ENV TOMCAT_MINOR ${TOMCAT_MINOR}
ENV TOMCAT_LINK  http://apache.mirrors.pair.com/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_MINOR}/bin/apache-tomcat-${TOMCAT_MINOR}.tar.gz
ENV TOMCAT_NATIVE ${TOMCAT_NATIVE}
ENV TOMCAT_NATIVE_LINK http://apache.mirrors.pair.com/tomcat/tomcat-connectors/native/${TOMCAT_NATIVE}/source/tomcat-native-${TOMCAT_NATIVE}-src.tar.gz
ENV CATALINA_HOME /opt/tomcat

WORKDIR /opt/tomcat
RUN curl -#L ${TOMCAT_LINK} -o /tmp/apache-tomcat.tar.gz
RUN tar zxvf /tmp/apache-tomcat.tar.gz -C /opt && \
    rm /tmp/apache-tomcat.tar.gz && \
    mv /opt/apache-tomcat-${TOMCAT_MINOR}/* /opt/tomcat

# Build and Install the native connector
RUN curl -#L ${TOMCAT_NATIVE_LINK} -o /tmp/tomcat-native.tar.gz
RUN mkdir -p /opt/tomcat-native && \
    tar zxvf /tmp/tomcat-native.tar.gz -C /opt/tomcat-native --strip-components=1 && \
    rm /tmp/*tar.gz && \
    cd /opt/tomcat-native/native && \
    ./configure \
        --libdir=/usr/lib/ \
        --prefix="$CATALINA_HOME" \
        --with-apr=/usr/bin/apr-1-config \
        --with-java-home="$JAVA_HOME" \
        --with-ssl=yes && \
    make -j$(nproc) && \
    make install && \
    rm -rf /opt/tomcat-native /tmp/openssl

RUN set -e \
	if `/opt/tomcat/bin/catalina.sh configtest | grep -q 'INFO: Loaded APR based Apache Tomcat Native library'` \
        then \
	    echo "Build Passed" \
        else \
            echo "Build Failed" \
            exit 1 \
	fi

RUN yum remove -y apr-devel kernel-devel kernel-headers boost* rsync perl* && \
 yum groupremove -y "Development Tools" && \
 yum clean all

 EXPOSE 8080
 CMD ["/opt/tomcat/bin/catalina.sh", "run"]
