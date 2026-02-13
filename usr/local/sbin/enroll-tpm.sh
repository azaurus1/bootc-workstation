#!/bin/bash

STATIC_FIRSTBOOT_KEY="password123"
LUKS_VOL=$(lsblk --raw -o NAME,TYPE,FSTYPE | awk '/crypto/ { print "/dev/" $1}')
TPM_PCRS="0:sha256+5:sha256+7:sha256"

if [[ -z $LUKS_VOL ]]; then
    echo "No encrypted block devices found. Exiting."
    exit 0
fi

if cryptsetup luksDump $LUKS_VOL | grep -q systemd-tpm; then
    echo "Already enrolled! No action needed. Exiting."
    exit 0
fi

LUKS_UUID=$(cryptsetup luksUUID $LUKS_VOL)

if [[ ! -e /sys/class/tpm/tpm0/dev ]]; then
    echo "FATAL: Kernel has not found a TPM device! Exiting."
    exit 1
fi

echo -n "$STATIC_FIRSTBOOT_KEY" > /tmp/luks_firstboot_key
chmod 0600 /tmp/luks_firstboot_key

enroll_tpm() {
    systemd-cryptenroll --wipe-slot=all --tpm2-device=auto --tpm2-pcrs=$TPM_PCRS --unlock-key-file=/tmp/luks_firstboot_key $LUKS_VOL <<<$(echo $STATIC_FIRSTBOOT_KEY)
}

make_recovery_key() {
    systemd-cryptenroll $LUKS_VOL --recovery-key --unlock-tpm2-device=auto 2>/dev/null
}

if enroll_tpm; then
    rm /tmp/luks_firstboot_key
    echo "Enrolled TPM! PCRS: $TPM_PCRS"
    make_recovery_key > /etc/.luks_recovery_key
    chmod 0600 /etc/.luks_recovery_key
    echo "Recovery key in /etc/.luks_recovery_key"
else
    echo "FATAL: Issue enrolling TPM!"
    exit 1
fi

