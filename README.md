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

###Stage 1 - build qemu+kvm image

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
[si@buru stage1]$ packer build packer_stage1.json
...
[si@buru stage1]$ vagrant box add vap_stage1 box/vap_stage1.box
...
[si@buru stage1]$ cd vagrant/
[si@buru vagrant]$ vagrant up
```
You should now have a local virtual machine and should be able to do the following-

```Shell
[si@buru stage1]$ virsh list
 Id    Name                           State
----------------------------------------------------
 16    stage1_vap_vm         running

[si@buru stage1]$ vagrant ssh
Welcome to Ubuntu 14.04.2 LTS (GNU/Linux 3.16.0-30-generic x86_64)

 * Documentation:  https://help.ubuntu.com/
Last login: Thu May 28 13:33:46 2015 from 192.168.121.1
vagrant@packer-vap:~$ 
```

You could run the virtual machine like this-
```Shell
[si@buru stage2]$ qemu-system-x86_64 output-qemu/vap-stage2.qcow2
```

To remove the box and delete the volume from libvirt (this needs to be
done before importing a subsequent build)-
```Shell
[si@buru stage1]$ vagrant destroy
==> vap_vm: Removing domain...
[si@buru stage1]$ vagrant box remove vap_stage1
...
[si@buru stage1]$ rm -r -f output-qemu
[si@buru stage1]$ rm -r -f box
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

```Shell
[si@buru stage2]$ packer build packer_stage2.json
...
[si@buru stage2]$ vagrant box add vap_stage2 box/vap_stage2.box
...
[si@buru stage2]$ vagrant box add vap_stage2 box/vap_stage2.box
==> box: Adding box 'vap_stage2' (v0) for provider: 
    box: Downloading: file:///home/si/workspace/vap/stage2/box/vap_stage2.box
==> box: Successfully added box 'vap_stage2' (v0) for 'libvirt'!
[si@buru stage2]$ cd vagrant/
[si@buru vagrant]$ vagrant up
Bringing machine 'vap_vm' up with 'libvirt' provider...
==> vap_vm: Uploading base box image as volume into libvirt storage...
==> vap_vm: Creating image (snapshot of base box volume).
==> vap_vm: Creating domain with the following settings...
==> vap_vm:  -- Name:              vagrant_vap_vm
<snip>
==> vap_vm:  -- Command line : 
==> vap_vm: Creating shared folders metadata...
==> vap_vm: Starting domain.
There was an error talking to Libvirt. The error message is shown
below:

Call to virDomainCreateWithFlags failed: internal error: process exited while connecting to monitor: qemu-system-x86_64: -drive file=/var/lib/libvirt/images/vagrant_vap_vm.img,if=none,id=drive-virtio-disk0,format=qcow2: could not open disk image /var/lib/libvirt/images/vagrant_vap_vm.img: Could not open backing file: Image is not in qcow2 format

[si@buru vagrant]$ sudo file /var/lib/libvirt/images/*
/var/lib/libvirt/images/vagrant_vap_vm.img:                 QEMU QCOW Image (v2), has backing file (path /var/lib/libvirt/images/vap_stage2_vagrant_box_image_0.img), 10737418240 bytes
/var/lib/libvirt/images/vap_stage2_vagrant_box_image_0.img: x86 boot sector
[si@buru vagrant]$ file /var/lib/libvirt/images/vap_stage2_vagrant_box_image_0.img
/var/lib/libvirt/images/vap_stage2_vagrant_box_image_0.img: x86 boot sector
[si@buru vagrant]$ 
```

... so the vagrant box doesn't work. I've not had time to look into this, please help if you know the solution!

