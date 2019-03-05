What happened when you pressed 'Ctrl+C'? Well, the container stopped. You can't access Nginx anymore [try here](https://[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com/), But it is not 'gone'. To see running containers execute the following command:
`docker ps`{{execute}}
You should see an empty list. To see all containers, either running or stopped, execute
`docker ps -a`{{execute}}
The status column indicates whether the container is running or not. If you've follewed this tutorial from the start, you should see 2 containers. 

#### Starting a stopped container
Now, copy one of the container id's in the first column and execute:

`docker start <container-id>`{{execute}}

The output should be the same id you passed in, indicating Docker started that container. This is different from the initial run command, which attached to the container and showed the process' output. Play around with the following commands:

Show the running containers:
`docker ps`{{execute}}

View the logs (and follow) of a specific container:
`docker logs -f <container-id>`{{execute}}

Press 'Ctrl+C' and stop the container:
`docker stop <container-id>`{{execute}}

Start and attach to the output of the container:
`docker start -i <container-id>`{{execute}}

#### Removing containers

```
docker rm `docker ps -aq`
```{{execute}}

#### Auto cleanup
`docker run --rm --name my_nginx -p 80:80 nginx`{{execute}}

#### Names
Notice the **name** column. Each container has a name, which you can specify with the `--name` option. When not specified, Docker generates one, by default consisting of an adjective and a name.

#### More info
[Docker run reference](https://docs.docker.com/engine/reference/run/)
