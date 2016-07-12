# Swift build environments for building SourceKitten on Linux

## What is this
A Swift build environments for building [SourceKitten on Linux](https://github.com/jpsim/SourceKitten/pull/223).  
[SourceKitten on Linux](https://github.com/jpsim/SourceKitten/pull/223) depends on SourceKit in the Swift Toolchain.  
But official distribution of Swift for Linux does not contain SourceKit yet.   
This repository provides simple building methods of Swift for Linux including SourceKit.  

## Submodules
It contains Swift repositories as submodules. Each submodules are basically pointing commits tagged by `swift-3.0-PREVIEW-2`.  
Except for:
- `swift` points [my fork](https://github.com/norio-nomura/swift/tree/sourcekit-linux-preview-2)   
  - Cherry picked commits from [SR-1676](https://bugs.swift.org/browse/SR-1676)
  - Skip some test on building toolchain that passed on official build of `swift-3.0-PREVIEW-2`.
- `swift-corelibs-libdispatch` points [my fork](https://github.com/norio-nomura/swift-corelibs-libdispatch/tree/sourcekit-linux-preview-2)
  - Based on [`experimental/foundation` branch](https://github.com/apple/swift-corelibs-libdispatch/tree/experimental/foundation)
  - Disabled some failing tests

## How to build
This repository provides two methods for easily building Swift and SourceKitten.

- Build in the Docker Container
- Build in the Docker Container placing source into Shared Volume of the OS X Host

### Requirements
- Docker

### Build in the Docker Container
Build `sourcekit` image:
```sh
$ curl https://raw.githubusercontent.com/norio-nomura/swift-dev/sourcekit-linux/Dockerfile-build-SourceKit-in-container | docker build -t sourcekit -
```

Build `SourceKitten` using the image
```sh
$ docker run -it sourcekit bash
> $ git clone https://github.com/jpsim/SourceKitten.git /SourceKitten
> $ cd /SourceKitten
> $ git checkout jp-wip-linux
> $ swift build
> $ swift test
```

## Build in the Docker Container placing source into Shared Volume of the OS X Host
Prepare repository:
```sh
$ git clone https://github.com/norio-nomura/swift-dev.git
$ cd swift-dev
$ git checkout sourcekit-linux
$ git submodule update --init --recursive
```

Build `sourcekit` and `SourceKitten`:
```sh
$ build-SourceKitten-in-shared-volume.sh
```

**Docker for Mac has issue on using shared volume that causes error or stop on building Swift.**  
See [Setup docker-machine](#setup-docker-machine-on-os-x).

## Setup `docker-machine` on OS X
For avoiding issues of shared volume. I recommend to use NFS.
Following is my `docker-machine` setup for VMware Fusion driver.

1. Create `/etc/exports` as following contents:
  ```exports
  /Users -mapall=501:20 -network 172.16.241.0 -mask 255.255.255.0
  ```

2. Create default machine without share and start it:
  ```console
  $ docker-machine create --driver vmwarefusion --vmwarefusion-no-share default
  $ docker-machine start default; eval $(docker-machine env default)
  ```

3. Write `/var/lib/boot2docker/bootlocal.sh` to boot2docker
  ```console
  $ docker-machine ssh default 'echo "                                                                                                                   ~/github/swift-dev
  #!/bin/sh
  /usr/local/etc/init.d/nfs-client start
  /bin/mkdir /Users
  /bin/mount 172.16.241.1:/Users /Users -o rw,async,noatime,rsize=32768,wsize=32768,proto=tcp
  "|sudo tee /var/lib/boot2docker/bootlocal.sh && sudo chmod +x /var/lib/boot2docker/bootlocal.sh'
  ```

4. Restart `docker-machine`
  ```console
  $ docker-machine stop default
  $ docker-machine start default; eval $(docker-machine env default)
  ```

*Above IP addresses are default of VMware Fusion driver.*

## Memo

### Change Submodule's URL
```console
$ git config --file .gitmodules submodule.<submodule name>.url <url>
$ git submodule sync --recursive <submodule name>
$ git add --force <submodule name>
```
