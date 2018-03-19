# Ubuntu 16.04 with SonarQube/GoLand scanning tools installed.
#    Barebones installation with GoLang,GoMetaLinter and Sonar-scanner installed and configured
# Creation Date: March 15, 2018

# OS Version - Note that this Dockerfile was greated with Ubuntu in mind.
FROM ubuntu:16.04

# Author
MAINTAINER Dennis Christilaw (https://github.com/Talderon)

# extra metadata
LABEL version="0.6.1"
LABEL description="Beta build of SonarQube Scanner for GoLang."

ENV HOME /root

# Add the hostname to the hosts file
RUN uhost=$(cat /etc/hostname ) && \
    echo '127.0.0.1 '$uhost >> /etc/hosts

# Run updates to ensure the repo's are updated
RUN apt-get update -qy && apt-get upgrade -qy

# Installs software in order to allow for independent vendor software sources, in particular the “add-apt-repository” command that is used elsewhere
# As well as come CLI Tools that are needed for various functions.
RUN apt-get install -qy \
    software-properties-common \
    apt-transport-https \
    ca-certificates curl \
    software-properties-common \
    make \
    vim \
    unzip \
    wget \
    git \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Elevate to Sudo
RUN sudo -s

# Install Docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    apt-get update -qy && \
    apt-get install -qy docker-ce

# Install Kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.9.4/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

# Install GoLang (1.10)
RUN wget https://dl.google.com/go/go1.10.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.10.linux-amd64.tar.gz

# Set GoLang Environment 
RUN mkdir -p $HOME/go_projects/{bin,src,pkg} && \
    mkdir -p /usr/local/sonar-scanner/bin && \
    mkdir -p /usr/local/go/bin

# Configure Path 
RUN echo 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/go/bin:/root/go_projects/bin:/usr/local:/usr/local/sonar-scanner/bin:/usr/local/go/bin"' >>/root/.profile && \
    echo 'GOPATH=$HOME/go_projects'  >>/root/.profile && \
    echo 'GOBIN=$GOPATH/bin' >>/root/.profile

# Source the .profile to get path changes    
RUN /bin/bash -c "source /root/.profile"

# Install GoMetaLinter
RUN go get -u gopkg.in/alecthomas/gometalinter.v2 && \
    mv $HOME/go/bin/gometalinter.v2 $HOME/go/bin/gometalinter && \
    gometalinger --install

# Install Sonar-Scanner
RUN wget https://sonarsource.bintray.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.0.3.778-linux.zip && \
    unzip sonar-scanner-cli-3.0.3.778-linux.zip -d /usr/local/ && \
    mv -f /usr/local/sonar-scanner-3.0.3.778-linux /usr/local/sonar-scanner

# Cleanup	
RUN apt-get -qy autoremove && \
    rm -f ~/go1.10.linux-amd64.tar.gz && \
    rm -f ~/sonar-scanner-cli-3.0.3.778-linux.zip
