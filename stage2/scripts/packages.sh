# ansible local - if only ansible could be used without
# a local client when run by packer.
# More recent version of ansible is needed than version
# in ubuntu universe so install from PPA here.
PACKAGES="
software-properties-common
"
apt-get -y install $PACKAGES
apt-add-repository ppa:ansible/ansible
apt-get -y update
apt-get -y install ansible
