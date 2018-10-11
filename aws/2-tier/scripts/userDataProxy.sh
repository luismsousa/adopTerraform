#!/bin/bash

echo "################## Configuring Package Repositories ##################"

cat > /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/$releasever/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

yum -y install lvm2 git docker-engine-1.12.6-1.el7.centos.x86_64 ntp

echo '################## Configuring NTP ##################'
sed -i "s/centos/europe/g" /etc/ntp.conf
systemctl start ntpd
systemctl enable ntpd
systemctl status ntpd
sleep 20
ntpq -p
ntpstat

echo "################## Installing AWS CLI ##################"

yum install -y wget
wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py
pip install --upgrade --user awscli
export PATH=~/.local/bin:$PATH

echo "################## Creating volumes ##################"
pvcreate /dev/xvdb
vgcreate vg-docker /dev/xvdb
while [ $(lvs vg-docker/data &> /dev/null; echo $?) -ne 0 ]; do lvcreate -l 95%VG -n data vg-docker; done
while [ $(lvs vg-docker/metadata &> /dev/null; echo $?) -ne 0 ]; do lvcreate -l 5%VG -n metadata vg-docker; done

echo "################## Configuring Docker Daemon ##################"

sed -i 's/ExecStart\\(.*\\)$/ExecStart\\1 --storage-driver=devicemapper --storage-opt dm.datadev=\\/dev\\/vg-docker\\/data --storage-opt dm.metadatadev=\\/dev\\/vg-docker\\/metadata/g' /usr/lib/systemd/system/docker.service
systemctl daemon-reload && systemctl restart docker

echo "################## Running Containers ##################"

mkdir -p /data/config/proxy/sites-enabled && cd /data/config/proxy/sites-enabled
curl -L https://raw.githubusercontent.com/luismsousa/adopTerraform/master/aws/2-tier/config/proxy/sites-enabled/base.conf > base.conf
cd .. #need to check if this works TODO to cleanup
chmod -R 777 ./*
docker run --restart="always" -p 80:80 -d -v $(pwd)/sites-enabled/:/usr/local/nginx/sites-enabled/ -e TARGET=${InternalProxyDnsName} --name=outer-proxy-nginx -d accenture/adop-outer-proxy:0.2.1