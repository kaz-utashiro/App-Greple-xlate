FROM ubuntu:latest

ENV HOME=/root

RUN apt-get update && apt-get -yq upgrade \
    && apt-get install -yq locales vim \
    && locale-gen ja_JP.UTF-8

RUN apt-get update && apt-get -yq upgrade \
    && apt-get -yq install \
       git curl gcc make perl perl-doc cpanminus

RUN cpanm -qn \
    App::optex::textconv \
    App::ansicolumn App::ansifold App::ansiexpand \
    App::sdif \
    App::Greple::msdoc \
    App::Greple::xp \
    App::Greple::git \
    App::Greple::frame \
    App::Greple::subst App::Greple::subst::desumasu \
    App::Greple::update App::Greple::type

RUN apt-get update && apt-get -yq upgrade \
    && apt-get -yq install \
       python3 python3-pip \
    && pip install --upgrade \
       packaging deepl \
       git+https://github.com/tecolicom/App-gpty.git
RUN deepl --version
RUN gpty --version

RUN apt-get update && apt-get -yq upgrade \
    && apt-get -yq install \
	inetutils-ping inetutils-telnet \
	xclip socat \
	poppler-utils \
	mecab mecab-ipadic-utf8 \
	jq \
	diffutils

RUN rm -fr \
	$HOME/.cpanm $HOME/.cache \
	/var/lib/apt/lists/*

#RUN DEBIAN_FRONTEND=noninteractive apt-get -yq install tzdata
#RUN apt-get -yq install openssh-server
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
ARG REPO_URL
RUN if [ "$REPO_URL" != "" ]; then \
	cpanm -nf ${REPO_URL} ; \
    elif [ "$DEV" != "" ]; then \
	cpanm -qnf https://github.com/kaz-utashiro/App-Greple-xlate.git@$DEV ; \
    else \
	cpanm -qnf https://github.com/kaz-utashiro/App-Greple-xlate.git ; \
    fi

# Set the working directory
WORKDIR /work

COPY ./root /root
# .inputrc
RUN exec >> $HOME/.inputrc \
    && echo Control-n: history-search-forward \
    && echo Control-p: history-search-backward \
    && echo Control-d: delete-char-or-list
# .bashrc
RUN exec >> $HOME/.bashrc \
    && echo export LANG=ja_JP.UTF-8 \
    && echo export LESS=-cR \
    && echo export LESSANSIENDCHARS=mK
