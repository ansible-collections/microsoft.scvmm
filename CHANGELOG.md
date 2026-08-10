# Microsoft SCVMM Collection Release Notes

**Topics**

- <a href="#v1-1-0">v1\.1\.0</a>
    - <a href="#release-summary">Release Summary</a>
    - <a href="#new-modules">New Modules</a>
- <a href="#v1-0-1">v1\.0\.1</a>
- <a href="#v1-0-0">v1\.0\.0</a>
    - <a href="#minor-changes">Minor Changes</a>
    - <a href="#new-modules-1">New Modules</a>

<a id="v1-1-0"></a>
## v1\.1\.0

<a id="release-summary"></a>
### Release Summary

Added new modules for bare metal provisioning\, inventory\, jobs\, servicing windows\, custom properties\, and library management\.

<a id="new-modules"></a>
### New Modules

* microsoft\.scvmm\.scvmm\_baseline \- Manage update baselines in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_baseline\_info \- Query update baselines in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_compliance\_info \- Query compliance status of managed computers in SCVMM\.
* microsoft\.scvmm\.scvmm\_compliance\_scan \- Start a compliance scan on a managed computer in SCVMM\.
* microsoft\.scvmm\.scvmm\_custom\_property \- Manage custom properties in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_custom\_property\_info \- Query custom properties in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_custom\_resource \- Manage custom resources in the SCVMM library\.
* microsoft\.scvmm\.scvmm\_custom\_resource\_info \- Query custom resources in the SCVMM library\.
* microsoft\.scvmm\.scvmm\_inventory\_info \- Retrieve SCVMM managed infrastructure inventory\.
* microsoft\.scvmm\.scvmm\_iso \- Manage ISO images in the SCVMM library\.
* microsoft\.scvmm\.scvmm\_iso\_info \- Query ISO images in the SCVMM library\.
* microsoft\.scvmm\.scvmm\_job \- Manage SCVMM job state\.
* microsoft\.scvmm\.scvmm\_job\_info \- Query jobs in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_library\_share \- Manage library shares in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_library\_share\_info \- Query library shares in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_physical\_computer\_profile \- Manage physical computer profiles in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_physical\_computer\_profile\_info \- Get information about physical computer profiles in SCVMM\.
* microsoft\.scvmm\.scvmm\_pxe\_server \- Manage PXE servers in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_pxe\_server\_info \- Query PXE servers in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_script \- Manage scripts in the SCVMM library\.
* microsoft\.scvmm\.scvmm\_script\_info \- Query scripts in the SCVMM library\.
* microsoft\.scvmm\.scvmm\_servicing\_window \- Manage servicing windows in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_servicing\_window\_info \- Query servicing windows in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_update\_server \- Manage WSUS update servers in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_update\_server\_info \- Query WSUS update servers in System Center Virtual Machine Manager\.

<a id="v1-0-1"></a>
## v1\.0\.1

<a id="v1-0-0"></a>
## v1\.0\.0

<a id="minor-changes"></a>
### Minor Changes

* scvmm\_vm \- Manage the creation\, update\, and removal of Virtual Machines on SCVMM 2022\.

<a id="new-modules-1"></a>
### New Modules

* microsoft\.scvmm\.scvmm\_application\_profile \- Manage application profiles in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_application\_profile\_info \- Query application profiles in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_capability\_profile \- Manage capability profiles in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_capability\_profile\_info \- Query capability profiles in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_cloud \- Manage private clouds in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_cloud\_capacity \- Manage cloud capacity limits in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_cloud\_capacity\_info \- Query cloud capacity information in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_cloud\_info \- Query private cloud information in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_guest\_os\_profile \- Manage guest OS profiles in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_guest\_os\_profile\_info \- Query guest OS profiles in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_hardware\_profile \- Manage hardware profiles in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_hardware\_profile\_info \- Query hardware profiles in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_host \- Manage Hyper\-V hosts in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_host\_cluster \- Manage Hyper\-V failover clusters in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_host\_cluster\_info \- Query host cluster information in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_host\_group \- Manage host groups in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_host\_group\_info \- Query host groups in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_host\_info \- Query Hyper\-V host information in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_host\_network\_adapter \- Manage host network adapter configuration in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_host\_network\_adapter\_info \- Query host network adapter information in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_host\_rating\_info \- Query host placement ratings in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_ip\_pool \- Manage static IP address pools in SCVMM\.
* microsoft\.scvmm\.scvmm\_ip\_pool\_info \- Query static IP address pools in SCVMM\.
* microsoft\.scvmm\.scvmm\_load\_balancer \- Manage load balancers in SCVMM\.
* microsoft\.scvmm\.scvmm\_load\_balancer\_info \- Query load balancers in SCVMM\.
* microsoft\.scvmm\.scvmm\_logical\_network \- Manage logical networks in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_logical\_network\_definition \- Manage logical network definitions \(network sites\) in SCVMM\.
* microsoft\.scvmm\.scvmm\_logical\_network\_definition\_info \- Query logical network definitions in SCVMM\.
* microsoft\.scvmm\.scvmm\_logical\_network\_info \- Query logical networks in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_logical\_switch \- Manage logical switches in SCVMM\.
* microsoft\.scvmm\.scvmm\_logical\_switch\_info \- Query logical switches in SCVMM\.
* microsoft\.scvmm\.scvmm\_mac\_address\_pool \- Manage MAC address pools in SCVMM\.
* microsoft\.scvmm\.scvmm\_mac\_address\_pool\_info \- Query MAC address pools in SCVMM\.
* microsoft\.scvmm\.scvmm\_network\_adapter \- Manage virtual network adapters on VMs in SCVMM\.
* microsoft\.scvmm\.scvmm\_network\_adapter\_info \- Query virtual network adapters on VMs in SCVMM\.
* microsoft\.scvmm\.scvmm\_port\_classification \- Manage port classifications in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_port\_classification\_info \- Query port classifications in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_run\_as\_account \- Manage Run As accounts in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_run\_as\_account\_info \- Query Run As accounts in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_service \- Manage services in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_service\_info \- Get service information from System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_service\_template \- Manage service templates in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_service\_template\_info \- Get service template information from System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_sql\_profile \- Manage SQL profiles in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_sql\_profile\_info \- Get SQL profile information from System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_storage\_classification \- Manage storage classifications in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_storage\_classification\_info \- Query storage classifications in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_storage\_file\_share\_info \- Query storage file shares in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_storage\_pool \- Manage storage pools in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_storage\_pool\_info \- Query storage pools in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_storage\_provider \- Manage storage providers in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_storage\_provider\_info \- Query storage providers in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_template \- Manage VM templates in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_template\_info \- Query VM templates in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_uplink\_port\_profile \- Manage native uplink port profiles in SCVMM\.
* microsoft\.scvmm\.scvmm\_uplink\_port\_profile\_info \- Query native uplink port profiles in SCVMM\.
* microsoft\.scvmm\.scvmm\_user\_role \- Manage user roles in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_user\_role\_info \- Query user roles in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_user\_role\_quota \- Manage user role quotas in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_user\_role\_quota\_info \- Query user role quotas in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_virtual\_hard\_disk \- Manage virtual hard disks in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_virtual\_hard\_disk\_info \- Query virtual hard disks in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_vm \- Manage SCVMM virtual machines\.
* microsoft\.scvmm\.scvmm\_vm\_checkpoint \- Manage VM checkpoints in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_vm\_checkpoint\_info \- Retrieve checkpoint information for SCVMM virtual machines\.
* microsoft\.scvmm\.scvmm\_vm\_clone \- Clone a virtual machine in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_vm\_disk \- Manage virtual disk drives on SCVMM virtual machines\.
* microsoft\.scvmm\.scvmm\_vm\_disk\_info \- Query virtual disk drives on VMs in SCVMM\.
* microsoft\.scvmm\.scvmm\_vm\_dvd\_drive \- Manage virtual DVD drives on SCVMM virtual machines\.
* microsoft\.scvmm\.scvmm\_vm\_dvd\_drive\_info \- Retrieve DVD drive information for SCVMM virtual machines\.
* microsoft\.scvmm\.scvmm\_vm\_info \- Retrieve information about SCVMM virtual machines\.
* microsoft\.scvmm\.scvmm\_vm\_migrate \- Live migrate a VM between Hyper\-V hosts in SCVMM\.
* microsoft\.scvmm\.scvmm\_vm\_network \- Manage VM networks in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_vm\_network\_info \- Query VM networks in System Center Virtual Machine Manager\.
* microsoft\.scvmm\.scvmm\_vm\_nic \- Configure virtual network adapter settings on VMs in SCVMM\.
* microsoft\.scvmm\.scvmm\_vm\_scsi\_adapter \- Manage virtual SCSI adapters on SCVMM virtual machines\.
* microsoft\.scvmm\.scvmm\_vm\_scsi\_adapter\_info \- Retrieve SCSI adapter information for SCVMM virtual machines\.
* microsoft\.scvmm\.scvmm\_vm\_state \- Manage SCVMM virtual machine power state\.
* microsoft\.scvmm\.scvmm\_vm\_subnet \- Manage VM subnets in SCVMM\.
* microsoft\.scvmm\.scvmm\_vm\_subnet\_info \- Query VM subnets in SCVMM\.
