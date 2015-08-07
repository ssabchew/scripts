#!/bin/bash

# Set name
name=${1:-centos7}
CHROOT=/var/lib/libvirt/lxc/"${name}"

mkdir -p "${CHROOT}"/etc/yum.repos.d/
cat /etc/yum.repos.d/CentOS-Base.repo |sed s/'$releasever'/7/g > "${CHROOT}"/etc/yum.repos.d/CentOS-Base.repo

yum -y  groupinstall core --installroot="${CHROOT}" --nogpgcheck

cat > "${CHROOT}"/config.sh <<  EOFF
#!/bin/bash
# set password
echo changeme |passwd root --stdin

# login console
cp /etc/securetty /etc/securetty.dist
echo "pts/0" > /etc/securetty
cp etc/pam.d/login etc/pam.d/login.dist
sed -i s/"session    required     pam_selinux.so close"/"#session    required     pam_selinux.so close"/g /etc/pam.d/login
sed -i s/"session    required     pam_selinux.so open"/"#session    required     pam_selinux.so open"/g /etc/pam.d/login
sed -i s/"session    required     pam_loginuid.so"/"#session    required     pam_loginuid.so"/g /etc/pam.d/login

# login ssh
cp /etc/pam.d/sshd /etc/pam.d/sshd.dist
sed -i s/"session    required     pam_selinux.so close"/"#session    required     pam_selinux.so close"/g /etc/pam.d/sshd
sed -i s/"session    required     pam_loginuid.so"/"#session    required     pam_loginuid.so"/g /etc/pam.d/sshd
sed -i s/"session    required     pam_selinux.so open env_params"/"#session    required     pam_selinux.so open env_params"/g /etc/pam.d/sshd

cat > /etc/sysconfig/network << EOF
NETWORKING=yes
HOSTNAME=lxc-template
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE=eth0
BOOTPROTO=dhcp
ONBOOT=yes
EOF

# Configure start-up services:
systemctl enable sshd
systemctl disable avahi-daemon
systemctl disable auditd
chkconfig network on

exit
EOFF

chmod +x "${CHROOT}"/config.sh
chroot "${CHROOT}" ./config.sh
rm -rf "${CHROOT}"/config.sh

echo "Now you can add new LXC Operating System Containter, pointing the"
echo "OS root directory to ${CHROOT}"
