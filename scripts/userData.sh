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
        
echo '=========================== Creating volumes ==========================='
pvcreate /dev/xvdh
vgcreate vg-docker /dev/xvdh
while [ $(lvs vg-docker/data &> /dev/null; echo $?) -ne 0 ]; do lvcreate -l 95%VG -n data vg-docker; done
while [ $(lvs vg-docker/metadata &> /dev/null; echo $?) -ne 0 ]; do lvcreate -l 5%VG -n metadata vg-docker; done
mkdir /mnt/docker-data && mkdir /mnt/docker-volumes
mkfs.ext4 /dev/xvdf && mkfs.ext4 /dev/xvdg
mount -t ext4 /dev/xvdf /mnt/docker-data
mount -t ext4 /dev/xvdg /mnt/docker-volumes
ln -s /mnt/docker-data /var/lib/docker
ln -s /mnt/docker-volumes /var/lib/docker/volumes
echo 'other_args="-g /mnt/docker-data"' >> /etc/sysconfig/docker
echo "/dev/xvdf /mnt/docker-data ext4 defaults 0 0" >> /etc/fstab
echo "/dev/xvdg /mnt/docker-volumes ext4 defaults 0 0" >> /etc/fstab

echo '=========================== Configuring Docker Daemon ==========================='
grep 'tcp://0.0.0.0:2375' /usr/lib/systemd/system/docker.service || sed -i 's#ExecStart\(.*\)$#ExecStart\1 -H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375#' /usr/lib/systemd/system/docker.service
sed -i "s/ExecStart\\(.*\\)$/ExecStart\\1 --storage-driver=devicemapper --storage-opt dm.datadev=\\/dev\\/vg-docker\\/data --storage-opt dm.metadatadev=\\/dev\\/vg-docker\\/metadata/g" /usr/lib/systemd/system/docker.service
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

echo '=========================== Running Docker Compose =========================='
export IP=$(hostname --ip-address)
export PUBLIC_IP=$(curl http://instance-data/latest/meta-data/public-ipv4)
export PRIVATE_IP=$(curl http://instance-data/latest/meta-data/local-ipv4)
export JENKINS_TOKEN=gAsuE35s
export DOCKER_HOST=tcp://${PRIVATE_IP}:2375
set -e
mkdir -p /data && cd /data
git clone https://github.com/Accenture/adop-docker-compose
cd /data/adop-docker-compose
export METADATA_URL='http://169.254.169.254/latest/meta-data'
export MAC_ADDRESS=$(curl -s ${METADATA_URL}/network/interfaces/macs/)
export AWS_VPC_ID=$(curl -s ${METADATA_URL}/network/interfaces/macs/${MAC_ADDRESS}/vpc-id/)
export AWS_SUBNET_ID=$(curl -s ${METADATA_URL}/network/interfaces/macs/${MAC_ADDRESS}/subnet-id/)
export AWS_AZ=$(curl -s ${METADATA_URL}/placement/availability-zone)
export AWS_DEFAULT_REGION=${AWS_AZ%?}
echo "export AWS_VPC_ID=${AWS_VPC_ID}" > conf/provider/env.provider.aws.sh
echo "export AWS_SUBNET_ID=${AWS_SUBNET_ID}" >> conf/provider/env.provider.aws.sh 
echo "export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}" >> conf/provider/env.provider.aws.sh 
echo "export AWS_INSTANCE_TYPE='t2.large'" >> conf/provider/env.provider.aws.sh
echo "export AWS_KEYPAIR=${KeyName}" >> conf/provider/env.provider.aws.sh
./adop compose -i ${PUBLIC_IP} -f etc/aws/default.yml init
sleep 10
./adop certbot gen-export-certs "registry.${PUBLIC_IP}.nip.io" registry

echo '=========================== Setting up ADOP-C =========================='
until [[ $(curl -X GET -s ${INITIAL_ADMIN_USER}:${INITIAL_ADMIN_PASSWORD_PLAIN}@${PUBLIC_IP}/jenkins/job/Load_Platform/lastBuild/api/json?pretty=true|grep result|cut -d$' ' -f5|sed 's|[^a-zA-Z]||g') == SUCCESS ]]; do echo "Load_Platform job not finished, sleeping for 5s"; sleep 5; done
./adop target set -t http://${PUBLIC_IP} -u ${INITIAL_ADMIN_USER} -p ${INITIAL_ADMIN_PASSWORD_PLAIN}
set +e
aws s3 cp platform.secrets.sh s3://${SecretS3BucketStore}/platform.secrets.sh

echo "=========================== ADOP-C setup complete ==========================="