#/bin/bash

# 1. remove old version
yum remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-selinux \
                  docker-engine-selinux \
                  docker-engine

# 2. install utils and repo
yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
yum-config-manager --disable docker-ce-edge

# 3. install docker-ce-17.03.2
# install docker-ce-selinux first
yum install https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-selinux-18.03.1.ce-1.el7.centos.noarch.rpm -y
yum install docker-ce-18.03.1.ce -y

# 4. install docker-compose
curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/bin/docker-compose
chmod 755 /usr/bin/docker-compose
