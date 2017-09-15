$user = 'administrator@vsphere.local'
$pswd = 'HomeLab2017!'
$vcsa = 'vcsa.local.lab'

Connect-rViServer -User $user -Password $pswd -Server $vcsa -Verbose

Get-rVMHost

Get-rProxyConfig | fc -Depth 2
