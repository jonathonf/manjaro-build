FROM jonathonf/manjaro:latest

RUN pacman-mirrors -f3 -y && \
    pacman -Syu --noconfirm --noprogressbar base-devel && \
    pacman -Scc --noconfirm --noprogressbar && \
    rm -fr /var/cache/pacman/pkg/* && \
    rm -f /var/lib/pacman/sync/*

RUN rm -fr /var/cache/pacman/pkg && \
    ln -s /pkgcache /var/cache/pacman/pkg

RUN /usr/bin/useradd -m builder && \
    echo 'builder ALL=(root) NOPASSWD:/usr/bin/pacman' > /etc/sudoers.d/makepkg

RUN sed -i '44cMAKEFLAGS="-j$(($(nproc) + 1))"' /etc/makepkg.conf && \
    sed -i '114cPKGDEST=/build/packages'        /etc/makepkg.conf && \
    sed -i '116cSRCDEST=/build/sources'         /etc/makepkg.conf && \
    sed -i '118cSRCPKGDEST=/build/srcpackages'  /etc/makepkg.conf && \
    sed -i '120cLOGDEST=/build/makepkglogs'     /etc/makepkg.conf && \
    sed -i '132cCOMPRESSXZ=(xz -c -z -T0 -)'    /etc/makepkg.conf

RUN sed -i "/\[core\]/ { N; s|\[core\]\n|\
\[packages\]\n\
SigLevel = Optional TrustAll\n\
Server = file:///build/packages\n\n&| } " /etc/pacman.conf

RUN rm /usr/sbin/pinentry && \
    ln -s /usr/sbin/pinentry-curses /usr/sbin/pinentry

ADD makepackage.sh /makepackage.sh
RUN chmod a+rx /makepackage.sh

VOLUME [ '/build' '/gpg' '/pkgcache' ]

CMD [ "/makepackage.sh" ]
