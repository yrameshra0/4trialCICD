#!/bin/bash -xe

export DEBIAN_FRONTEND=noninteractive
echo "path-exclude /usr/share/doc/*" > /etc/dpkg/dpkg.cfg.d/01_nodoc

# docker (CLI only)
export DOCKER_VERSION="18.09.0"
curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_VERSION.tgz > docker.tgz
tar xzf docker.tgz
chmod +x docker/docker
mv docker/docker /usr/local/bin/

# cleanup
rm -Rf /var/lib/apt /var/cache/apt docker docker.tgz

usermod -aG root jenkins