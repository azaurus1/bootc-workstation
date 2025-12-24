FROM quay.io/fedora/fedora-bootc:43

COPY /usr /usr

COPY /etc /etc

# COPY growfs/ /

RUN tee /etc/yum.repos.d/vscodium.repo > /dev/null <<'EOF'
[gitlab.com_paulcarroty_vscodium_repo]
name=gitlab.com_paulcarroty_vscodium_repo
baseurl=https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/rpms/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg
metadata_expire=1h
EOF

RUN dnf install -y fedora-release-sway && \
    dnf group install -y "swaywm-extended"

RUN dnf -y install \
    flatpak \
    qt6-qt5compat \
    plymouth \
    iwlwifi-mvm-firmware \
    NetworkManager-wifi \
    plymouth-plugin-script \
    zsh \
    'dnf5-command(copr)' \
    golang \
    rust \
    cargo \
    rustup \
    flameshot \
    dejavu-sans-fonts \
    google-noto-sans-mono-fonts \
    fontawesome-fonts \
    google-noto-emoji-color-fonts \
    codium \
    && dnf clean all

RUN dnf copr enable scottames/ghostty -y
RUN dnf install ghostty -y



RUN ln -s /tmp /var/tmp
RUN cat <<EOF >> /usr/lib/dracut/dracut.conf.d/plymouth.conf
add_dracutmodules+=" plymouth "
EOF

RUN plymouth-set-default-theme red_loader
RUN set -x; kver=$(cd /usr/lib/modules && echo *); dracut -vf /usr/lib/modules/$kver/initramfs.img $kver

RUN mkdir -p /usr/lib/bootc/kargs.d
RUN cat <<EOF >> /usr/lib/bootc/kargs.d/plymouth.toml
kargs = ["splash quiet"]
match-architectures = ["x86_64"]
EOF


# RUN systemctl enable seatd.service \
#     && systemctl enable greetd.service
