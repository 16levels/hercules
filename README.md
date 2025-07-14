# oci-hercules
Builds the latest SDL-Hercules (Hyperion) within an OCI container.

## How to build
```
podman build -t 16levels/hercules https://github.com/16levels/hercules.git
```

## How to run
By default, hercules runs within this container as a non-root user. In order to run in unprivileged mode, the `NET_ADMIN`[^net_admin] and `SYS_NICE`[^sys_nice] Linux capabilities must be granted by providing the option `--cap-add=NET_ADMIN,SYS_NICE`.[^capabilities]

- Use the options `-it` (`-i`, `-t`) to launch an interactive session. 
- Alternatively, specify `-d` to launch the container in daemon mode. 
- Use the option `-p` to explicitly publish ports as defined in `HERCULES_CNF`.

Example (Interactive Panel):
```
podman run -it \
        --cap-add=NET_ADMIN,SYS_NICE \
        -p 3270:3270 -p 8081:8081 \
        ghcr.io/16levels/hercules
```

To IPL the system, use the `-v=` option to create a bind mount of the host directory containing necessary configuration and storage files under a subdirectory of `/home/hercules/` within the container. Use the `-w=` option to set the container's `WORKDIR` to the mount destination.

Hercules will look for machine and runtime configuration files named `hercules.cnf` and `hercules.rc` in the working directory. Explicitly set relative paths to `HERCULES_CNF` and `HERCULES_RC` at runtime by using the `-e=` option to set environment variables: 

```
podman run -d \
        --cap-add=NET_ADMIN,SYS_NICE \
        -p 3270:3270 -p 8038:8038 \
        -v "$(pwd)/VSE":/home/hercules/VSE \
        -w /home/hercules/VSE \
        -e HERCULES_CNF="vse.cnf" \
        -e HERCULES_RC="vse.rc" \
        ghcr.io/16levels/hercules
```

Alternatively, all necessary configuration and storage files can be built into a child container image.

Containerfile:
```
FROM alpine:3.22 AS builder
RUN apk add --no-cache 7zip=24.09-r0
COPY VSE.iso /tmp
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN <<EOF
7z x -o'/VSE' /tmp/VSE.iso VSE/DOSRES.ZIP VSE/SYSWK1.ZIP README.CKD
find /VSE -iname '*.zip' -print0 | xargs -n1 -I {} sh -c "7z x -o'/VSE' {}; rm {};"
find /VSE -type d -empty -delete
EOF

FROM 16levels/hercules:latest
# Copy VSE/ESA to runtime container.
COPY --from=builder --chown=hercules:hercules /VSE /home/hercules/VSE

# Create Hercules machine and runtime configuration files:
USER hercules
WORKDIR /home/hercules/VSE


COPY <<EOF vse.rc
ipl 150
EOF


COPY <<EOF vse.cnf
MANUFACTURER IBM
PLANT        02
CPUSERIAL    000001
MODEL        X47
CPUMODEL     7060
MAINSIZE     512
XPNDSIZE     0
CNSLPORT     3270          # Console Port (3270/tcp)
NUMCPU       1
OSTAILOR     VSE
PANOPT       RATE=FAST
ARCHMODE     ESA/390
PGMPRDOS     LICENSED

# DEVICES
000E     1403
000F     1403
0500     3420
0501     3420
0590     3480
001F     3270
0200     3270
0201     3270
0202     3270
0203     3270
0150     3390     DOSRES.150
0151     3390     SYSWK1.151

HTTP     PORT     8081 NOAUTH
HTTP     START
EOF


ENV HERCULES_CNF="vse.cnf" HERCULES_RC="vse.rc"
EXPOSE 3270/tcp 8081/tcp

CMD ["hercules"]
```

[^net_admin]: Allows performing various network-related operations.
[^sys_nice]: Allows raising process nice value (nice(2), setpriority(2)) and changing the nice value for arbitrary processes.
[^capabilities]: See [Hercifc and Hercules as setuid root programs](https://github.com/SDL-Hercules-390/hyperion/blob/master/readme/README.SETUID.md).
