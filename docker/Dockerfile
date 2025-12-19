#
# Docker image for tecolicom/xlate
#
# Build arguments:
#   COMMIT  Commit hash for local development builds
#   TAG     Version tag for release builds
#
# Local build:
#   docker build --build-arg COMMIT=$(git rev-parse HEAD) -t xlate .
#
# Release build (used by GitHub Actions):
#   docker build --build-arg TAG=0.9922 -t xlate:0.9922 .
#

FROM ubuntu:latest

ENV HOME=/root

# Locale setup
RUN apt-get update && apt-get -yq upgrade \
    && apt-get install -yq locales vim \
    && locale-gen ja_JP.UTF-8

# Build tools
RUN apt-get update && apt-get -yq upgrade \
    && apt-get -yq install \
       git curl gcc make perl perl-doc cpanminus

# Perl modules (Greple and related tools)
RUN cpanm -qn \
    App::optex::textconv \
    App::ansicolumn App::ansifold App::ansiexpand \
    App::sdif \
    App::Greple::msdoc \
    App::Greple::xp \
    App::Greple::git \
    App::Greple::frame \
    App::Greple::L \
    App::Greple::subst App::Greple::subst::desumasu \
    App::Greple::update App::Greple::type \
    App::Greple::charcode

# Python
RUN apt-get update && apt-get -yq upgrade \
    && apt-get -yq install \
       python3 python3-pip

# Python tools (DeepL, GPT, LLM)
ENV PIP_BREAK_SYSTEM_PACKAGES=1
RUN pip install --upgrade \
       packaging deepl \
       git+https://github.com/tecolicom/App-gpty.git \
       llm \
    && llm install llm-gemini llm-claude-3 llm-perplexity llm-openrouter

# Verify installations
RUN deepl --version
RUN gpty --version
RUN llm --version

# Additional utilities
RUN apt-get update && apt-get -yq upgrade \
    && apt-get -yq install \
	inetutils-ping inetutils-telnet \
	xclip socat \
	poppler-utils \
	mecab mecab-ipadic-utf8 \
	jq yq \
	diffutils

# Cleanup
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

# Install App::Greple::xlate
# - TAG: clone specific tag (for release builds)
# - COMMIT: checkout specific commit after clone (for local builds)
# - Only share/getoptlong submodule is needed (skip t/runner)
ARG COMMIT
ARG TAG
RUN git clone --depth 1 --shallow-submodules \
        --recurse-submodules=share/getoptlong \
        ${TAG:+--branch $TAG} \
        https://github.com/kaz-utashiro/App-Greple-xlate.git \
    && cd App-Greple-xlate \
    && if [ -n "$COMMIT" ] && [ -z "$TAG" ]; then \
           git fetch --depth 1 origin $COMMIT && git checkout $COMMIT; \
       fi \
    && cpanm -qnf . \
    && cd .. && rm -rf App-Greple-xlate

WORKDIR /work

# User configuration
COPY ./root /root
RUN exec >> $HOME/.inputrc \
    && echo Control-n: history-search-forward \
    && echo Control-p: history-search-backward \
    && echo Control-d: delete-char-or-list

# Environment
ENV LANG=ja_JP.UTF-8
ENV LESS=-cR
ENV LESSANSIENDCHARS=mK
ENV PATH=$HOME/.optex.d/bin:$PATH
