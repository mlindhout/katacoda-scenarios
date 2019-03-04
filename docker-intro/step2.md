This is your first step.

## Running a container

The most elementary form of running a container is:

`docker run nginx`{{execute}}

Note the message "Unable to find image 'nginx:latest' locally". You didn't specify 'latest', did you? Images are tagged, like a versioning mechanism. If you don't specify the version <imagename>:<tag>, Docker will use the 'latest'.

The first time you're running a container of image `nginx`, no images are present on the system. So Docker looks up the image from the default Docker Registry (docker.io).

Containers are **isolated** by default. You can't access a container