function Format-AnsiColor {
[CmdletBinding()]
[OutputType([String])]
param(
    [Parameter(
        Mandatory = $true,
        ValueFromPipeline = $true
    )]
    [AllowEmptyString()]
    [String]
    $Message ,

    [Parameter()]
    [ValidateSet(
         'normal display'
        ,'bold'
        ,'underline (mono only)'
        ,'blink on'
        ,'reverse video on'
        ,'nondisplayed (invisible)'
    )]
    [Alias('attribute')]
    [String]
    $Style ,

    [Parameter()]
    [ValidateSet(
         'black'
        ,'red'
        ,'green'
        ,'yellow'
        ,'blue'
        ,'magenta'
        ,'cyan'
        ,'white'
    )]
    [Alias('fg')]
    [String]
    $ForegroundColor ,

    [Parameter()]
    [ValidateSet(
         'black'
        ,'red'
        ,'green'
        ,'yellow'
        ,'blue'
        ,'magenta'
        ,'cyan'
        ,'white'
    )]
    [Alias('bg')]
    [String]
    $BackgroundColor
)

    Begin {
        $e = [char]27

        $attrib = @{
            'normal display' = 0
            'bold' = 1
            'underline (mono only)' = 4
            'blink on' = 5
            'reverse video on' = 7
            'nondisplayed (invisible)' = 8
        }

        $fore = @{
            black = 30
            red = 31
            green = 32
            yellow = 33
            blue = 34
            magenta = 35
            cyan = 36
            white = 37
        }

        $back = @{
            black = 40
            red = 41
            green = 42
            yellow = 43
            blue = 44
            magenta = 45
            cyan = 46
            white = 47
        }
    }

    Process {
        $formats = @()
        if ($Style) {
            $formats += $attrib[$Style]
        }
        if ($ForegroundColor) {
            $formats += $fore[$ForegroundColor]
        }
        if ($BackgroundColor) {
            $formats += $back[$BackgroundColor]
        }
        if ($formats) {
            $formatter = "$e[$($formats -join ';')m"
        }

       $Timestamp = Get-Date
       $Jenkins = $env:Jenkins
       If ($Jenkins) {"$formatter$Timestamp ::: $message"} 
       Else 
       {
           $Console_Message = "$Timestamp ::: $Message"
           if ($ForegroundColor) {
                if ($BackgroundColor) {
                    Write-Host $Console_Message -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
                }
                Else {
                    Write-Host $Console_Message -ForegroundColor $ForegroundColor
                    }
                }
            Else {
                if ($BackgroundColor) {
                    Write-Host $Console_Message -BackgroundColor $BackgroundColor
                }
                           
            Write-Host $console_message
            }
        }
       <#
       #Looging the Information to the Log File
       $LogEntry = "$Timestamp ::: $message"
       $LogEntry | Out-File -FilePath $logfile -Append
       #>
    }
}