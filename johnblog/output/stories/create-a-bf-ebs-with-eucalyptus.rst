.. link: 
.. description: Tutorial to create a bfEBS EMI for Eucalyptus
.. tags: Eucalyptus, Cloud Computing, bfEBS
.. date: 2013/11/02 21:51:12
.. title: Create a bf EBS with Eucalyptus
.. slug: create-a-bf-ebs-with-eucalyptus

There are two types of instances : Instance-Store and EBS-Backend. As you will be able to see here (http://url-vers-explication-ebs-instancestrore) EBS give you the capacity to keep your datas on SAN, to stop / start a VM without loosing datas. But there is no "3 Clicks" way to have one today. So here we are going to see an easy and sure way to create your EBS EMIs.

Requirements
------------

Of course, you will need to have a working Eucalyptus Cloud. It seems obviouis that you have enough compute capacity to run new instances and enough hard drive free space to create EBS and snapshots. Depending on your platform, some steps may be long.

Let's check some cloud-properties and status :

.. code-block:: bash

   admin@clc-0 $>euca-describe-services -E # here we check that all the Eucalyptus components are running and registred
   admin@clc-0 $>euca-describe-properties
   admin@clc-0 $>euca-create-volume -s 5 -z cluster # here we test that EBS creation is working properly


The services must be all enabled and let's understand some cloud-properties for our needs :

- cluster.storage.maxtotalvolumesizeingb : This is the size allocated for all EBS volumes
- cluster.storage.maxvolumesizeingb : This is the maximum size of 1 EBS volume (default: 15Go)

  - *You will have to change this property if you want to create more thant 15 Go EBS volumes*

- cluster.storage.shouldtransfersnapshots : Defines if your snapshots should also be transfered in S3 Walrus. (default: True)

  - *This will allow you to "distribute" all your EMIs across regions easily. But This will take more time to create the snapshot.*

- walrus.storagemaxtotalsnapshotsizeingb : This is the maximum size allocated for all your snapshots

Original VM
-----------

Most of people want to do an EBS EMI from an Instance-Store one. I am not part of these people. I prefer to fully create an instance from my own. There are ways :

- You have physical access to the NC, and the capacity to use and external medium (USB CD/DVD Reader - USB Key) to boot on and setup the OS
- You do not have physical access but you have SSH access to it and your client has graphical X Server (You can also use XMing for Windows).
- The computer you are working with supports virtualization.

First case
==========

Here, we only have to create a volume, snapshot it and register an EMI. Then run a new instance. Obviously, no OS on the EBS. But thanks to the USB Device, you can add a PCI device on the fly, and declare to boot from it. Then, do your setup. When OS setup finished, you have your VM. Stop it, snapshot the root device and re-create an EMI.

.. attention:: You will need to use the init scripts provided by Eucalyptus or create your own to have SSH-Key based access and other functions.

Second case
===============

We now need an Instance (an instance-store one). This one will allow us to use our EBS in the future. Will eustore, download one and run it :

.. code-block:: bash

   admin@clc-0 $>eustore-describe-images
   admin@clc-0 $>eustore-install-image --help
   admin@clc-0 $>euca-run-instances $EMI -n $number -k $KEY -t $instance-size -g $group

I do advice you to create specific Security Groups depending on your Instance usage.

Use virt-manager
^^^^^^^^^^^^^^^^

I am a shell guy, mean I do everything in shell windows, but it is also true to say that GUI have a lot of benefits. Here, what we are going to do is to use virt-manager. It is a very powerful tool to manage KVM / XEN on remote and redirect all through SSH. So, here I am on a CentOS client with graphical interface. Be sure to have ssh access to your NC.

Before creating our VM
""""""""""""""""""""""

I advice you to enable graphical access (via VNC) to the VM created by Eucalyptus. To do so, uncomment vnc section in /etc/eucalyptus/libvirt.xsl :

.. code-block:: xml

    <graphics type='vnc' port='-1' autoport='yes' keymap='en-us'/>

Restart the Node controller service (If you have running VMs on it, this **will not** stop them)

.. code-block:: bash

   sudo service eucalyptus-nc restart

Use ssh-keys
""""""""""""

For any action made by virt-manager, you will be prompted for your password. To avoid this and guarantee a full secured permanent access, use ssh-keys : generate a ssh-key for your current user, then, sync it for the root user on your NC :

.. code-block:: bash

   user@client $>ssh-keygen -t rsa -b 4096
   user@client $>ssh-copy-id -i $HOME/.ssh/id_rsa.pub root@node

Once it's done, download and setup virt-manager, then, launch it. If you plan to use your own computer (the one you are working with) to create this original VM, do so, otherwise, create a new connection to your NC.

.. note:: You will need the ISO of the Operating System you plan to install. On a NC, you should put this in /var/lib/libvirt/images with the correct access rights (libvirt:root)

.. warning:: If you plan to create a Windows EMI, get the KVM drivers and kernels. If you do not provide these to windows, you will not be able to detect virtio drives

Create on VM
^^^^^^^^^^^^

Here we are ! That's the usual way to install a new operating system. You will be able to assign the values you want to your original VM.

.. warning::

   In /etc/eucalyptus/eucalyptus.conf on your NC, you are using specific VM properties : virtio. Be sure that all devices on the VM you are creating are the same according to this configuration !

.. tip::

   Here you will be able to organize your partitions on your will. There are tens way to do so. Here is the right moment to plan your instance according to its usage.

   - Classical VM ? :

     - Create a /boot, / using most of space and some for the swap
     - Create a /boot, / using most of space and NO swap : you will use a script which on startup will use part of your ephemeral as a swap device

   - Heavy storage VM ?

     - Create a /boot, and use LVM for the sub parts : in the future, if you need more space, add EBS volumes, and extend LVM ;)

Prepare our fresh VM for Eucalyptus
===================================

Our setup is finished, and after reboot we are glad to see our system running properly. But, it is a too specific one. So here we are going to "clean" this VM to be the most generic possible. We also are going to setup all our usual packages.

On linux
^^^^^^^^

At startup, you system created some "rules" which come from your hardware configuration. We need to delete this, because all the instances you will create from this EMI will have different properties (i.e. the eth0 MAC address). So begin with deleting these rules :

.. code-block:: bash

   rm -rfv /etc/udev/rules.d/* # rules usually are in the same directory for most common distros. Specifyt this path according to yours.

.. warning::

   For CentOS or RedHat EMIs, remember to delete the HWADDR property in /etc/sysconfig/network-scripts/ifcfg-eth0 and set BOOTPROTO to dhcp and ONBOOT to yes
   On debian based, the HWADDR is usually not set.

