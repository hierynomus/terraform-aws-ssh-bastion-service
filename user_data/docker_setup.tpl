#!/bin/bash
#debian specific set up for docker https://docs.docker.com/install/linux/docker-ce/debian/#install-using-the-repository
DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable"
apt update
DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce
systemctl start docker
mkdir -p /opt/sshd_worker
#Write out Dockerfile
cat << EOF > /opt/sshd_worker/Dockerfile
FROM ${bastion_container_image}

USER root

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server sudo awscli && \
    echo '\033[1;31mI am a one-time Ubuntu container with passwordless sudo. \033[1;37;41mI will terminate after 12 hours or else on exit\033[0m' > /etc/motd && \
    mkdir /var/run/sshd

EXPOSE ${bastion_ssh_port}
CMD ["/opt/ssh_populate.sh"]
EOF

#Build sshd service container
cd /opt/sshd_worker
docker build -t sshd_worker .

