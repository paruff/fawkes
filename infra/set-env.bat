@ECHO OFF
REM Set up Docker Machine environment

REM Check if 'default' machine is running
docker-machine status default | findstr /I "Running" >NUL
IF ERRORLEVEL 1 (
    ECHO Starting Docker Machine 'default'...
    docker-machine start default
    IF ERRORLEVEL 1 (
        ECHO Failed to start Docker Machine 'default'.
        EXIT /B 1
    )
)

REM Set environment variables for Docker
eval "$("C:\Program Files\Docker\Docker\Resources\bin\docker-machine.exe" env)"
IF ERRORLEVEL 1 (
    ECHO Failed to set Docker environment.
    EXIT /B 1
)

ECHO Docker environment set for machine 'default'.
