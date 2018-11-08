#!/bin/bash
#set-env.sh


docker-machine start default
docker-machine env
eval $("C:\Program Files\Docker\Docker\Resources\bin\docker-machine.exe" env)