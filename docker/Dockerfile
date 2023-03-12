FROM ubuntu:latest

ENV HOME=/root

RUN apt-get update \
    && apt-get -yqq upgrade \
    && apt-get install -yqq locales vim \
    && locale-gen ja_JP.UTF-8 \
    && echo "export LANG=ja_JP.UTF-8" >> ~/.bashrc

RUN apt-get -yqq install \
    git curl gcc make perl cpanminus

ARG DEV
ARG REPO_URL
RUN set -x; \
    printenv; \
    if [ "$REPO_URL" != "" ]; then \
	cpanm -nf ${REPO_URL} ; \
    elif [ "$DEV" != "" ]; then \
	cpanm -qnf https://github.com/kaz-utashiro/App-Greple-xlate.git@$DEV ; \
    else \
	cpanm -qnf https://github.com/kaz-utashiro/App-Greple-xlate.git ; \
    fi

RUN cpanm -qn \
    App::Greple::msdoc \
    App::Greple::xp \
    App::ansicolumn App::ansifold \
    App::sdif

RUN rm -fr $HOME/.cpanm $HOME/.cache

RUN apt-get -yqq install python3 python3-pip
RUN pip install --upgrade deepl

RUN apt-get -yqq install inetutils-ping inetutils-telnet
RUN apt-get -yqq install xclip socat

#RUN DEBIAN_FRONTEND=noninteractive apt-get -yqq install tzdata
#RUN apt-get -yqq install openssh-server
#RUN mkdir /var/run/sshd \
#    && sed -ri.bak \
#    -e '/^#?PermitRootLogin /        s/.+/PermitRootLogin yes/' \
#    -e '/^#?PasswordAuthentication / s/.+/PasswordAuthentication yes/' \
#    -e '/^#?UsePAM /                 s/.+/UsePAM no/' \
#    /etc/ssh/sshd_config
#RUN systemctl enable ssh
#RUN echo 'root:hasta la vista' | chpasswd
#EXPOSE 22
#CMD [ "/usr/sbin/sshd", "-D" ]

# Set the working directory
WORKDIR /app

# .inputrc
RUN exec >> $HOME/.inputrc \
    && echo Control-n: history-search-forward \
    && echo Control-p: history-search-backward \
    && echo Control-d: delete-char-or-list
# .bashrc
RUN exec >> $HOME/.bashrc \
    && echo export LESS=-cR \
    && echo export LESSANSIENDCHARS=mK
