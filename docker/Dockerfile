FROM centos
MAINTAINER Javi Fontan <jfontan@gmail.com>

# Use qemu directly instead of libvirt
ENV LIBGUESTFS_BACKEND=direct

RUN yum install -y centos-release-qemu-ev && \
    yum install -y libguestfs libguestfs-tools ruby && \
    yum remove -y linux-firmware && \
    yum autoremove -y && \
    rm -rf /var/cache/yum /var/tmp/.guestfs-0 /tmp/* /root/* && \
    yum clean all

RUN gem install cangallo

CMD ["/bin/bash"]

