PACKAGES="
vim-nox
"
apt-get -y install $PACKAGES

#
#software-properties-common
#
# more up to date version of ansible so it can be used
# locally by packer. The ansible patch module is being
# used so at least ansible version 1.9 is needed.
# apt-add-repository is in software-properties-common
#apt-add-repository ppa:ansible/ansible
#apt-get -y update
#apt-get -y install ansible
