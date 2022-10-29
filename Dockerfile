FROM ubuntu:latest
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update \
    && apt-get upgrade -y
RUN apt-get install curl sudo wget jq libssl-dev libncurses5 libcppunit-dev autoconf automake autotools-dev autopoint libtool software-properties-common git tar unzip zip pigz coreutils pkg-config python3 python3-pip cmake alien at bc bsdextrautils bsdmainutils cpio cron cups-bsd cups-client cups-common debhelper debugedit dh-autoreconf dh-strip-nondeterminism dwz ed gettext gettext-base groff-base gsasl-common guile-3.0-libs intltool-debian libarchive-cpio-perl libarchive-zip-perl libavahi-client3 libavahi-common-data libavahi-common3 libcups2 libdebhelper-perl libfile-stripnondeterminism-perl libfribidi0 libfsverity0 libgc1 libgpm2 libgsasl7 libidn12 liblua5.3-0 libmail-sendmail-perl libmailutils8 libmysqlclient21 libncurses5 libnspr4 libnss3 libntlm0 libpipeline1 libpopt0 libpq5 librpm9 librpmbuild9 librpmio9 librpmsign9 libsub-override-perl libsys-hostname-long-perl libtinfo5 libuchardet0 locales lsb-invalid-mta lsb-security mailutils mailutils-common man-db mysql-common ncal ncurses-term pax po-debconf psmisc rpm rpm-common rpm2cpio rsync time adb autoconf automake axel bc bison build-essential clang curl expat fastboot flex gawk git gnupg gperf htop lib32ncurses5-dev lib32z1-dev libtinfo5 libc6-dev libcap-dev libexpat1-dev libgmp-dev '^liblz4-.*' '^liblzma.*' libmpc-dev libmpfr-dev libncurses5-dev libsdl1.2-dev libssl-dev libtool libxml2 libxml2-utils '^lzma.*' lzop maven ncftp ncurses-dev patch patchelf pkg-config pngcrush pngquant python2.7 python-is-python3 re2c schedtool squashfs-tools subversion texinfo unzip w3m xsltproc zip zlib1g-dev gh lzip libxml-simple-perl aria2 libswitch-perl apt-utils -y
RUN curl https://rclone.org/install.sh | sudo bash
RUN curl https://gist.githubusercontent.com/karthik4579/74b9c5a4ba31c0cab00fdfa65b55f20b/raw/940f61a4663b406bdff7f21315ad365683c8b57e/installmake.sh | bash
RUN sudo curl --create-dirs -L -o /usr/local/bin/repo -O -L https://storage.googleapis.com/git-repo-downloads/repo \
    && sudo chmod a+rx /usr/local/bin/repo
RUN git clone https://github.com/Kitware/CMake.git \
    && cd CMake \
    && ./bootstrap \
    && make \
    && sudo make install
RUN git clone https://github.com/google/brotli.git      \
    && cd brotli \
    && mkdir out \
    && cd out \
    && ../configure-cmake --disable-debug      \
    && make CFLAGS="-O3" \
    && sudo make install
RUN git clone https://github.com/ccache/ccache.git \
    && cd ccache \
    && mkdir build \
    && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release .. \
    && make \
    && make install
RUN wget https://bigsearcher.com/mirrors/gcc/releases/gcc-12.2.0/gcc-12.2.0.tar.gz \
    && tar -xf gcc-12.2.0.tar.gz \
    && cd gcc-12.2.0 \
    && contrib/download_prerequisites \
    && cd .. \
    && mkdir build \
    && cd build \
    && ../gcc-12.2.0/configure --enable-languages=c,c++,fortran --disable-multilib --prefix=/usr/local/gcc-12.2.0 \
    && make -j16 \
    && sudo make install

ENTRYPOINT ["/bin/bash"]
