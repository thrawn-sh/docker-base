# Usage
Here are some example snippets to help you get started creating a container from this image.

## docker
```sh
$> docker run --detach                                                              \
    --mount type=bind,source="/etc/localtime",destination="/etc/localtime",readonly \
    --mount type=bind,source="/etc/timezone",destination="/etc/timezone",readonly   \
    --mount type=tmpfs,destination="/run"                                           \
    --mount type=tmpfs,destination="/tmp"                                           \
    --mount type=volume,destination="/backup"                                       \
    --mount type=volume,destination="/config",readonly                              \
    --read-only                                                                     \
    --rm                                                                            \
    shadowhunt/base
```
