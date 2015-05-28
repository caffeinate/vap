# vap
Vagrant + Ansible + Packer
... + libvirt + ubuntu + Flask

##Introduction

I'd like a development and deployment environment with the following:

* Vagrant for local development
* Use Vmware fusion for self contained private demonstration
* AWS for a public server

This repo. is intended as a reference to tie together the tools I used-
* Packer - building system images
* Vagrant - instantiating local virtual machines
* Ansible - orchestration - installing packages and data

There is an overlap in functionality with all of these devops tools so I'll aim
to keep this to a minimum by getting ansible to do as much work as possible.

Ansible Galaxy is great but I want this to be simple and self contained so it
is easier to use for reference.


###Vagrant

I'm using vagrant to test and refine the ansible playbooks.

I mainly develop on a Linux workstation and like libvirt for running virtual 
machines. Libvirt is a blend of QEMU and KVM so makes hardware virtualised 
machines. It's simple, very stable and fully opensource. But does require a
little more work as the vagrant box also needs to be built as opposed to just
using one provided by Hashicorp. Fortunately these guys did the hard work-

* https://github.com/pradels/vagrant-libvirt/
* https://github.com/jakobadam/packer-qemu-templates/

####Building a vagrant+libvirt box using packer
You only need this stage if you are using libvirt instead of virtualbox
(the default virtualisation environment in vagrant).

If using ubuntu 14.04 as the (physical) host machine install vagrant >= 1.5 from .deb from https://www.vagrantup.com/downloads.html

```Shell
dpkg --install vagrant_1.7.2_x86_64.deb
apt-get install libxslt-dev libxml2-dev libvirt-dev ruby-dev
vagrant plugin install vagrant-libvirt
```

Build the box...
The first time this is run it will need to download the 595M ubuntu image.

```Shell
[si@buru vagrant_libvirt]$ packer build packer_vagrant.json
...
[si@buru vagrant_libvirt]$ vagrant box add vap box/vap.box
...
[si@buru vagrant_libvirt]$ vagrant up
```
You should now have a local virtual machine.


