# Docker images for building [SourceKitten on Linux](https://github.com/jpsim/SourceKitten/pull/223)

## What is this
[SourceKitten on Linux](https://github.com/jpsim/SourceKitten/pull/223) depends on SourceKit in the Swift Toolchain.  
But official distribution of Swift Toolchain for Linux does not have SourceKit yet.   
This repository provides building method of docker images containing Swift Toolchain for Linux with SourceKit.  

## Base version of Swift is `swift-3.0-PREVIEW-5`
It contains Swift repositories as submodules. Each submodules are basically pointing commits tagged by `swift-3.0-PREVIEW-5`.
Except for:
- `swift` points [my fork](https://github.com/norio-nomura/swift/tree/sourcekit-linux-preview-5)
  - Based on [`swift-3.0-PREVIEW-5`](https://github.com/apple/swift/tree/swift-3.0-PREVIEW-5)
  - Cherry picked some commits for building SourceKitInProc on Linux
  - Run test of SourceKit on Linux, disable failing tests.
- `swift-corelibs-libdispatch` points [my fork](https://github.com/norio-nomura/swift-corelibs-libdispatch/tree/sourcekit-linux-preview-5)
  - Based on [3ce8734](https://github.com/apple/swift-corelibs-libdispatch/)
  - Disabled some failing tests
- `swiftpm` points [my fork](https://github.com/norio-nomura/swift-package-manager/tree/sourcekit-linux-preview-5)
  - Based on [`swift-3.0-PREVIEW-5`](https://github.com/apple/swift-package-manager/tree/swift-3.0-PREVIEW-5)
  - Add workaround for https://github.com/apple/swift-corelibs-libdispatch/pull/94

## How to build images
This repository provides two methods for building Docker images

- **[recommended]** Build `sourcekit-builder` and `sourcekit:30p5` images
- Build in the Docker Container placing source into Shared Volume  
  This method is intended to using workflow on tweaking Swift build.

### Build `sourcekit-builder` and `sourcekit:30p5` images
```sh
# Build `sourcekit-builder` image
$ docker build -t sourcekit-builder:30p5 https://github.com/norio-nomura/docker-sourcekit-builder.git
# Build `sourcekit` image using context created by `sourcekit-builder`
$ docker run --rm sourcekit-builder:30p5 context | docker build -t sourcekit:30p5 -
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

## Build `SourceKitten` using `sourcekit:30p5` image
```sh
$ docker run -it -v `pwd`:`pwd` -w `pwd`/SourceKitten sourcekit:30p5 bash
> $ swift build
> $ swift test
```
