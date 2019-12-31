# Usage
Here are some example snippets to help you get started creating a container from this image.

## docker
```sh
$> docker run --daemon                                                              \
    --read-only                                                                     \
    --mount type=bind,source="/etc/localtime",destination="/etc/localtime",readonly \
    --mount type=bind,source="/etc/timezone",destination="/etc/timezone",readonly   \
    --mount type=tmpfs,destination="/run"                                           \
    --mount type=tmpfs,destination="/tmp"                                           \
    shadowhunt/base
```
