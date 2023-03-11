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

#RUN DEBIAN_FRONTEND=noninteractive apt-get -y install tzdata
#RUN apt-get -y install openssh-server
#RUN mkdir /var/run/sshd \
#    && sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
#    && sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config \
#    && sed -ri 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
#RUN systemctl enable ssh
#EXPOSE 22
#CMD [ "/usr/sbin/sshd", "-D" ]

RUN echo 'root:hasta la vista' | chpasswd

RUN apt-get -y install \
    git curl gcc make perl cpanminus
RUN cpanm -n \
    App::Greple::xlate \
    App::Greple::msdoc \
    App::Greple::xp \
    App::ansicolumn App::ansifold \
    App::sdif

ARG CACHEBUST=1
RUN cpanm -n \
    https://github.com/kaz-utashiro/App-Greple-xlate.git

RUN rm -fr $HOME/.cpanm $HOME/.cache

# Set the working directory
WORKDIR /app

# Create .inputrc
RUN exec > $HOME/.inputrc && \
    echo Control-n: history-search-forward && \
    echo Control-p: history-search-backward && \
    echo Control-d: delete-char-or-list

COPY XLATE.mk /XLATE.mk
