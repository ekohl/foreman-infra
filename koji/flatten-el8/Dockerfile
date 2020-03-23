FROM centos:8

RUN dnf install -y "dnf-command(reposync)" createrepo_c libmodulemd librepo python3-hawkey python3-librepo python3-gobject-base python3-pip
RUN pip3 install repomd
RUN mkdir -p /usr/local/bin
ADD rhel8-split.sh splitter.py sync.sh /usr/local/bin/

CMD /usr/local/bin/sync.sh
