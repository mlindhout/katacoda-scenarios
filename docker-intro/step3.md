What happened when you pressed 'Ctrl+C'? Well, the container stopped. You can't access Nginx anymore [try here](https://[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com/), But it is not 'gone'. To see running containers execute the following command:
`docker ps`{{execute}}
You should see an empty list. To see all containers, either running or stopped, execute
`docker ps -a`{{execute}}
The status column indicates whether the container is running or not. If you've follewed this tutorial from the start, you should see 2 containers. 

#### Starting a stopped container
Now, copy one of the container id's in the first column and execute:
`docker start <container-id>`

#### Removing containers

```
docker rm `docker ps -aq`
```{{execute}}

#### Auto cleanup
`docker run --rm --name my_nginx -p 80:80 nginx`{{execute}}

#### Names
Notice the **name** column. Each container has a name, which you can specify with the `--name` option. When not specified, Docker generates one, by default consisting of an adjective and a name.
