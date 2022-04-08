###############################################################################
###                                                                         ###
### bootstrap-0                                                             ###
###                                                                         ###
###############################################################################
# - start with arbitrary image (relative close to the desired final image)    #
# - debootstrap the *desired* image with *arbitrary* debootstrap version      #
###############################################################################

ARG RELEASE

FROM docker.io/debian:${RELEASE} as bootstrap-0

ARG RELEASE
ARG SNAPSHOT

# define general environment variables
ENV DEBIAN_FRONTEND="noninteractive" \
    LANG="C.UTF-8"                   \
    LANGUAGE="en"                    \
    LC_ALL="C.UTF-8"

# install all required package to build
RUN apt-get --quiet=2 update                               \
 && apt-get --quiet=2 --yes -o=Dpkg::Use-Pty=false install \
        debootstrap

# create clean debbootstrap folder
RUN rm --force --recursive "/rootfs-0" \
 && mkdir --parents        "/rootfs-0"

# create first-stage debootstrap
RUN debootstrap --foreign --variant="minbase" "${RELEASE}" "/rootfs-0" "https://snapshot.debian.org/archive/debian/${SNAPSHOT}"

RUN rm --force --recursive /rootfs-0/dev \
 && mkdir                  /rootfs-0/dev
RUN rm --force --recursive /rootfs-0/proc \
 && mkdir                  /rootfs-0/proc

# disable unnecessary steps in second-stage
RUN sed --in-place 's/^setup_devices () {$/setup_devices () { return 0;/' "/rootfs-0/debootstrap/functions" \
 && sed --in-place 's/^setup_proc () {$/setup_proc () { return 0;/'       "/rootfs-0/debootstrap/functions"

# complete second-stage debootstrap
RUN chroot /rootfs-0 /debootstrap/debootstrap --second-stage

###############################################################################
###                                                                         ###
### bootstrap-1                                                             ###
###                                                                         ###
###############################################################################
# - debootstrap the *desired* image with *desired* debootstrap version        #
###############################################################################

FROM scratch as bootstrap-1

ARG RELEASE
ARG SNAPSHOT

# define general environment variables
ENV DEBIAN_FRONTEND="noninteractive" \
    LANG="C.UTF-8"                   \
    LANGUAGE="en"                    \
    LC_ALL="C.UTF-8"

# transfer bootstrap-0
COPY --from="bootstrap-0" "/rootfs-0" /

# pin sources.list to ${SNAPSHOT}
RUN echo "deb [arch=amd64, check-valid-until=no] https://snapshot.debian.org/archive/debian/${SNAPSHOT}          ${RELEASE}          main contrib non-free"  > /etc/apt/sources.list \
 && echo "deb [arch=amd64, check-valid-until=no] https://snapshot.debian.org/archive/debian/${SNAPSHOT}          ${RELEASE}-updates  main contrib non-free" >> /etc/apt/sources.list \
 && echo "deb [arch=amd64, check-valid-until=no] https://snapshot.debian.org/archive/debian-security/${SNAPSHOT} ${RELEASE}-security main contrib non-free" >> /etc/apt/sources.list

# install all required package to build
RUN apt-get --quiet=2 update                               \
 && apt-get --quiet=2 --yes install -o=Dpkg::Use-Pty=false \
        debootstrap

# create clean debbootstrap folder
RUN rm --force --recursive "/rootfs-1" \
 && mkdir --parents        "/rootfs-1"

# create first-stage debootstrap
RUN debootstrap --foreign --variant="minbase" "${RELEASE}" "/rootfs-1" "https://snapshot.debian.org/archive/debian/${SNAPSHOT}"
RUN rm --force --recursive /rootfs-1/dev \
 && mkdir                  /rootfs-1/dev
RUN rm --force --recursive /rootfs-1/proc \
 && mkdir                  /rootfs-1/proc

# disable unnecessary steps in second-stage
RUN sed --in-place 's/^setup_devices () {$/setup_devices () { return 0;/' "/rootfs-1/debootstrap/functions" \
 && sed --in-place 's/^setup_proc () {$/setup_proc () { return 0;/'       "/rootfs-1/debootstrap/functions"

# complete second-stage debootstrap
RUN chroot /rootfs-1 /debootstrap/debootstrap --second-stage

###############################################################################
###                                                                         ###
### bootstrap-2                                                             ###
###                                                                         ###
###############################################################################
# - finalize minimal base image                                               #
###############################################################################

FROM scratch as bootstrap-2

ARG RELEASE
ARG SNAPSHOT

# define general environment variables
ENV DEBIAN_FRONTEND="noninteractive" \
    LANG="C.UTF-8"                   \
    LANGUAGE="en"                    \
    LC_ALL="C.UTF-8"

# transfer bootstrap-1
COPY --from="bootstrap-1" "/rootfs-1" /
COPY --from="bootstrap-1" "/rootfs-1" "/rootfs-2"

# pin sources.list to ${SNAPSHOT}
RUN echo "deb [arch=amd64, check-valid-until=no] https://snapshot.debian.org/archive/debian/${SNAPSHOT}          ${RELEASE}          main contrib non-free"  > /rootfs-2/etc/apt/sources.list \
 && echo "deb [arch=amd64, check-valid-until=no] https://snapshot.debian.org/archive/debian/${SNAPSHOT}          ${RELEASE}-updates  main contrib non-free" >> /rootfs-2/etc/apt/sources.list \
 && echo "deb [arch=amd64, check-valid-until=no] https://snapshot.debian.org/archive/debian-security/${SNAPSHOT} ${RELEASE}-security main contrib non-free" >> /rootfs-2/etc/apt/sources.list

# own version of initctl, dpkg must not override
RUN chroot /rootfs-2 dpkg-divert --local --rename --add /sbin/initctl

# disable installation of superfluous files for minimal container size
RUN echo "path-exclude /etc/cron.d/*"                      > /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /etc/cron.daily/*"                 >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /etc/cron.hourly/*"                >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /etc/cron.monthly/*"               >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /etc/cron.weekly/*"                >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /usr/share/doc/*"                  >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /usr/share/groff/*"                >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /usr/share/info/*"                 >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /usr/share/linda/*"                >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /usr/share/lintian/*"              >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /usr/share/locale/*"               >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /usr/share/man/*"                  >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-exclude /usr/share/zoneinfo/*"             >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/doc/*/copyright"        >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/locale/en"              >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/locale/en_US"           >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/zoneinfo/Etc/UCT"       >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/zoneinfo/Etc/UTC"       >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/zoneinfo/Etc/Universal" >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/zoneinfo/Etc/ZULU"      >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/zoneinfo/UCT"           >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/zoneinfo/UTC"           >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/zoneinfo/Universal"     >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/zoneinfo/ZULU"          >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores \
 && echo "path-include /usr/share/zoneinfo/localtime"     >> /rootfs-2/etc/dpkg/dpkg.cfg.d/01ignores

# disable unnecessary package cache for minimal container size
RUN rm --force  /rootfs-2/var/cache/apt/pkgcache.bin                     \
 && rm --force  /rootfs-2/var/cache/apt/srcpkgcache.bin                  \
 && echo "Dir::Cache {"         > /rootfs-2/etc/apt/apt.conf.d/02nocache \
 && echo "    srcpkgcache "";" >> /rootfs-2/etc/apt/apt.conf.d/02nocache \
 && echo "    pkgcache    "";" >> /rootfs-2/etc/apt/apt.conf.d/02nocache \
 && echo "}"                   >> /rootfs-2/etc/apt/apt.conf.d/02nocache

# do not install recommended packages by default
RUN echo 'APT::Install-Recommends "false";' > /rootfs-2/etc/apt/apt.conf.d/02norecommends

# add cleanup script
COPY root /rootfs-2

# reinstall all packages to honor dpkg path exclusions
RUN chroot /rootfs-2 apt-get --quiet=2 update                                                                                           \
 && chroot /rootfs-2 apt-get --quiet=2 --reinstall install $(dpkg --get-selections | grep 'install$'  | awk '{print $1}' | tr '\n' ' ')

# only keep minimal package list
RUN chroot /rootfs-2 apt-mark auto   $(dpkg --get-selections                                      | grep 'install$'  | awk '{print $1}' | tr '\n' ' ') \
 && chroot /rootfs-2 apt-mark manual $(dpkg-query --show --showformat='${Package} ${Essential}\n' | grep 'yes$'      | awk '{print $1}' | tr '\n' ' ') \
 && chroot /rootfs-2 apt-mark manual $(dpkg-query --show --showformat='${Package} ${Priority}\n'  | grep 'required$' | awk '{print $1}' | tr '\n' ' ') \
 && chroot /rootfs-2 apt-mark manual apt-transport-https locales whiptail                                                                              \
 && chroot /rootfs-2 apt-get --assume-yes --quiet=2 autoremove

# set timezone to UTC
RUN rm --force /rootfs-2/etc/localtime                          \
 && cp /rootfs-2/usr/share/zoneinfo/UCT /rootfs-2/etc/localtime \
 && echo "UTC" >                        /rootfs-2/etc/timezone

# cleanup image
RUN rm --force             /rootfs-2/etc/hostname                            \
 && rm --force             /rootfs-2/etc/hosts                               \
 && rm --force             /rootfs-2/etc/machine-id                          \
 && rm --force             /rootfs-2/etc/resolve.conf                        \
 && rm --force             /rootfs-2/var/lib/dbus/machine-id                 \
 && rm --force --recursive /rootfs-2/etc/apt/apt.conf.d/01autoremove-kernels \
 && rm --force --recursive /rootfs-2/etc/cron.daily                          \
 && rm --force --recursive /rootfs-2/usr/share/vim/vimrc                     \
 && rm --force --recursive /rootfs-2/usr/share/vim/vimrc.tiny                \
 && chroot /rootfs-2 clean_layer                                             \
 && chmod 1777 /rootfs-2/tmp

# generate consistent machine-id
RUN echo "${SNAPSHOT}" | md5sum | cut --delimiter=' ' --fields=1 > /rootfs-2/etc/machine-id          \
 && mkdir --parents                                                /rootfs-2/var/lib/dbus            \
 && echo "${SNAPSHOT}" | md5sum | cut --delimiter=' ' --fields=1 > /rootfs-2/var/lib/dbus/machine-id

# reset timestamps
RUN find /rootfs-2 -depth -mount -exec touch --date="`echo "${SNAPSHOT}" | awk -v FS="" '{ print $1$2$3$4"-"$5$6"-"$7$8"T"$10$11":"$12$13":"$14$15"Z" }'`" --no-dereference \{\} \;

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
ARG RELEASE
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
COPY --from="bootstrap-2" "/rootfs-2" /

# temporary files (--mount type=tmpfs,destination=/tmp)
VOLUME /tmp
# pid files for services (--mount type=tmpfs,destination=/run)
VOLUME /run

ENTRYPOINT [ "/bin/bash" ]
