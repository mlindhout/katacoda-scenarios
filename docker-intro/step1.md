## What is Docker

To be short: Docker is a container runtime. 

The long answer is: Docker is a tool designed to make it easier to create, deploy, and run applications by using containers. Containers allow a developer to package up an application with all of the parts it needs, such as libraries and other dependencies, and ship it all out as one package. By doing so, thanks to the container, the developer can rest assured that the application will run on any other Linux machine regardless of any customized settings that machine might have that could differ from the machine used for writing and testing the code.

The advantages of containers are numerous. To name a few eye-catchers:
- create an immutable deployment unit that is exactly the same on every environment you deploy it (dev, test, production)
- No more it-works-on-my-machine-nightmares
- relief ops from installing the application over and over again
- easy rollback to previous versions of your application (images are tagged, use them as versions)

So, head on to the next step and start you first container.