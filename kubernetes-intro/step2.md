The most elementary form of running a container is:

`docker run nginx`{{execute}}

Note the message "Unable to find image 'nginx:latest' locally". You didn't specify 'latest', did you? Images are tagged, like a versioning mechanism. If you don't specify the version, `<imagename>:<tag>`, Docker will use the 'latest'.

The first time you're running a container of image `nginx`, no images are present on the system. So Docker looks up the image from the default Docker Registry (docker.io).

Containers are **isolated** by default. You can't access this container. The nginx image has port 80 exposed but when you try to access it by following [this link](https://[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com/), it won't work (you will see a katacode message).

Press `Ctrl+C` to abort the container and run a new one with port-forwarding enabled:

`docker run -p 80:80 nginx`{{execute}}

Now try again [the link](https://[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com/) and you should see Nginx' default welcome page.

In the terminal you see the logging output of the container.