FROM fedora:latest as builder
RUN dnf update && \
    dnf install -y time which libtool regina-rexx regina-rexx-devel \
    regina-rexx-libs git wget gcc make cmake flex gawk m4 autoconf automake \
    libtool-ltdl-devel bzip2-devel zlib-devel && \
    useradd hercules && \
    echo 'hercules ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER hercules
WORKDIR /home/hercules
RUN git clone https://github.com/wrljet/hercules-helper.git && \
    mkdir build && cd build && \
   ~/hercules-helper/hercules-buildall.sh --auto --flavor=sdl-hyperion

FROM fedora:latest
RUN dnf -y update && \
    dnf -y install regina-rexx regina-rexx-libs && \
    useradd hercules 
USER hercules
WORKDIR /home/hercules
ENV PATH="/home/hercules/build/herc4x/bin:${PATH}"
ENV LD_LIBRARY_PATH="/home/hercules/build/herc4x/lib"
COPY --from=builder /home/hercules/build/herc4x/ /home/hercules/build/herc4x
USER root
RUN setcap 'cap_sys_nice=eip' /home/hercules/build/herc4x/bin/hercules && \
    setcap 'cap_sys_nice=eip' /home/hercules/build/herc4x/bin/herclin && \
    setcap 'cap_net_admin+ep' /home/hercules/build/herc4x/bin/hercifc && \
    chown hercules:hercules /home/hercules/build/herc4x/bin/hercules && \
    ln -s /lib64/libregina.so.3 /lib64/libregina.so
USER hercules
