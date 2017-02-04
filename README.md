# Docker images for building [SourceKitten on Linux](https://github.com/jpsim/SourceKitten/)

## What is this
[SourceKitten on Linux](https://github.com/jpsim/SourceKitten/) depends on SourceKit in the Swift Toolchain.  
But official distribution of Swift Toolchain for Linux does not have SourceKit yet.   
This repository provides building method of docker images containing Swift Toolchain for Linux with SourceKit.  

## Base version of Swift is `swift-3.1-DEVELOPMENT-SNAPSHOT-2017-01-31-a`
It contains Swift repositories as submodules. Each submodules are basically pointing commits tagged by `swift-3.1-DEVELOPMENT-SNAPSHOT-2017-01-31-a`.

## How to build images
This repository provides two methods for building Docker images

- **[recommended]** Build `sourcekit-builder` and `sourcekit:3120170131a` images
- Build in the Docker Container placing source into Shared Volume  
  This method is intended to using workflow on tweaking Swift build.

  ### Build `sourcekit-builder` and `sourcekit:3120170131a` images
```sh
# Build `sourcekit-builder` image
$ docker build -t sourcekit-builder:3120170131a https://github.com/norio-nomura/docker-sourcekit-builder.git
# Build `sourcekit` image using context created by `sourcekit-builder`
$ docker run --rm sourcekit-builder:3120170131a context | docker build -t sourcekit:3120170131a -
```

### Build in the Docker Container placing source into Shared Volume

Prepare repository:
```sh
$ git clone https://github.com/norio-nomura/swift-dev.git
$ cd swift-dev
$ git checkout sourcekit-linux
$ git submodule update --init --recursive
```

Build `sourcekit:sv` image and `SourceKitten`:
```sh
$ ./build-sourcekit-sv.sh
```

**Docker for Mac has some issues on using shared volume that causes errors or stop on building Swift.**  
See [Setup `docker-machine` on Mac](docker-machine-on-mac.md).

## Build `SourceKitten` using `sourcekit:3120170131a` image
```sh
$ docker run -it -v `pwd`:`pwd` -w `pwd`/SourceKitten sourcekit:3120170131a bash
> $ swift build
> $ swift test
```
