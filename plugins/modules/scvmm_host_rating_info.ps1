#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        vm_name = @{ type = 'str'; required = $true }
        host_group = @{ type = 'str'; default = 'All Hosts' }
        vmm_server = @{ type = 'str' }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$vm = Get-SCVMMVirtualMachine -Module $module -VMMConnection $vmmConnection -Name $module.Params.vm_name

$hostGroup = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCVMHostGroup' `
    -Name $module.Params.host_group `
    -ObjectType 'host group' `
    -FailIfNotFound $true

try {
    $ratings = @(Get-SCVMHostRating -VM $vm -VMHostGroup $hostGroup -ErrorAction Stop)
}
catch {
    $module.FailJson("Failed to get host ratings: $($_.Exception.Message)", $_)
}

$propertyMap = @(
    @{ Param = "rating"; Property = "Rating"; Type = "int" }
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "transfer_type"; Property = "TransferType"; Type = "string" }
    @{ Param = "estimated_disk_remaining_mb"; Property = "EstimatedHostDiskSpaceRemaining"; Type = "int" }
    @{ Param = "estimated_memory_remaining_mb"; Property = "EstimatedHostMemoryRemaining"; Type = "int" }
)

$module.Result.host_ratings = @($ratings | Sort-Object -Property Rating -Descending | ForEach-Object {
        $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
        $result['host_name'] = if ($null -ne $_.VMHost) { [string]$_.VMHost.FQDN } else { $null }
        $result['zero_rating_reasons'] = @($_.ZeroRatingReasonList | ForEach-Object { [string]$_ })
        $result['warnings'] = @($_.WarningReasonList | ForEach-Object { [string]$_ })
        $result
    })

$module.ExitJson()
