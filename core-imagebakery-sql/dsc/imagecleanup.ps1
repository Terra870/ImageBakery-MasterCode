configuration imagecleanup
{
    param (
        [string[]] $computername
        #[string[]] $imagetype
    )
    
    Node $computername
    {
        # Configure Disk volumes
        Script imagecleanup
        {
            SetScript = {
                Function Invoke-DISM1{
                    Write-Verbose -Message "Running DISM to clean old servicepack files" 
                    $ErrorActionPreference = 'Stop'
                    Try{
                        $DISMResult = dism.exe /online /cleanup-Image /spsuperseded
                        $ErrorActionPreference = 'Continue'
                    }
                    Catch [System.Exception]{
                        $ErrorActionPreference = 'Continue'
                        $DISMResult = $False
                    }
                    $ErrorActionPreference = 'Continue'
                    If($DISMResult -match 'The operation completed successfully'){
                        Write-Verbose "DISM Completed Successfully." 
                    }
                    Else{
                        Write-Verbose -Message "Unable to clean old ServicePack Files." 
                    }
                }

                Function Clear-Recyclebin{
                    [CmdletBinding()]
                    Param
                    (
                        $RetentionTime = "0"
                    )
                    Try{
                       $Shell = New-Object -ComObject Shell.Application
                       $Recycler = $Shell.NameSpace(0xa)
                       $Recycler.Items() 
                       foreach($item in $Recycler.Items())
                        {
                         $DeletedDate = $Recycler.GetDetailsOf($item,2) -replace "\u200f|\u200e","" #Invisible Unicode Characters
                         $DeletedDatetime = Get-Date $DeletedDate 
                         [Int]$DeletedDays = (New-TimeSpan -Start $DeletedDatetime -End $(Get-Date)).Days
                         If($DeletedDays -ge $RetentionTime)
                          {
                           Remove-Item -Path $item.Path -Confirm:$false -Recurse -ErrorAction SilentlyContinue
                          }
                        }
                       }
                    Catch [System.Exception]{
                       $RecyclerError = $true
                       }
                    Finally{
                       If($RecyclerError -eq $true){
                           Write-Verbose -Message "Unable to delete some items in the Recycle Bin."
                           }
                       Else{
                          Write-Verbose -Message "All recycler items older than $RetentionTime days were deleted"
                           }
                        }    
                }

                Function Clear-SoftwareDistribution{
                    Write-Verbose -Message "Deleting files from 'C:\Windows\SoftwareDistribution\'"
                        Try{
                            Get-Service -Name wuauserv | Stop-Service -Force -ErrorAction Stop
                            $WUpdateError = $false
                        }
                        Catch [System.Exception]{
                            $WUpdateError = $true
                        }
                        Finally{
                            If($WUpdateError -eq $False){
                                Get-ChildItem "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -force -recurse -ErrorAction SilentlyContinue    
                                Get-Service -Name wuauserv | Start-Service
                                Write-Verbose -Message "Files Deleted Successfully" 
                            }
                            Else{
                                Get-Service -Name wuauserv | Start-Service
                                Write-Verbose -Message "Unable to stop the windows update service. No files were deleted."
                            }
                        }
                }
                
                Write-Verbose -Message "Execute cleanup script"
                Remove-Item -Path "C:\windows\Temp\*" -recurse -confirm:$false -ErrorAction SilentlyContinue
                #Remove-Item -Path "C:\Temp\*" -recurse -confirm:$false -force -ErrorAction SilentlyContinue
                Remove-Item -Path "C:\ProgramData\Microsoft\Windows\WER\ReportArchive\*" -recurse -confirm:$false -ErrorAction SilentlyContinue
                Remove-Item -Path "C:\ProgramData\Microsoft\Windows\WER\ReportQueue\*" -recurse -confirm:$false -ErrorAction SilentlyContinue
                #Remove-Item -Path "C:\ServiceProfiles\LocalService\AppData\Local\Temp\*" -recurse -confirm:$false -force -ErrorAction SilentlyContinue

                Write-Verbose -Message "Moving File to C:\Windows\System32\Sysprep\ folder"
                #Write-Verbose -Message "Image Type Variable - $imagetype and $using:imagetype"
                #Copy-Item -Path "C:\fidelity\AnswerFiles\${imagetype}\Unattend.xml" -Destination "C:\Windows\System32\Sysprep\" -Force -PassThru
                Copy-Item -Path "D:\fidelity\Scripts\Sysprep.bat" -Destination "C:\Windows\System32\Sysprep\" -confirm:$false -Force
                
                Remove-Item -Path "C:\fidelity\*" -recurse -Force -confirm:$false
                Remove-Item -Path "D:\fidelity\*" -recurse -Force -confirm:$false

                Invoke-DISM1 
                # Invoke-DISM2 
                
                Clear-SoftwareDistribution #-ComputerOBJ $ComputerOBJ
                Clear-Recyclebin #-ComputerOBJ $ComputerOBJ
                #Write-Verbose -Message "Running SysPrep"
                #CMD /C "C:\Windows\System32\Sysprep\Sysprep.bat"
            }
            GetScript = {
                $fileexist = Test-Path -path $env:SystemDrive\Windows\System32\Sysprep\Unattend.xml
                Return @{
                    'filestat' = $fileexist 
                }
            }
            TestScript = { 
                If (Test-Path -path $env:SystemDrive\Windows\System32\Sysprep\sysprep.bat) {
                    # EMET is installed and return true
                    Write-Verbose -Message "Unattend.xml is present in system32 folder"
                    Return $True
                } else {
                    Write-Verbose -Message "Unattend File is not present, Please run image cleanup script"
                    Return $False
                }
            }
        }
    }
}