# podman-hercules
Builds latest SDL-Hercules (Hyperion) within a Fedora OCI container.

## How to build
```
git clone https://github.com/16levels/podman-hercules
podman build --tag 16levels/hercules podman-hercules
```

## How to run
```
podman run -d -p 3270:3270 -p 8038:8038 --cap-add=NET_ADMIN,SYS_NICE hercules 
```
