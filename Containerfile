FROM fedora:42 as builder
LABEL org.opencontainers.image.source https://github.com/16levels/hercules

# Install hercules dependencies to builder stage:
#
RUN <<EOF
dnf update
dnf install -y time which libtool regina-rexx regina-rexx-devel regina-rexx-libs git wget gcc make cmake flex gawk m4 autoconf automake libtool-ltdl-devel bzip2-devel zlib-devel
dnf clean all
useradd hercules
echo 'hercules ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
EOF

# Build SDL-Hyperion using 'wrljet/hercules-helper': 
#
USER hercules
WORKDIR /home/hercules/build
RUN <<EOF
git clone https://github.com/wrljet/hercules-helper.git ~/hercules-helper/
~/hercules-helper/hercules-buildall.sh --auto --flavor=sdl-hyperion --no-packages --sudo --no-envscript --no-bashrc --prefix=/opt/herc4x --no-setcap
EOF

# Copy SDL-Hyperion build to runtime container.
# Install REXX in runtime container
# Set binary capabilities.
# Create symbolic link to REXX library object for discoverability.  
#
FROM fedora:42
COPY --from=builder /opt/herc4x /opt/herc4x

RUN <<EOF
dnf -y update
dnf -y install regina-rexx regina-rexx-libs
dnf clean all
useradd hercules 
setcap 'cap_sys_nice=eip' /opt/herc4x/bin/hercules
setcap 'cap_sys_nice=eip' /opt/herc4x/bin/herclin
setcap 'cap_net_admin+ep' /opt/herc4x/bin/hercifc
ln -s /lib64/libregina.so.3 /lib64/libregina.so
EOF

# Set environment variables
#
ENV PATH="/opt/herc4x/bin:${PATH}" LD_LIBRARY_PATH="/opt/herc4x/lib"
WORKDIR /home/hercules
USER hercules
EXPOSE 3270/tcp
EXPOSE 8081/tcp

CMD ["hercules"]
