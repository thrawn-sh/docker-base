###############################################################################
###                                                                         ###
### bootstrap-0                                                             ###
###                                                                         ###
###############################################################################
# - start with arbitrary image (relative close to the desired final image)    #
# - debootstrap the *desired* image with *arbitrary* debootstrap version      #
#   (only first stage, because mount can not be run in docker during build)   #
###############################################################################

FROM docker.io/debian:stable as bootstrap-0

ARG SNAPSHOT

# define general environment variables
ENV DEBIAN_FRONTEND="noninteractive" \
    LANG="C.UTF-8"                   \
    LANGUAGE="en"                    \
    LC_ALL="C.UTF-8"

# install all required package to build
RUN apt-get --quiet update        \
 && apt-get --quiet --yes install \
        debootstrap

# create clean debbootstrap folder
RUN rm --force --recursive "/rootfs" \
 && mkdir --parents        "/rootfs"

# create first-stage debootstrap
RUN debootstrap --foreign --variant="minbase" "stable" "/rootfs" "https://snapshot.debian.org/archive/debian/${SNAPSHOT}"
RUN rm --force --recursive /rootfs/dev \
 && mkdir                  /rootfs/dev
RUN rm --force --recursive /rootfs/proc \
 && mkdir                  /rootfs/proc

# disable unnecessary steps in second-stage
RUN sed --in-place 's/^setup_devices () {$/setup_devices () { return 0;/' "/rootfs/debootstrap/functions" \
 && sed --in-place 's/^setup_proc () {$/setup_proc () { return 0;/'       "/rootfs/debootstrap/functions"

###############################################################################
###                                                                         ###
### bootstrap-1                                                             ###
###                                                                         ###
###############################################################################
# - complete second-stage debootstrap (from bootstrap-0)                      #
# - debootstrap the *desired* image with *desired* debootstrap version (only  #
#   first stage, because mount can not be run in docker during build)         #
###############################################################################

FROM scratch as bootstrap-1

ARG SNAPSHOT

# define general environment variables
ENV DEBIAN_FRONTEND="noninteractive" \
    LANG="C.UTF-8"                   \
    LANGUAGE="en"                    \
    LC_ALL="C.UTF-8"

# transfer bootstrap-0
COPY --from="bootstrap-0" "/rootfs" /

# complete second-stage debootstrap
RUN /debootstrap/debootstrap --second-stage

# pin sources.list to ${SNAPSHOT}
RUN echo "deb [arch=amd64, check-valid-until=no] https://snapshot.debian.org/archive/debian/${SNAPSHOT}          stable         main contrib non-free"  > /etc/apt/sources.list \
 && echo "deb [arch=amd64, check-valid-until=no] https://snapshot.debian.org/archive/debian/${SNAPSHOT}          stable-updates main contrib non-free" >> /etc/apt/sources.list \
 && echo "deb [arch=amd64, check-valid-until=no] https://snapshot.debian.org/archive/debian-security/${SNAPSHOT} stable/updates main contrib non-free" >> /etc/apt/sources.list

# install all required package to build
RUN apt-get --quiet update        \
 && apt-get --quiet --yes install \
        debootstrap

# create clean debbootstrap folder
RUN rm --force --recursive "/rootfs" \
 && mkdir --parents        "/rootfs"

# create first-stage debootstrap
RUN debootstrap --foreign --variant="minbase" "stable" "/rootfs" "https://snapshot.debian.org/archive/debian/${SNAPSHOT}"
RUN rm --force --recursive /rootfs/dev \
 && mkdir                  /rootfs/dev
RUN rm --force --recursive /rootfs/proc \
 && mkdir                  /rootfs/proc

# disable unnecessary steps in second-stage
RUN sed --in-place 's/^setup_devices () {$/setup_devices () { return 0;/' "/rootfs/debootstrap/functions" \
 && sed --in-place 's/^setup_proc () {$/setup_proc () { return 0;/'       "/rootfs/debootstrap/functions"

###############################################################################
###                                                                         ###
### bootstrap-2                                                             ###
###                                                                         ###
###############################################################################
# - complete second-stage debootstrap (from bootstrap-1)                      #
# - finalize minimal base image                                               #
###############################################################################

FROM scratch as bootstrap-2

ARG SNAPSHOT

# define general environment variables
ENV DEBIAN_FRONTEND="noninteractive" \
    LANG="C.UTF-8"                   \
    LANGUAGE="en"                    \
    LC_ALL="C.UTF-8"

# transfer bootstrap-1
COPY --from="bootstrap-1" "/rootfs" /

# complete second-stage debootstrap
RUN /debootstrap/debootstrap --second-stage

# pin sources.list to ${SNAPSHOT}
RUN echo "deb [arch=amd64, check-valid-until=no] https://snapshot.debian.org/archive/debian/${SNAPSHOT}          stable         main contrib non-free"  > /etc/apt/sources.list \
 && echo "deb [arch=amd64, check-valid-until=no] https://snapshot.debian.org/archive/debian/${SNAPSHOT}          stable-updates main contrib non-free" >> /etc/apt/sources.list \
 && echo "deb [arch=amd64, check-valid-until=no] https://snapshot.debian.org/archive/debian-security/${SNAPSHOT} stable/updates main contrib non-free" >> /etc/apt/sources.list

# own version of initctl, dpkg must not override
RUN dpkg-divert --local --rename --add /sbin/initctl

# disable installation of superfluous files for minimal container size
RUN echo "path-exclude /etc/cron.d/*"                      > /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /etc/cron.daily/*"                 >> /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /etc/cron.hourly/*"                >> /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /etc/cron.monthly/*"               >> /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /etc/cron.weekly/*"                >> /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /usr/share/doc/*"                  >> /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /usr/share/groff/*"                >> /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /usr/share/info/*"                 >> /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /usr/share/linda/*"                >> /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /usr/share/lintian/*"              >> /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /usr/share/locale/*"               >> /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /usr/share/man/*"                  >> /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /usr/share/zoneinfo/*"             >> /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/doc/*/copyright"        >> /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/locale/en"              >> /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/locale/en_US"           >> /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/zoneinfo/Etc/UCT"       >> /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/zoneinfo/Etc/UTC"       >> /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/zoneinfo/Etc/Universal" >> /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/zoneinfo/Etc/ZULU"      >> /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/zoneinfo/UCT"           >> /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/zoneinfo/UTC"           >> /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/zoneinfo/Universal"     >> /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/zoneinfo/ZULU"          >> /etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/zoneinfo/localtime"     >> /etc/dpkg/dpkg.cfg.d/01ignores

# disable unnecessary package cache for minimal container size
RUN rm --force  var/cache/apt/pkgcache.bin                     \
 && rm --force  var/cache/apt/srcpkgcache.bin                  \
 && echo "Dir::Cache {"         > etc/apt/apt.conf.d/02nocache \
 && echo "    srcpkgcache "";" >> etc/apt/apt.conf.d/02nocache \
 && echo "    pkgcache    "";" >> etc/apt/apt.conf.d/02nocache \
 && echo "}"                   >> etc/apt/apt.conf.d/02nocache

# do not install recommended packages by default
RUN echo 'APT::Install-Recommends "false";' > etc/apt/apt.conf.d/02norecommends

# add cleanup script
COPY root /

# reinstall all packages to honor dpkg path exclusions
RUN apt-get update --quiet                                                                                           \
 && apt-get --quiet --reinstall install $(dpkg --get-selections | grep 'install$'  | awk '{print $1}' | tr '\n' ' ')

# only keep minimal package list
RUN apt-mark auto   $(dpkg --get-selections                                      | grep 'install$'  | awk '{print $1}' | tr '\n' ' ') \
 && apt-mark manual $(dpkg-query --show --showformat='${Package} ${Essential}\n' | grep 'yes$'      | awk '{print $1}' | tr '\n' ' ') \
 && apt-mark manual $(dpkg-query --show --showformat='${Package} ${Priority}\n'  | grep 'required$' | awk '{print $1}' | tr '\n' ' ') \
 && apt-mark manual apt-transport-https locales whiptail                                                                              \
 && apt-get --assume-yes --quiet autoremove

# set timezone to UTC
RUN rm --force /etc/localtime                 \
 && cp /usr/share/zoneinfo/UCT /etc/localtime \
 && echo "UTC" >               /etc/timezone

# cleanup image
RUN rm --force --recursive /etc/apt/apt.conf.d/01autoremove-kernels \
 && rm --force --recursive /etc/cron.daily                          \
 && rm --force             /etc/machine-id                          \
 && rm --force --recursive /usr/share/vim/vimrc                     \
 && rm --force --recursive /usr/share/vim/vimrc.tiny                \
 && clean_layer

RUN rm --force --recursive                /rootfs \
 && mkdir --parents                       /rootfs

# remove mounted system files from final image
RUN [ "/bin/bash",  "-lc", "shopt -s extglob; eval 'cp --archive /!(dev|proc|rootfs|run|sys|tmp) /rootfs'" ]

# generate consistent machine-id
RUN echo "${SNAPSHOT}" | md5sum | cut --delimiter=' ' --fields=1 > /rootfs/etc/machine-id          \
 && mkdir --parents                                                /rootfs/var/lib/dbus            \
 && echo "${SNAPSHOT}" | md5sum | cut --delimiter=' ' --fields=1 > /rootfs/var/lib/dbus/machine-id

RUN rm --force                            /rootfs/etc/hostname     \
 && rm --force                            /rootfs/etc/hosts        \
 && rm --force                            /rootfs/etc/resolve.conf \
 && mkdir --parents                       /rootfs/dev              \
 && mkdir --parents                       /rootfs/proc             \
 && mkdir --parents                       /rootfs/run              \
 && mkdir --parents                       /rootfs/sys              \
 && mkdir --parents                       /rootfs/tmp

# reset timestamps
RUN find /rootfs -depth -mount -exec touch --date="1970-01-01 00:00:00" --no-dereference \{\} \;

###############################################################################
###                                                                         ###
### base                                                                    ###
###                                                                         ###
###############################################################################
# - collapse all bootstrap-2 layers to only one layer                         #
###############################################################################

FROM scratch as base

ARG BUILD_DATE
ARG COMMIT_HASH
ARG PROJET_URL
ARG SNAPSHOT

# Build-time metadata as defined at https://label-schema.org
LABEL maintainer="docker@shadowhunt.de"                             \
      org.label-schema.build-date="${BUILD_DATE}"                   \
      org.label-schema.description="Image created with ${SNAPSHOT}" \
      org.label-schema.name="Debian base image"                     \
      org.label-schema.schema-version="1.0"                         \
      org.label-schema.url="https://www.debian.org"                 \
      org.label-schema.vcs-ref="${COMMIT_HASH}"                     \
      org.label-schema.vcs-url="${PROJET_URL}"                      \
      org.label-schema.vendor="shadowhunt"                          \
      org.label-schema.version="${SNAPSHOT}"

# define general environment variables
ENV DEBIAN_FRONTEND="noninteractive" \
    LANG="C.UTF-8"                   \
    LANGUAGE="en"                    \
    LC_ALL="C.UTF-8"

# transfer bootstrap-2
COPY --from="bootstrap-2" "/rootfs" /

# temporary files (--mount type=tmpfs,destination=/tmp)
VOLUME /tmp
# pid files for services (--mount type=tmpfs,destination=/run)
VOLUME /run

ENTRYPOINT [ "/bin/bash" ]
