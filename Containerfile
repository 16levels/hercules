# Install hercules dependencies to builder stage:
#
FROM fedora:latest as builder
RUN <<EOF
dnf update
dnf install -y time which libtool regina-rexx regina-rexx-devel regina-rexx-libs git wget gcc make cmake flex gawk m4 autoconf automake libtool-ltdl-devel bzip2-devel zlib-devel
useradd hercules
echo 'hercules ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
EOF

# Build SDL-Hyperion using 'wrljet/hercules-helper': 
#
USER hercules
WORKDIR /home/hercules
RUN <<EOF
git clone https://github.com/wrljet/hercules-helper.git
mkdir build
cd build
~/hercules-helper/hercules-buildall.sh --auto --flavor=sdl-hyperion --no-packages --sudo --no-envscript --no-bashrc --prefix=/opt/herc4x --no-setcap
EOF

# Install REXX in runtime container
#
FROM fedora:latest
RUN <<EOF
dnf -y update
dnf -y install regina-rexx regina-rexx-libs
dnf clean all
useradd hercules 
EOF

# Copy SDL-Hyperion build to runtime container.
# Set environment variables, binary capabilities and attributes.
# Create symbolic link to REXX library object for discoverability.  
USER hercules
WORKDIR /home/hercules
ENV PATH="/opt/herc4x/bin:${PATH}" LD_LIBRARY_PATH="/opt/herc4x/lib"
COPY --from=builder /opt/herc4x/ /opt/herc4x
USER root
RUN <<EOF
setcap 'cap_sys_nice=eip' /opt/herc4x/bin/hercules
setcap 'cap_sys_nice=eip' /opt/herc4x/bin/herclin
setcap 'cap_net_admin+ep' /opt/herc4x/bin/hercifc
ln -s /lib64/libregina.so.3 /lib64/libregina.so
EOF

# Create Hercules machine and runtime configuration files:
USER hercules
WORKDIR /home/hercules
EXPOSE 3270/tcp
EXPOSE 8038/tcp

CMD hercules
