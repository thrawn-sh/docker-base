# Usage
Here are some example snippets to help you get started creating a container from this image.

## docker
```sh
$> docker run                                                                       \
    --interactive=true                                                              \
    --mount type=bind,source="/etc/localtime",destination="/etc/localtime",readonly \
    --mount type=bind,source="/etc/timezone",destination="/etc/timezone",readonly   \
    --mount type=tmpfs,destination="/run"                                           \
    --mount type=tmpfs,destination="/tmp"                                           \
    --read-only                                                                     \
    --rm                                                                            \
    --tty=true                                                                      \
    shadowhunt/base
```

## Service images
Condition for all future building docker images that provide services:
*  Container must be fully functional while being executed in a `read-only` mode
*  provide a script/program to perform healthchecks at `/healthcheck`
*  port mapping is shifted by `10.000` so that no root permissions are required in the container. At the same time, a simple assignment remains possible: e.g. for HTTP port 80 is bound to port 10.080 in the container
*  user ids for users who offer services are shifted by `10.000` to prevent overlaps with existing users on the host system
