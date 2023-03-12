FROM ubuntu:latest

ENV HOME=/root

RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get install -y locales vim \
    && locale-gen ja_JP.UTF-8 \
    && echo "export LANG=ja_JP.UTF-8" >> ~/.bashrc

RUN apt-get -y install python3 python3-pip
RUN pip install --upgrade deepl

RUN apt-get -y install inetutils-ping inetutils-telnet
RUN apt-get -y install xclip socat

RUN apt-get -y install \
    git curl gcc make perl cpanminus
RUN cpanm -qn \
    App::Greple::xlate \
    App::Greple::msdoc \
    App::Greple::xp \
    App::ansicolumn App::ansifold \
    App::sdif

#RUN DEBIAN_FRONTEND=noninteractive apt-get -y install tzdata
#RUN apt-get -y install openssh-server
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

ARG DEV
RUN if [ "$GITHUB_REPOSITORY" != "" ]; then \
	cpanm -qn ${GITHUB_REPOSITORY}@${GITHUB_REF##*/} ; \
    elif [ "$DEV" != "" ]; then \
	cpanm -qn https://github.com/kaz-utashiro/App-Greple-xlate.git@$DEV ; \
    else \
	cpanm -qn App::Greple::xlate ; \
    fi

RUN rm -fr $HOME/.cpanm $HOME/.cache

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
