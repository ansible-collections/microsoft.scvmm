#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str' }
        member = @{
            type = 'str'
            choices = @(
                'VM', 'Template', 'VMHost', 'HostCluster', 'VMHostGroup',
                'ServiceTemplate', 'ServiceInstance', 'ComputerTier', 'Cloud',
                'ProtectionUnit'
            )
        }
        vmm_server = @{ type = 'str' }
    }
    mutually_exclusive = @(, @('name', 'member'))
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

try {
    if ($module.Params.name) {
        $customProperties = @(Get-SCCustomProperty -VMMServer $vmmConnection -Name $module.Params.name -ErrorAction Stop)
    }
    elseif ($module.Params.member) {
        $customProperties = @(Get-SCCustomProperty -VMMServer $vmmConnection -Member $module.Params.member -ErrorAction Stop)
    }
    else {
        $customProperties = @(Get-SCCustomProperty -VMMServer $vmmConnection -ErrorAction Stop)
    }
}
catch {
    $module.FailJson("Failed to query custom properties: $($_.Exception.Message)", $_)
}

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "description"; Property = "Description"; Type = "string" }
)

$module.Result.custom_properties = @($customProperties | ForEach-Object {
        $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
        $members = @()
        foreach ($member in $_.Members) {
            $members += $member.ToString()
        }
        $result['member_types'] = @($members | Sort-Object)
        $result
    })

$module.ExitJson()
