#!/bin/bash

# Not all machines contain sudo
if [ -x "$(command -v sudo)" ]; then
	sudo="sudo"
else
	sudo=""
fi

echo "Checking if docker is installed..."
if [ -x "$(command -v docker)" ]; then
    # docker is installed
	version=$(docker version --format '{{.Server.Version}}')
	echo "Docker found as version $version"
else
    # docker is not installed
	echo "Docker is not installed, in order to run this system it is required, would you like to install it? (Y/y/N/n)"
	read install
	if [[ $install == "Y" ]] || [[ $install == "y" ]]; then
		packagesNeeded='docker-ce docker-ce-cli containerd.io'
		if [ -x "$(command -v apk)" ]; then
			echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/community/" >> /etc/apk/repositories
			$sudo apk update
			$sudo apk add --no-cache docker --allow-untrusted
		elif [ -x "$(command -v apt-get)" ]; then
			$sudo apt update
			$sudo apt-get -y install ca-certificates curl gnupg lsb-release
			curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
			echo \
			"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
			$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
			$sudo apt-get update
			$sudo apt-get -y install $packagesNeeded
		elif [ -x "$(command -v dnf)" ]; then
			$sudo dnf -y install dnf-plugins-core
			$sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
			$sudo dnf -y install $packagesNeeded
			$sudo systemctl start docker
		elif [ -x "$(command -v yum)" ]; then
			$sudo yum update
			$sudo yum install -y yum-utils
			$sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
			$sudo yum -y install $packagesNeeded
			$sudo systemctl start docker
		elif [ -x "$(command -v zypper)" ]; then 
			sles_version="$(. /etc/os-release && echo "${VERSION_ID##*.}")"
			opensuse_repo="https://download.opensuse.org/repositories/security:SELinux/SLE_15_SP$sles_version/security:SELinux.repo"
			$sudo zypper addrepo $opensuse_repo
			$sudo zypper addrepo https://download.docker.com/linux/sles/docker-ce.repo
			$sudo zypper -y install $packagesNeeded
			$sudo systemctl start docker
		else
			echo "FAILED TO INSTALL PACKAGE: Package manager not found. You must manually install: $packagesNeeded">&2
			exit
		fi
		#Now we add the user to the docker group and make sure that group exists
		getent group docker || groupadd docker
		addgroup $USER docker
		version=$(docker version --format '{{.Server.Version}}')
		echo "Docker has now been installed and setup with version $version"
	else
		echo "Docker is not installed, therefore this script cannot run correctly, aborting..."
		exit
	fi
fi

#Now docker is setup, check for nfs kernel modules needed
if [[ $(lsmod | grep 'nfs ') == "" ]]; then
	echo "nfs is not an installed kernel module, would you like to install it? (Y/y/N/n)"
	read install
	if [[ $install == "Y" ]] || [[ $install == "y" ]]; then
		if [ -x "$(command -v apk)" ]; then
			$sudo apk update
			$sudo apk add nfs-utils
		elif [ -x "$(command -v apt-get)" ]; then
			$sudo apt update
			$sudo apt-get -y install nfs-common
		elif [ -x "$(command -v dnf)" ]; then
			$sudo dnf -y install nfs-utils
		elif [ -x "$(command -v yum)" ]; then
			$sudo yum update
			$sudo yum install -y nfs-utils
		elif [ -x "$(command -v zypper)" ]; then 
			$sudo zypper -n in nfs-client
		else
			echo "FAILED TO INSTALL PACKAGE: Package manager not found. You must manually install: $packagesNeeded">&2
			exit
		fi
	else
		echo "The nfs microservice will not run without nfs client and server modules installed, aborting..."
		exit
	fi
else
	if [[ $(modinfo nfsd | grep 'filename') == "" ]] && [[ ! ${PIPESTATUS[-1]} ]]; then
		echo "nfs daemon (server) kernel module is not installed"
		read install
		if [[ $install == "Y" ]] || [[ $install == "y" ]]; then
			if [ -x "$(command -v apk)" ]; then
				$sudo apk update
				$sudo apk add nfs-utils
			elif [ -x "$(command -v apt-get)" ]; then
				$sudo apt update
				$sudo apt-get -y install nfs-kernel-server
			elif [ -x "$(command -v dnf)" ]; then
				$sudo dnf -y install nfs-utils
			elif [ -x "$(command -v yum)" ]; then
				$sudo yum update
				$sudo yum install -y nfs-utils
			elif [ -x "$(command -v zypper)" ]; then 
				$sudo zypper -n in nfs-kernel-server
			else
				echo "FAILED TO INSTALL PACKAGE: Package manager not found. You must manually install: $packagesNeeded">&2
				exit
			fi
		else
			echo "The nfs microservice will not run without nfs client and server modules installed, aborting..."
			exit
		fi
	fi
fi

echo "All prerequisities have been met, moving to setup of system"