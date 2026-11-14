#!/usr/bin/bash

IMAGE_DIR=/var/lib/libvirt/images
BUILD_VER=20261103-2651
HOST_NAME=vehicle
K3S_MINIMUM_CPU=2
K3S_MINIMUM_MEM=2048
DISK_SIZE=20G
K3S_INSTALL_OPTS='K3S_KUBECONFIG_MODE="644"'

function clean_up() {
  rm user-data meta-data
}

# Download the prebuilt debian image
curl -XGET -L  https://cloud.debian.org/images/cloud/trixie/${BUILD_VER}/debian-13-generic-amd64-${BUILD_VER}.qcow2 \
  -o  $IMAGE_DIR/debian-13-generic-amd64-${BUILD_VER}.qcow2

# Refresh the /var/lib/cloud and allow to run the fresh cloud-init config
qemu-img create \
  -f qcow2 \
  -F qcow2  \
  -b  $IMAGE_DIR/debian-13-generic-amd64-${BUILD_VER}.qcow2 $IMAGE_DIR/${HOST_NAME}.qcow2 $DISK_SIZE

# Customized user-data
cat << EOF > user-data
#cloud-config
hostname: ${HOST_NAME}
ssh_pwauth: true
users:
  - name: sdv
    plain_text_passwd: sdv
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /usr/bin/bash
    lock_passwd: false
package_update: true
packages:
  - qemu-guest-agent

runcmd:
  - systemctl enable --now qemu-guest-agent
  - until curl -sfL https://github.com -o /dev/null; do sleep 1; done
  - curl -sfL https://get.k3s.io | $K3S_INSTALL_OPTS sh -
EOF

# State file for the cloud-init
cat << EOF > meta-data
instance-id: ${HOST_NAME}
EOF

# Launch
virt-install \
  --name ${HOST_NAME} \
  --memory $K3S_MINIMUM_MEM \
  --vcpus $K3S_MINIMUM_CPU   \
  --disk path=$IMAGE_DIR/${HOST_NAME}.qcow2   \
  --cloud-init user-data=user-data,meta-data=meta-data  \
  --os-variant debian13 \
  --import \
  --network network=default \
  --noautoconsole

clean_up