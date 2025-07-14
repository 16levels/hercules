FROM alpine:3.22 AS builder
LABEL org.opencontainers.image.source="https://github.com/16levels/hercules"

# Install hercules dependencies to builder stage:
#
RUN <<EOF
apk add --no-cache autoconf automake bash build-base bzip2-dev cmake curl doas-sudo-shim flex gawk gcc git libc6-compat libcap libcap-dev libltdl libtool m4 make musl-locales procps wget zlib-dev

adduser -D hercules
echo 'permit nopass hercules' >> /etc/doas.conf
EOF

# Build Regina-REXX: 
#
USER hercules
WORKDIR /home/hercules/build/regina-rexx-3.9.7
ADD --checksum="sha256:f13701ebd542e74d0fc83b2a7876a812b07d21e43400275ed65b1ac860204bd4" --chown=hercules:hercules https://downloads.sourceforge.net/project/regina-rexx/regina-rexx/3.9.7/regina-rexx-3.9.7.tar.gz /home/hercules/

RUN <<EOF
tar -xz -C ~/build -f ~/regina-rexx-3.9.7.tar.gz
rm ~/regina-rexx-3.9.7.tar.gz

./configure --prefix=/opt/regina
make
sudo make install
EOF

# Build SDL-Hyperion using 'wrljet/hercules-helper': 
#
WORKDIR /home/hercules/build
ENV PATH="/opt/regina/bin:${PATH}" LD_LIBRARY_PATH="/opt/regina/lib" C_INCLUDE_PATH="/opt/regina/include"
RUN <<EOF
git clone https://github.com/wrljet/hercules-helper.git ~/hercules-helper/
~/hercules-helper/hercules-buildall.sh --auto --flavor=sdl-hyperion --sudo --no-packages --no-envscript --no-bashrc --prefix=/opt/herc4x --no-setcap
EOF

# Copy SDL-Hyperion build to runtime container.
# Set binary capabilities.
#
FROM alpine:3.22
COPY --from=builder /opt/regina /opt/regina
COPY --from=builder /opt/herc4x /opt/herc4x

RUN <<EOF
apk add --no-cache libbz2 libcap

adduser -D hercules 
setcap 'cap_sys_nice=eip' /opt/herc4x/bin/hercules
setcap 'cap_sys_nice=eip' /opt/herc4x/bin/herclin
setcap 'cap_net_admin+ep' /opt/herc4x/bin/hercifc

ln -s /opt/regina/lib/libregina.so.3.9 /usr/local/lib/libregina.so

EOF

# Set environment variables, user & working directory.
#
ENV PATH="/opt/herc4x/bin:/opt/regina/bin:${PATH}" LD_LIBRARY_PATH="/opt/herc4x/lib:/opt/regina/lib"
WORKDIR /home/hercules
USER hercules

CMD ["hercules"]
