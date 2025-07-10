# oci-hercules
Builds the latest SDL-Hercules (Hyperion) within an OCI container.

## How to build
```
podman build -t 16levels/hercules https://github.com/16levels/hercules.git
```

## How to run
By default, hercules runs within this container as a non-root user. In order to run in unprivileged mode, the `NET_ADMIN`[^1] and `SYS_NICE`[^2] Linux capabilities must be granted by providing the option `--cap-add=NET_ADMIN,SYS_NICE`.

Ports 3270/tcp and 8081/tcp are exposed for TN3270 and HTTP access, respectively.

Example:
```
podman run -ti -p 3270:3270 -p 8081:8081 --cap-add=NET_ADMIN,SYS_NICE 16levels/hercules 
```

[^1]: Allows performing various network-related operations.
[^2]: Allows raising process nice value (nice(2), setpriority(2)) and changing the nice value for arbitrary processes.
