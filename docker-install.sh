#/bin/bash

set -e
echo "" > /tmp/docker-install.log
# 0. prepare user docke
#id docker >/dev/null 2>&1 || (
#    chattr -i /etc/passwd;
#    chattr -i /etc/shadow;
#    chattr -i /etc/group;
#    chattr -i /etc/gshadow;
#    useradd -r -s /sbin/nologin docker -g docker;
#    chattr +i /etc/passwd;
#    chattr +i /etc/shadow;
#    chattr +i /etc/group;
#    chattr +i /etc/gshadow;
#    )
#echo "0. prepare user docker" >> /tmp/docker-install.log

# 1. remove old version
yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
echo "1. remove old version" >> /tmp/docker-install.log

# 2. install utils and repo
yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
yum-config-manager --disable docker-ce-edge
yum-config-manager --disable docker-ce-test
yum-config-manager --disable docker-ce-nightly
echo "2. install utils and repo" >> /tmp/docker-install.log

# 3. install docker-ce
VERSION_STRING=18.09.9
yum install -y docker-ce-${VERSION_STRING} docker-ce-cli-${VERSION_STRING} containerd.io

# 如果安装的是`18.09`，需要额外执行以下步骤，来解决docker服务启动失败的问题
# 问题详情参照：https://github.com/docker/for-linux/issues/475
IS_1809=18.09.*
[[ ${VERSION_STRING} =~ ${IS_1809} ]] && (
  [[ -d /etc/systemd/system/containerd.service.d ]] || /usr/bin/mkdir /etc/systemd/system/containerd.service.d;
  [[ -f /etc/systemd/system/containerd.service.d/override.conf ]] || echo -e '[Service]\nExecStartPre=' > /etc/systemd/system/containerd.service.d/override.conf
  )
echo "3. install docker-ce" >> /tmp/docker-install.log

# 4. install docker-compose
if [ ! -f /usr/local/bin/docker-compose ];then
curl -s -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
fi
chmod 755 /usr/local/bin/docker-compose
[[ -L /usr/bin/docker-compose ]] || ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
echo "4. install docker-compose" >> /tmp/docker-install.log

[[ -d /etc/docker ]] || mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

[[ -d /etc/systemd/system/docker.service.d ]] || mkdir -p /etc/systemd/system/docker.service.d

cat << EOF > /etc/systemd/system/docker.service.d/network.conf
[Service]
ExecStartPost=-/usr/bin/docker network create --driver=bridge --subnet=10.255.1.0/24 --ip-range=10.255.1.0/24 --gateway=10.255.1.254 internal
ExecStartPost=-/usr/bin/docker network create --driver=bridge --subnet=10.255.2.0/24 --ip-range=10.255.2.0/24 --gateway=10.255.2.254 production
EOF

# 5. start docker
systemctl daemon-reload
systemctl enable docker
systemctl start docker
echo "5. start docker" >> /tmp/docker-install.log

# 6. make sure iptables rules not lost when restart docker
sed -i 's/^IPTABLES_SAVE_ON_RESTART=.*$/IPTABLES_SAVE_ON_RESTART=\"yes\"/g' /etc/sysconfig/iptables-config
sed -i 's/^IPTABLES_SAVE_ON_STOP=.*$/IPTABLES_SAVE_ON_STOP=\"yes\"/g' /etc/sysconfig/iptables-config
echo "6. make sure iptables rules not lost when restart docker end " >> /tmp/docker-install.log

# 7. init file
[[ -d /home/data ]] || mkdir /home/data
[[ -d /data ]] || ln -s /home/data /data
[[ -d /data/docker ]] || mkdir /data/docker
[[ -d /data/docker/runtime ]] || mkdir /data/docker/runtime
[[ -d /data/docker/yml ]] || mkdir /data/docker/yml
[[ -d /data/docker/data ]] || mkdir /data/docker/data
[[ -d /data/docker/bin ]] || mkdir /data/docker/bin
echo "7. init file " >> /tmp/docker-install.log
