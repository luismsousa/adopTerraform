#!/bin/bash
echo '=========================== Installing Yum Packages ==========================='
cat > /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/$releasever/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF
yum -y install wget unzip git lvm2 docker-engine-1.12.6-1.el7.centos.x86_64 ntp


echo '=========================== Configuring Docker Daemon ==========================='
grep 'tcp://0.0.0.0:2375' /usr/lib/systemd/system/docker.service || sed -i 's#ExecStart\(.*\)$#ExecStart\1 -H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375#' /usr/lib/systemd/system/docker.service
/usr/lib/systemd/system/docker.service
systemctl daemon-reload && systemctl enable docker && systemctl restart docker

echo '=========================== Configuring NTP =========================='
sed -i "s/centos/${NtpRegion}/g" /etc/ntp.conf
systemctl start ntpd && systemctl enable ntpd && systemctl status ntpd
sleep 20
ntpq -p
ntpstat          

echo '============================== Installing AWS CLI ============================='
wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py
pip install --upgrade --user awscli
export PATH=~/.local/bin:$PATH

echo '=========================== Installing Docker Compose =========================='
curl -L https://github.com/docker/compose/releases/download/1.7.1/docker-compose-`uname -s`-`uname -m` > /usr/bin/docker-compose
chmod +x /usr/bin/docker-compose


export METADATA_API='?api-version=2018-04-02&format=text'
export METADATA_URL='http://169.254.169.254/metadata/instance'
echo '=========================== Running Docker Compose =========================='
export PUBLIC_IP=$(curl -s -H Metadata:true "${METADATA_URL}/network/interface/0/ipv4/ipAddress/0/publicIpAddress${METADATA_API}")
export PRIVATE_IP=$(curl -s -H Metadata:true "${METADATA_URL}/network/interface/0/ipv4/ipAddress/0/privateIpAddress${METADATA_API}")
export JENKINS_TOKEN=gAsuE35s
export DOCKER_HOST=tcp://${PRIVATE_IP}:2375
set -e
mkdir -p /data && cd /data
git clone https://github.com/Accenture/adop-docker-compose
cd /data/adop-docker-compose
export MAC_ADDRESS=$(curl -s -H Metadata:true "${METADATA_URL}/network/interface/0/macAddress${METADATA_API}")

./adop compose -i ${PUBLIC_IP} init
sleep 10
./adop certbot gen-export-certs "registry.${PUBLIC_IP}.nip.io" registry

echo '=========================== Setting up ADOP-C =========================='
until [[ $(curl -X GET -s ${INITIAL_ADMIN_USER}:${INITIAL_ADMIN_PASSWORD_PLAIN}@${PUBLIC_IP}/jenkins/job/Load_Platform/lastBuild/api/json?pretty=true|grep result|cut -d$' ' -f5|sed 's|[^a-zA-Z]||g') == SUCCESS ]]; do echo "Load_Platform job not finished, sleeping for 5s"; sleep 5; done
./adop target set -t http://${PUBLIC_IP} -u ${INITIAL_ADMIN_USER} -p ${INITIAL_ADMIN_PASSWORD_PLAIN}
set +e

echo "=========================== ADOP-C setup complete ==========================="