#!/bin/bash

#Load Modules

echo "Loading necessary kernel modules"
modprobe nfs
modprobe nfsd

echo "Building docker images if not already built..."

docker build -t dhcp -f dhcp_dockefile
docker build -t tftp -f tftp_dockerfile
docker build -t nfs -f nfs_dockerfile

echo "Docker images ready"
printf "\n \n Please provide the location of your image directory of the image to host for PXE booting. This should be of the format and contain the following: \n |-- compressed kernel binary (named bzImage,vmlinux,vmlinuz or zImage) \n |-- initramfs.cpio.gz (usually has file extension \
.cpio.gz or any .cpio.* \n |-- root\\ (the location of the whole root directory containing everything) \n \n \n"
read $pathtov
printf "Please provide the directory which contains your pxelinux cfg file for the pxe menu - this should have the file named as default - note to use the example as a reference where these must have a parent directory of /tftpboot/images/ \n please review the scripts/setup.sh to see how they are mounted"
read $pathtod
echo "Starting docker services..."

docker run -d --net host dhcp
docker run -d --net host -v $pathtod:/tftpboot/pxelinux.0 tftp
docker run -d --net host -v $pathtod:/tftpboot/pxelinux.0 -v $pathtov:/tftpboot/images --cap-add SYS_ADMIN nfs