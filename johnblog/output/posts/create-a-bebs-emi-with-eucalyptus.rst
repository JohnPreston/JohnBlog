.. link: 
.. description: Eucalyptus - Create bfEBS EMIs
.. tags: eucalyptus
.. date: 2013/10/31 12:55:37
.. title: Create a bEBS EMI with Eucalyptus
.. slug: create-a-bebs-emi-with-eucalyptus

There are two types of EMI : Instance-Store and EBS.

In Cloud platforms, there are two types of backend-storing when a VM is launched : instance-store and EBS. First of all, let see the differences :

An instance-store VM will be launched from a S3 image which will be stored in Walrus (like any S3 bucket) in several files. When the VM is launched, the Node Controller (NC) will download the files and store it in his own local hard drive. Then, it will run the new VM from these files. That means the VM is ran "locally". Faster to be launched, but, volatile : on stopping the VM, it will be destroyed and all files on it too. Like an ephemeral disk. 

EBS Backed Instances, have their HDD on the Storage Contoller (SC). Each time you create a new VM, it will copy the original snapnhot to be a volume like another. It will be auto-attached to the Instance, being /dev/sda, and the VM will start her system from this, as if it was a generic server with its own HDD. It maybe a little longer than a Instance-Store to be launched, but you can stop these VMs and keep all datas (be carefull, it doesn't mean it will keep the ephemerals one)

So, as really often asked we're gonna see how to do a bfEBS instance for any usage.
-----------------------------------------------------------------------------------

First, it's really interesting to know how to setup instance-store VMs, and it is very, especially using the eustore.

We will consider your cloud is correctly setup, all services are enabled and working. Do not forget to source the eucarc file you must have downloaded. I DO suggest you to have at least one graphical client (setenv XForwarding if not) to use virt-manager. It's a pretty useful and powerfull tool to manage your XEN / KVM nodes, on remote.

Once you're ready, begin with download an instance store from the eustore. Begin with listing all images avaiable on eustore :

.. code-block:: bash

   euser@clc-0 $>euca-describe-services -E
