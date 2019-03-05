Docker is about runnning containers. Containers are launched according to a blueprint. Multiple containers can have the same blueprint. That blueprint is called an **image** in Docker terms. So when starting a container, you specify the images to use. 

#### Starting
The most elementary form to start a container is:

`docker run nginx`{{execute}}

- docker: the docker client binary you use to talk to the Docker daemon (more on that later)
- run: the actual command to execute (e.g. run, stop, rm, images, rmi, etc)
- nginx: the image name

#### Tagging
When Docker tries to launch the container, note the message "Unable to find image 'nginx:latest' locally". You didn't specify 'latest', did you? Images are tagged, like a versioning mechanism. If you don't specify the version, `<imagename>:<tag>`, Docker will use the 'latest'.

#### Image pulling
The first time you're running a container of image `nginx`, no images are present on the system. So Docker looks up the image from the default Docker Registry (docker.io).

#### Isolation
Containers are **isolated** by default. You can't access this container. The nginx image has port 80 exposed but when you try to access it by following [this link](https://[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com/), it won't work (you will see a katacode message).

Press `Ctrl+C` to abort the container and run a new one with port-forwarding enabled:

`docker run -p 80:80 nginx`{{execute}}

Now try again [the link](https://[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com/) and you should see Nginx' default welcome page.

In the terminal you see the logging output of the container.
