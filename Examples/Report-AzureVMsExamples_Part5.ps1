param (
	$ReportOutputPath
)

Import-Module ReportHtml
Get-Command -Module ReportHtml

if (!$ReportOutputPath) 
{
	$ReportOutputPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
} 
$ReportName = "Azure VMs"

# see if we already have a session. If we don't, re-authN
if (!$AzureRMAccount.Context.Tenant) {
    $AzureRMAccount = Add-AzureRmAccount 		
}

# Get arrary of VMs from ARM
$RMVMs = get-azurermvm

$RMVMArray = @() ; $TotalVMs = $RMVMs.Count; $i =1 
# Loop through VMs
foreach ($vm in $RMVMs)
{
  # Tracking progress
  Write-Progress -PercentComplete ($i / $TotalVMs * 100) -Activity "Building VM array" -CurrentOperation  ($vm.Name + " in resource group " + $vm.ResourceGroupName)
    
  # Get VM Status (for Power State)
  $vmStatus = Get-AzurermVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Status

  # Generate Array
  $RMVMArray += New-Object PSObject -Property @{`

    # Collect Properties
   	ResourceGroup = $vm.ResourceGroupName
	ID = $VM.id
	Name = $vm.Name;
    PowerState = (get-culture).TextInfo.ToTitleCase(($vmStatus.statuses)[1].code.split("/")[1]);
    Location = $vm.Location;
    Tags = $vm.Tags
    Size = $vm.HardwareProfile.VmSize;
    ImageSKU = $vm.StorageProfile.ImageReference.Sku;
    OSType = $vm.StorageProfile.OsDisk.OsType;
    OSDiskSizeGB = $vm.StorageProfile.OsDisk.DiskSizeGB;
    DataDiskCount = $vm.StorageProfile.DataDisks.Count;
    DataDisks = $vm.StorageProfile.DataDisks;
    }
	$i++
}
  
Function Test-Report 
{
	param (
		$TestName
	)
	$rptFile = join-path $ReportOutputPath ($ReportName.replace(" ","") + "-$TestName" + ".mht")
	$rpt | Set-Content -Path $rptFile -Force
	Invoke-Item $rptFile
	sleep 1
}


####### Example 15 ########
$rpt = @()
$rpt += Get-HtmlOpen -TitleText ($ReportName + "Example 15")

$rpt += Get-HtmlContentOpen -BackgroundShade 2 -HeaderText "VM States" 

$rpt += get-htmlcolumn1of2 
$rpt += Get-HtmlContentOpen -BackgroundShade 1 -HeaderText Deallocated
$rpt += Get-HtmlContentTable  ($RMVMArray  | where {$_.PowerState -eq "Deallocated"} | select ResourceGroup, Name, Size,  DataDiskCount, ImageSKU) 
$rpt += Get-HtmlContentClose
$rpt += get-htmlcolumnclose

$rpt += get-htmlcolumn2of2
$rpt += Get-HtmlContentOpen -BackgroundShade 1 -HeaderText Running
$rpt += Get-HtmlContentTable ($RMVMArray | where {$_.PowerState -eq "Running"} | select ResourceGroup, Name, Size,  DataDiskCount, ImageSKU  )
$rpt += Get-HtmlContentClose
$rpt += get-HtmlColumnClose
$rpt += Get-HtmlContentClose

$rpt += Get-HtmlContentOpen -HeaderText 'Alternating Row Color'
$rpt += Get-HtmlContentTable (Set-TableRowColor ($RMVMArray | select ResourceGroup, Name, Location, Size, ImageSKU )-Alternating)
$rpt += Get-HtmlContentclose

$rpt += Get-HtmlContentClose

$rpt += Get-HtmlClose
 
Test-Report -TestName Example15

Invoke-Item $ReportOutputPath
