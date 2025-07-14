FROM alpine:3.22 AS builder
LABEL org.opencontainers.image.source https://github.com/16levels/hercules

# Install hercules dependencies to builder stage:
#
RUN <<EOF
apk add --no-cache curl libc6-compat musl-locales procps build-base bash doas-sudo-shim libtool git wget gcc make cmake flex gawk m4 autoconf automake libltdl bzip2-dev zlib-dev libcap libcap-dev

adduser -D hercules
echo 'permit nopass hercules' >> /etc/doas.conf
EOF

# Build SDL-Hyperion using 'wrljet/hercules-helper': 
#
USER hercules
WORKDIR /home/hercules/build
RUN <<EOF
git clone https://github.com/wrljet/hercules-helper.git ~/hercules-helper/
~/hercules-helper/hercules-buildall.sh --auto --flavor=sdl-hyperion --sudo --no-packages --no-envscript --no-bashrc --prefix=/opt/herc4x --no-setcap --no-rexx
EOF

# Copy SDL-Hyperion build to runtime container.
# Set binary capabilities.
#
FROM alpine:3.22
COPY --from=builder /opt/herc4x /opt/herc4x

RUN <<EOF
apk add --no-cache libbz2 libcap

adduser -D hercules 
setcap 'cap_sys_nice=eip' /opt/herc4x/bin/hercules
setcap 'cap_sys_nice=eip' /opt/herc4x/bin/herclin
setcap 'cap_net_admin+ep' /opt/herc4x/bin/hercifc

EOF

# Set environment variables, user & working directory.
#
ENV PATH="/opt/herc4x/bin:${PATH}" LD_LIBRARY_PATH="/opt/herc4x/lib"
WORKDIR /home/hercules
USER hercules

CMD ["hercules"]
