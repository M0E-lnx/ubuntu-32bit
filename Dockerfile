FROM scratch
# Download from https://partner-images.canonical.com/core/trusty/current/ubuntu-trusty-core-cloudimg-i386-root.tar.gz
ADD ubuntu-trusty-core-cloudimg-i386-root.tar.gz /

# a few minor docker-specific tweaks
# see https://github.com/docker/docker/blob/master/contrib/mkimage/debootstrap
RUN echo '#!/bin/sh' > /usr/sbin/policy-rc.d \
	&& echo 'exit 101' >> /usr/sbin/policy-rc.d \
	&& chmod +x /usr/sbin/policy-rc.d \
	\
	&& dpkg-divert --local --rename --add /sbin/initctl \
	&& cp -a /usr/sbin/policy-rc.d /sbin/initctl \
	&& sed -i 's/^exit.*/exit 0/' /sbin/initctl \
	\
	&& echo 'force-unsafe-io' > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup \
	\
	&& echo 'DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' > /etc/apt/apt.conf.d/docker-clean \
	&& echo 'APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' >> /etc/apt/apt.conf.d/docker-clean \
	&& echo 'Dir::Cache::pkgcache ""; Dir::Cache::srcpkgcache "";' >> /etc/apt/apt.conf.d/docker-clean \
	\
	&& echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/docker-no-languages \
	\
	&& echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/docker-gzip-indexes

# enable the universe
RUN sed -i 's/^#\s*\(deb.*universe\)$/\1/g' /etc/apt/sources.list
ENV TERM=linux
ENV EDITOR=nano
RUN echo "nameserver 8.8.8.8" >/etc/resolv.conf && apt-get update && \
  echo 'APT::Install-Recommends 0;' >> /etc/apt/apt.conf.d/01norecommends && \
  echo 'APT::Install-Suggests 0;' >> /etc/apt/apt.conf.d/01norecommends && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y nano wget sudo net-tools software-properties-common \
  ca-certificates unzip && \
  apt-add-repository -y ppa:brightbox/ruby-ng && \
  apt-get -y purge software-properties-common && apt-get -y autoremove && \
  rm -rf /var/lib/apt/lists/* 

# overwrite this with 'CMD []' in a dependent Dockerfile
CMD ["/bin/bash"]
