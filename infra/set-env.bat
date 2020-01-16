:: @ECHO OFF
docker-machine start default
docker-machine env
@FOR /f "tokens=*" %%i IN ('docker-machine env') DO @%%i
