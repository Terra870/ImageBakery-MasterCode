configuration diskconfiguration
{
    param (
        [string[]] $computername
    )
    
    Node $computername
    {
        Script diskconfiguration
        {
            SetScript = {
                #$disks = (Get-Disk | Where-Object partitionstyle -eq 'raw' | sort number)
                Write-Verbose "Configure Mount Point"
                $disk = Get-Disk 9 | Where-Object partitionstyle -eq 'raw'
                if ($disk) {
                    $disk | Initialize-Disk -PartitionStyle MBR
                    $disk | New-Partition -UseMaximumSize -MbrType IFS 
                    $Partition = Get-Partition -DiskNumber $disk.Number
                    $Partition | Format-Volume -FileSystem NTFS -AllocationUnitSize 65536 -Confirm:$false -Force

                    $letters = 70..89 | ForEach-Object { [char]$_ }
                    $driveLetter = $letters[0].ToString()
                    $Partition | Add-PartitionAccessPath -AccessPath "${driveLetter}:"
                    Write-Verbose -Verbose "Mount Point Drive Latter ${driveLetter}:"
                    [Environment]::SetEnvironmentVariable("mountpointdrive", "${driveLetter}", "Machine")
                    $mountpointdrive=$driveLetter
                    Write-Verbose -Verbose "Set environment variable mountpointdrive as ${mountpointdrive}"
                }

                Write-Verbose "Configure SQL SystemDB Disks"
                $disk = Get-Disk 8 | Where-Object partitionstyle -eq 'raw'
                if ($disk) {
                    $disk | Initialize-Disk -PartitionStyle MBR
                    $disk | New-Partition -UseMaximumSize -MbrType IFS
                    $Partition = Get-Partition -DiskNumber $disk.Number
                    Set-Partition -DiskNumber $disk.Number -PartitionNumber $Partition.PartitionNumberber `
                        -NoDefaultDriveLetter $true -IsHidden $true
                    $Partition | Format-Volume -FileSystem NTFS -AllocationUnitSize 65536 -Confirm:$false -Force

	                $mountpointpath="${mountpointdrive}:\SQLSystemDB01"
                    Write-Verbose -Verbose $mountpointpath
                    Get-PSDrive -PSProvider FileSystem | Out-Null
                    New-Item -ItemType directory -Path $mountpointpath -Confirm:$false -force 
                    $Partition | Add-PartitionAccessPath -AccessPath $mountpointpath
                }
                
                Write-Verbose "Configure SQL TempDB Data Disk"
                $disk = Get-Disk 7 | Where-Object partitionstyle -eq 'raw'
                if ($disk) {              
                    $disk | Initialize-Disk -PartitionStyle MBR
                    $disk | New-Partition -UseMaximumSize -MbrType IFS
                    $Partition = Get-Partition -DiskNumber $disk.Number
                    Set-Partition -DiskNumber $disk.Number -PartitionNumber $Partition.PartitionNumberber `
                        -NoDefaultDriveLetter $true -IsHidden $true
                    $Partition | Format-Volume -FileSystem NTFS -AllocationUnitSize 65536 -Confirm:$false -Force
                    New-Item -ItemType directory -Path "${mountpointdrive}:\SQLTempDBData01"
                    $Partition | Add-PartitionAccessPath -AccessPath "${mountpointdrive}:\SQLTempDBData01"
                }

                Write-Verbose "Configure SQL TempDB Log Disk"
                $disk = Get-Disk 6 | Where-Object partitionstyle -eq 'raw'
                if ($disk) {
                    $disk | Initialize-Disk -PartitionStyle MBR
                    $disk | New-Partition -UseMaximumSize -MbrType IFS
                    $Partition = Get-Partition -DiskNumber $disk.Number
                    Set-Partition -DiskNumber $disk.Number -PartitionNumber $Partition.PartitionNumberber `
                        -NoDefaultDriveLetter $true -IsHidden $true
                    $Partition | Format-Volume -FileSystem NTFS -AllocationUnitSize 65536 -Confirm:$false -Force
                    New-Item -ItemType directory -Path "${mountpointdrive}:\SQLTempDBLogs01"
                    $Partition | Add-PartitionAccessPath -AccessPath "${mountpointdrive}:\SQLTempDBLogs01"
                }

                Write-Verbose "Configure SQL UserDB Data Disk"
                $disk = Get-Disk 5 | Where-Object partitionstyle -eq 'raw'
                if ($disk) {
                    $disk | Initialize-Disk -PartitionStyle MBR
                    $disk | New-Partition -UseMaximumSize -MbrType IFS
                    $Partition = Get-Partition -DiskNumber $disk.Number
                    Set-Partition -DiskNumber $disk.Number -PartitionNumber $Partition.PartitionNumberber `
                        -NoDefaultDriveLetter $true -IsHidden $true
                    $Partition | Format-Volume -FileSystem NTFS -AllocationUnitSize 65536 -Confirm:$false -Force
                    New-Item -ItemType directory -Path "${mountpointdrive}:\SQLUserDBData01"
                    $Partition | Add-PartitionAccessPath -AccessPath "${mountpointdrive}:\SQLUserDBData01"
                }

                Write-Verbose "Configure SQL UserDB Logs Disk"
                $disk = Get-Disk 4 | Where-Object partitionstyle -eq 'raw'
                if ($disk) {
                    $disk | Initialize-Disk -PartitionStyle MBR
                    $disk | New-Partition -UseMaximumSize -MbrType IFS
                    $Partition = Get-Partition -DiskNumber $disk.Number
                    Set-Partition -DiskNumber $disk.Number -PartitionNumber $Partition.PartitionNumberber `
                        -NoDefaultDriveLetter $true -IsHidden $true
                    $Partition | Format-Volume -FileSystem NTFS -AllocationUnitSize 65536 -Confirm:$false -Force

                    New-Item -ItemType directory -Path "${mountpointdrive}:\SQLUserDBLogs01"
                    $Partition | Add-PartitionAccessPath -AccessPath "${mountpointdrive}:\SQLUserDBLogs01"
                }

                Write-Verbose "Configure SQL SQLBackup Disk"
                $disk = Get-Disk 3 | Where-Object partitionstyle -eq 'raw'
                if ($disk) {
                    $disk | Initialize-Disk -PartitionStyle MBR
                    $disk | New-Partition -UseMaximumSize -MbrType IFS
                    $Partition = Get-Partition -DiskNumber $disk.Number
                    Set-Partition -DiskNumber $disk.Number -PartitionNumber $Partition.PartitionNumberber `
                        -NoDefaultDriveLetter $true -IsHidden $true
                    $Partition | Format-Volume -FileSystem NTFS -AllocationUnitSize 65536 -Confirm:$false -Force 
                    New-Item -ItemType directory -Path "${mountpointdrive}:\SQLBackups01"
                    $Partition | Add-PartitionAccessPath -AccessPath "${mountpointdrive}:\SQLBackups01"
                }

                Write-Verbose "Configure SQL Installation Disk"
                $disk = Get-Disk 2 | Where-Object partitionstyle -eq 'raw'
                if ($disk) {
                    $disk | Initialize-Disk -PartitionStyle MBR
                    $disk | New-Partition -UseMaximumSize -MbrType IFS
                    $Partition = Get-Partition -DiskNumber $Disk.Number
                    $Partition | Format-Volume -FileSystem NTFS -AllocationUnitSize 65536 -Confirm:$false -Force

                    $sqlinstalldriveletter = $letters[1].ToString()
                    $Partition | Add-PartitionAccessPath -AccessPath "${sqlinstalldriveletter}:"
                    Write-Verbose -Verbose "Mount Point Drive Latter ${sqlinstalldriveletter}:"
                    [Environment]::SetEnvironmentVariable("sqlinstalldrive", "${sqlinstalldriveletter}", "Machine")
                    start-sleep -Seconds 5
                    $sqlinstalldrive=[Environment]::GetEnvironmentVariable("sqlinstalldrive","Machine")
                    Write-Verbose -Verbose "Set environment variable mountpointdrive as ${sqlinstalldrive}"
                }    
               
            }

            GetScript = {
                $disks = (Get-Disk | Where-Object partitionstyle -eq 'raw'| Sort-Object number)
                Return @{
                    'diskstatus' = $disks
                }
            }

            TestScript = { 
                $disks = Get-Disk | Where-Object partitionstyle -eq 'raw' | Sort-Object number
                
                If (($disks.Number).count -eq 0) {
                    # Raw disks are there and need to configure
                    Return $True
                }
                # Disk already configured
                Return $False
            }
        }
    }
}