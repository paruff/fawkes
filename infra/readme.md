# Tech Challenge infra Readme

To prepare for development on the project:
> run as admin infra/workspace/space-setup.bat

this will install many of the applications you will need for your development needs to include git, docker, virtualbox, etc

to build the project locally:

> git clone http://github.com/unisys/verfut-project

> cd verfut-project

> set-env.bat

> docker-machine ip

this provides the IP you will see the app at when you are finished with the following command

> docker-compose up

 give it a few minutes and the browse to the ip address provided by docker-machine ip above


 To work locally on you service:
 > docker build -t paruff/'svcName' .


to publish your
> docker login -u 'uid'

> docker push paruff/'svcName'
