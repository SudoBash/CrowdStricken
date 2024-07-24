# CrowdStricken: Experimental Crowdstrike Solution

If this helps you, please consider donating with Cash App to $SudoBashX

## Experimental Nature of Script:

This script is provided on an experimental basis and is not guaranteed to resolve issues related to Crowdstrike or any associated outages. 
It is offered "as is," without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and non-infringement. 
The script may not be suitable for production environments or critical systems.

## Use at Your Own Risk:

Users are advised to exercise caution when using this script and should thoroughly review and test it in a non-production environment before deploying it in any critical or production systems. 
The authors and contributors disclaim all liability for any damages, direct or indirect, resulting from the use of this script, including but not limited to loss of data, disruption of services, or any other issues.

## No Endorsement:

The inclusion of any third-party tools, libraries, or references in this script does not imply endorsement or recommendation by the authors or contributors.

## Feedback and Contributions:

Feedback and contributions to improve this script are welcome but will be subject to the same disclaimers and considerations outlined above.

Shoutout to Roush for being a constant source of encouragement, inspiration and seemingly endless knowledge!

By using this script, you acknowledge that you have read, understood, and agree to these terms and conditions.
-

Instructions
-

Download or Build CrowdStricken Alpine ISO (Coming) (Alpine Standard with root password set to alpine)

Transfer CrowdStricken.iso to ISO Datastore

Open Powershell as Administrator

In powershell execute:
Set-ExecutionPolicy Bypass

## For VMware ESXi (vSphere) Infrastructure, execute:

Install-Module -Name VMware.VimAutomation.Core
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false

Edit CrowdStricken.ps1 with Hypervisor IP, User, Pass, ISO Datastore name, etc...

Execute CrowdStricken.ps1 with appropriate option (-vmware | -hyperv | -proxmox | -xen)


## For HyperV Infrastructure, execute:
[Placeholder]


## For ProxMox Infrastructure, execute:
[Placeholder]


## For Xen Infrastructure, execute:
[Placeholder]


## VERY IMPORTANT!

When finished, set PowerShell Execution Policy back to Restricted for security:

Set-ExecutionPolicy Restricted
