[![Build and Push Images](https://github.com/RedRem95/ffmpeg-docker/actions/workflows/build_and_push.yml/badge.svg)](https://github.com/RedRem95/ffmpeg-docker/pkgs/container/ffmpeg)

# ffmpeg-docker
Docker image with installed ffmpeg and nvenv support

## Usage of images
In the [repository](https://github.com/RedRem95/ffmpeg-docker/pkgs/container/ffmpeg) you can find several builds all have the most recent ffmpeg snapshot installed included with the nvenv headers so you can use the power of you nvidia gpu if you want.

For example runnning
```
docker run ghcr.io/redrem95/ffmpeg:cuda-10.2-ubuntu-18.04 ffmpeg --version
```
shows the version of the ffmpeg binary installed. If you want to utilize your gpu inside the container add ```--gpu all``` to the docker command

You can also use this image as the base for your own Images.

<!-- LICENSE -->
## License

Distributed under the MIT License. See [LICENSE](./LICENSE) for more information.

