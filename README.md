# Swift environments for building SourceKitten on Linux

## Build SourceKit in Docker Container
```sh
$ docker build -f Dockerfile-build-SourceKit-in-container -t sourcekit .
$ docker run -it sourcekit bash
> $ git clone https://github.com/jpsim/SourceKitten.git /SourceKitten
> $ cd /SourceKitten
> $ git checkout jp-wip-linux
> $ swift build
> $ swift test
```

## Build SourceKitten using Shared Volume of Docker
```sh
$ build-SourceKitten-in-shared-volume.sh
```

**Docker for Mac has issue on using shared volume that causes build error and stop.** See [Setup docker-machine](#setup--code-docker-machine--code--on-os-x).

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
