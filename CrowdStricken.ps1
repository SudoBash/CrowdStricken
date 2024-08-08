# UNTESTED BLIND EMERGENCY DEVELOPMENT
param (
    [string]$hypervisor = "10.10.10.10", # IP of Hypervisor Host
    [string]$user = "Hypervisor Username", # Hypervisor Root / Administrator Username
    [string]$pass = "Hypervisor Password", # Hypervisor Root / Administrator Password
    [string]$datastore = "ISO", # Datastore where you store your ISO files
    [string]$ISO = "CrowdStricken.iso", # Standard Alpine with root password set to alpine (must have a password, but alpine defaults to blank, which won't work I don't think #unconfirmed)
    [switch]$vmware, # Switches for which hypervisor you have
    [switch]$hyperv,
    [switch]$proxmox,
    [switch]$xen
)

Set-StrictMode -Off

$defaultAutoLoad = $PSMmoduleAutoloadingPreference
$PSMmoduleAutoloadingPreference = "none"

# Hypervisor imports for Connect / Close Hypervisor
if($vmware){
    if (Get-Module -ListAvailable -Name VMware*) {
        Import-Module VMware.VimAutomation.Core 2>&1 | out-null
        Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope Session -Confirm:$false | Out-Null
    }
}
elseif ($hyperv){} # Anyone?
elseif($proxmox){} # Anyone?
elseif($xen){} # Anyone?

# Universal Connect
function Connect-Hypervisor {
    $session = Connect-VIServer -Server $hypervisor -User:$user -Pass:$pass 2>&1 | out-null
    Write-Host "Connecting to Hypervisor"
    if($global:DefaultVIServer.name -like $hypervisor){
        Write-Host "Established Connection to $session"
    } else {
        Write-Host "Couldn't Connect to $hypervisor"
        exit
    }
    return $session
}

#Universal Close
function Close-Hypervisor {
    if($global:DefaultVIServer.name -like $hypervisor){
        Write-Host "Disconnecting from Hypervisor and Cleaning Up..."
        Remove-PSDrive -Name DS -Confirm:$false 2>&1 | out-null
        Disconnect-VIServer $hypervisor -Confirm:$false 2>&1 | out-null
    }
}

# Bash ScriptBlock that gets executed on each VM Guest through Invoke-VMScript (by the Hypervisor)
$repair_script = @"
!/bin/bash
mkdir -p /media/drive
mapfile -t devices < <(blkid -o list)

for device_info in "${devices[@]}"; do
    device_path=$(echo "$device_info" | awk '{print $1}')
    device_type=$(echo "$device_info" | awk '{print $2}')

    if [[ "$device_type" == "ntfs" || "$device_type" == "vfat" ]]; then
        echo "Windows drive detected: $device_path"
        break
    fi
done

#RFC: Could move the fix below into the above loop to attempt the fix on all discovered NTFS / VFAT partitions instead of first discovered since it searches for the file.

echo "Attempting to mount suspected Windows Partition: $device_path"

mount -t $device_type $device_path /media/drive

if [ "$(find /media/drive/Windows/System32/drivers/CrowdStrike/ -maxdepth 1 -name 'C-00000291*.sys')" ]; then
    echo "Faulty Cloudstrike Driver Found! Deleting..."
    rm /media/drive/Windows/System32/drivers/CrowdStrike/C-00000291*.sys
else
    echo "Faulty Cloudstrike Driver NOT Found! Unmounting!"
    umount /media/drive
fi
"@

    # Main
    $session = Connect-Hypervisor # Connect to your Hypervisor

    # Could manually define machines if you want more control:
    # $machines = @("vm-name", "vm1", "vm2")
    $machines = Get-VM -Name * # Get ALL Virtual Machines
    
    foreach -Parallel ($machine in $machines) { # Loop through machines one at a time
        Write-Host "Attempting to Repair $machine"
        $vm = Get-VM -name $machine -ErrorAction SilentlyContinue # Get-VM into $vm
        $cd = Get-CDDrive -VM $vm # Get VM's CD Drive for Set-CDDrive
        Set-CDDrive -CD $cd -ISOPath "[$datastore]\$ISO" -Confirm:$false -StartConnected $true # Set custom Alpine / CrowdStricken.iso to VM's CD Drive
        
        Start-Sleep -Seconds 1 # Sleep for setting change
        $power = Start-VM -VM $vm -Confirm:$false -ErrorAction SilentlyContinue # power on
        Start-Sleep -Seconds 10 # Wait for inevitable Boot
		
        while ($Power_Task.ExtensionData.Info.State -eq "running") {  # While VM State not equal to running
		Start-Sleep 1 # Wait 1 extra sec
		$Power_Task.ExtensionData.UpdateViewData('Info.State') #Update State view data
	}
	
        $repair = Invoke-VMScript -VM $vm -GuestUser "root" -GuestPass "alpine" -ScriptType "Bash" -ScriptText $repair_script # root must have a password for this command to be successful, I believe
	
        $shutdown = Shutdown-VMGuest -VM $machine -Confirm:$false -Server $session -ErrorAction SilentlyContinue # Shutdown after fix to change settings for next boot
        Set-CDDrive -CD $cd -ISOPath "" -Confirm:$false -StartConnected $false # Reset CD Settings for normal boot
	#$power = Start-VM -VM $vm -Confirm:$false -ErrorAction SilentlyContinue # Uncomment this to auto boot machines back up for normal operation
    }

    Close-Hypervisor
