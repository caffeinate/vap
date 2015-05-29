# vap
Vagrant + Ansible + Packer
... + libvirt + ubuntu + Flask

##Introduction

I'd like a development and deployment environment with the following:

* Vagrant - local development
* Vmware fusion - self contained local version
* AWS EC2 instance - a public access

This repository is a reference to tie together the tools I used-
* Packer - building system images
* Vagrant - instantiating local virtual machines
* Ansible - orchestration - installing packages and data

Ansible Galaxy is great but I want this to be simple and self contained so it
is easier to use for reference.

###Stage 1 - /vagrant_libvirt/ - build qemu+kvm image

I mainly develop on a Linux workstation and like libvirt for running virtual 
machines. Libvirt combines QEMU and KVM to make hardware virtualised 
machines. It's simple, very stable and fully opensource. But does require a
little more work as the vagrant box also needs to be built as opposed to just
using one provided by Hashicorp. Fortunately these guys did the hard work-

* https://github.com/pradels/vagrant-libvirt/
* https://github.com/jakobadam/packer-qemu-templates/

The image created by this stage is super simple. It is just enough OS
to be used to work with ansible in stage 2. As I'm using vagrant to test and 
refine the ansible playbooks this stage also builds a vagrant box from the
(qcow2 format) libvirt image. Vagrant boxes are provider specific so a
"post-processors" builds the vap.box file from the qcow2 image.

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
[si@buru vagrant_libvirt]$ packer build packer_stage1.json
...
[si@buru vagrant_libvirt]$ vagrant box add vap_stage1 box/vap_stage1.box
...
[si@buru vagrant_libvirt]$ cd vagrant/
[si@buru vagrant]$ vagrant up
```
You should now have a local virtual machine and should be able to do the following-

```Shell
[si@buru vagrant_libvirt]$ virsh list
 Id    Name                           State
----------------------------------------------------
 16    vagrant_libvirt_vap_vm         running

[si@buru vagrant_libvirt]$ vagrant ssh
Welcome to Ubuntu 14.04.2 LTS (GNU/Linux 3.16.0-30-generic x86_64)

 * Documentation:  https://help.ubuntu.com/
Last login: Thu May 28 13:33:46 2015 from 192.168.121.1
vagrant@packer-vap:~$ 
```

You could also import and then run the virtual machine using virsh like this-
(you'll need to put the qcow disk image somewhere the qemu user can access it)

```Shell
[si@buru vagrant_libvirt]$ sudo cp output-qemu/vap-stage1.qcow2 /data
[si@buru vagrant_libvirt]$ sudo virt-install --name demo \
>               --ram 512 \
>               --disk path=/data/vap-stage1.qcow2 \
>               --import
```

To remove the box and delete the volume from libvirt (this needs to be
done before importing a subsequent build)-
```Shell
[si@buru vagrant_libvirt]$ vagrant destroy
==> vap_vm: Removing domain...
[si@buru vagrant_libvirt]$ vagrant box remove vap_stage1
...
[si@buru vagrant_libvirt]$ rm -r -f output-qemu
[si@buru vagrant_libvirt]$ rm -r -f box
[si@buru vagrant]$ virsh vol-list default
 Name                 Path                                    
------------------------------------------------------------------------------
 vap_stage1_vagrant_box_image_0.img /var/lib/libvirt/images/vap_stage1_vagrant_box_image_0.img

[si@buru vagrant]$ virsh vol-delete vap_stage1_vagrant_box_image_0.img --pool default
Vol vap_stage1_vagrant_box_image_0.img deleted
```

###Stage 2 - Packer+Ansible

Provisioning could be done by vagrant or packer. To keep it as similar as possible
between the 3 images this is done by packer. But being idempotent and as Vagrant
is there to help with the build, it runs ansible as well.

