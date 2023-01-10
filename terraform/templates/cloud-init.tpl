#cloud-config

hostname: ${instance_name}

# Disable password authentication with the SSH daemon
ssh_pwauth: false

# /dev/nvme1n1 is mounted at an arbitrary time during the boot process.
# shamelessly taken from https://binx.io/blog/2019/01/26/how-to-mount-an-ebs-volume-on-nvme-based-instance-types/
bootcmd:
- mkdir -p /data
- while [ ! -b $(readlink -f /dev/nvme1n1) ]; do echo "waiting for device /dev/nvme1n1"; sleep 5 ; done
- blkid $(readlink -f /dev/nvme1n1) || mkfs -t ext4 -L data $(readlink -f /dev/nvme1n1)
- sed  -e '/^[\/][^ \t]*[ \t]*\/data[ \t]/d' -i /etc/fstab
- grep -q ^LABEL=data /etc/fstab || echo 'LABEL=data /data ext4 defaults,noatime 0 0' >> /etc/fstab
- grep -q "^$(readlink -f /dev/nvme1n1) /data " /proc/mounts || mount /data

packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg-agent
  - software-properties-common
  - git
  - jq
  - openssh-server
  - net-tools
  - htop
  - iftop
  - iotop
  - haveged
  - fail2ban
  - docker.io
  - docker-compose

runcmd:
  - systemctl stop snapd.socket && systemctl disable snapd.socket
  - systemctl disable snapd.service && systemctl disable snapd.service
  - systemctl disable snap.amazon-ssm-agent.amazon-ssm-agent.service && systemctl disable snap.amazon-ssm-agent.amazon-ssm-agent.service
  - apt autoremove -y --purge snapd
  - DEBIAN_FRONTEND=noninteractive dpkg-reconfigure --priority=low unattended-upgrades
  - sed -e "s/^.*precedence.*::ffff:0:0\/96.*10$/precedence ::ffff:0:0\/96  100/" -i /etc/gai.conf
  - systemctl start docker
  - systemctl enable docker

write_files:
  - path: /etc/systemd/timesyncd.conf
    permissions: '0644'
    owner: root:root
    content: |
      [Time]
      NTP=169.254.169.123
  - path: /etc/ssh/sshd_config.d/no-root-login.conf
    permissions: '0644'
    owner: root:root
    content: |
      PermitRootLogin no
