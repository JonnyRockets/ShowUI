## Add-EventHandler is deprecated because the compiled Register-BootsEvent is a better way
function Add-EventHandler {
    <#
    .Synopsis
        Adds an event handler to an object
    .Description
        Adds an event handler to an object.  If the object has a 
        resource dictionary, it will add an eventhandlers 
        hashtable to that object and it will store the event handler,
        so it can be removed later.
    .Example
        $window = New-Window
        $window | Add-EventHandler Loaded { $this.Top = 100 }
    .Parameter Object
        The Object to add an event handler to
    .Parameter EventName
        The name of the event (i.e. Loaded)
    .Parameter Handler
        The script that will handle the event. Will accept a ScriptBlock or the names of scripts or functions
    .Parameter PassThru 
        If this is set, the delegate that is added to the object will
        be returned from the function.
    #>
    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$true, Position=0)]
    [String]
    $EventName,

    [Parameter(Mandatory=$true, Position=1)]
    $Handler,
    
    [Parameter(ValueFromPipeline=$true, Mandatory=$true)]
    $InputObject,

        
    [Switch]
    $PassThru  
    )
    
    process {
        if ($EventName.StartsWith("On_")) {
            $EventName = $EventName.Substring(3)
        }

        if($Handler -IsNot [ScriptBlock]) {
            $Handler = (Get-Command $Handler -CommandType Function,ExternalScript).ScriptBlock
        }
    
        ## Validate the existence of the event:
        $Event = $InputObject.GetType().GetEvent($EventName, [Reflection.BindingFlags]"IgnoreCase, Public, Instance")
        if (-not $Event) {
            throw "Handler $EventName does not exist on $InputObject"
        }
        
        # WAS: Invoke-Expression "`$DObject.$EventName( {$($sb.GetNewClosure())} )" 
        $InputObject."Add_$EventName".Invoke( @($Handler.GetNewClosure()) );
         
        #  ## This is what WPK was doing ...
        #  ## Get the type
        #  $handlerType = $event.GetAddMethod().GetParameters()[0].ParameterType
        #  ## Make a scriptblock handler with a $Extra trap{ } block
        #  $realHandler = ([ScriptBlock]::Create(" $Handler `ntrap { Write-Error `$_ }")) -as $HandlerType
        #  ## Stuff a reference to it into the object's resources (so you can remove it later)
        #  if ($InputObject.Resources) {
        #      if (-not $InputObject.Resources.EventHandlers) {
        #          $InputObject.Resources.EventHandlers = @{}
        #      }
        #      $InputObject.Resources.EventHandlers."On_$EventName" = $realHandler
        #  }
        #  ## Finally, add the actual handler
        #  $InputObject."add_$($Event.Name)".Invoke(@($realHandler))
        if ($passThru) {
            $Handler
        }
    }
} 

# SIG # Begin signature block
# MIIIDQYJKoZIhvcNAQcCoIIH/jCCB/oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQURQcPtMkJwbuoz0J82GP6q+Kd
# /oKgggUrMIIFJzCCBA+gAwIBAgIQKQm90jYWUDdv7EgFkuELajANBgkqhkiG9w0B
# AQUFADCBlTELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAlVUMRcwFQYDVQQHEw5TYWx0
# IExha2UgQ2l0eTEeMBwGA1UEChMVVGhlIFVTRVJUUlVTVCBOZXR3b3JrMSEwHwYD
# VQQLExhodHRwOi8vd3d3LnVzZXJ0cnVzdC5jb20xHTAbBgNVBAMTFFVUTi1VU0VS
# Rmlyc3QtT2JqZWN0MB4XDTEwMDUxNDAwMDAwMFoXDTExMDUxNDIzNTk1OVowgZUx
# CzAJBgNVBAYTAlVTMQ4wDAYDVQQRDAUwNjg1MDEUMBIGA1UECAwLQ29ubmVjdGlj
# dXQxEDAOBgNVBAcMB05vcndhbGsxFjAUBgNVBAkMDTQ1IEdsb3ZlciBBdmUxGjAY
# BgNVBAoMEVhlcm94IENvcnBvcmF0aW9uMRowGAYDVQQDDBFYZXJveCBDb3Jwb3Jh
# dGlvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMfUdxwiuWDb8zId
# KuMg/jw0HndEcIsP5Mebw56t3+Rb5g4QGMBoa8a/N8EKbj3BnBQDJiY5Z2DGjf1P
# n27g2shrDaNT1MygjYfLDntYzNKMJk4EjbBOlR5QBXPM0ODJDROg53yHcvVaXSMl
# 498SBhXVSzPmgprBJ8FDL00o1IIAAhYUN3vNCKPBXsPETsKtnezfzBg7lOjzmljC
# mEOoBGT1g2NrYTq3XqNo8UbbDR8KYq5G101Vl0jZEnLGdQFyh8EWpeEeksv7V+YD
# /i/iXMSG8HiHY7vl+x8mtBCf0MYxd8u1IWif0kGgkaJeTCVwh1isMrjiUnpWX2NX
# +3PeTmsCAwEAAaOCAW8wggFrMB8GA1UdIwQYMBaAFNrtZHQUnBQ8q92Zqb1bKE2L
# PMnYMB0GA1UdDgQWBBTK0OAaUIi5wvnE8JonXlTXKWENvTAOBgNVHQ8BAf8EBAMC
# B4AwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcDAzARBglghkgBhvhC
# AQEEBAMCBBAwRgYDVR0gBD8wPTA7BgwrBgEEAbIxAQIBAwIwKzApBggrBgEFBQcC
# ARYdaHR0cHM6Ly9zZWN1cmUuY29tb2RvLm5ldC9DUFMwQgYDVR0fBDswOTA3oDWg
# M4YxaHR0cDovL2NybC51c2VydHJ1c3QuY29tL1VUTi1VU0VSRmlyc3QtT2JqZWN0
# LmNybDA0BggrBgEFBQcBAQQoMCYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmNv
# bW9kb2NhLmNvbTAhBgNVHREEGjAYgRZKb2VsLkJlbm5ldHRAWGVyb3guY29tMA0G
# CSqGSIb3DQEBBQUAA4IBAQAEss8yuj+rZvx2UFAgkz/DueB8gwqUTzFbw2prxqee
# zdCEbnrsGQMNdPMJ6v9g36MRdvAOXqAYnf1RdjNp5L4NlUvEZkcvQUTF90Gh7OA4
# rC4+BjH8BA++qTfg8fgNx0T+MnQuWrMcoLR5ttJaWOGpcppcptdWwMNJ0X6R2WY7
# bBPwa/CdV0CIGRRjtASbGQEadlWoc1wOfR+d3rENDg5FPTAIdeRVIeA6a1ZYDCYb
# 32UxoNGArb70TCpV/mTWeJhZmrPFoJvT+Lx8ttp1bH2/nq6BDAIvu0VGgKGxN4bA
# T3WE6MuMS2fTc1F8PCGO3DAeA9Onks3Ufuy16RhHqeNcMYICTDCCAkgCAQEwgaow
# gZUxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJVVDEXMBUGA1UEBxMOU2FsdCBMYWtl
# IENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEhMB8GA1UECxMY
# aHR0cDovL3d3dy51c2VydHJ1c3QuY29tMR0wGwYDVQQDExRVVE4tVVNFUkZpcnN0
# LU9iamVjdAIQKQm90jYWUDdv7EgFkuELajAJBgUrDgMCGgUAoHgwGAYKKwYBBAGC
# NwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUZUYLtpr4
# TDVpa1OinWhHAmDOO6swDQYJKoZIhvcNAQEBBQAEggEAM+0/qN8zi8l4bVpbiWxX
# gHy8CnrVCc7AKh9IzC4JYdyqsIQniXc1vMoBQFSgkY/se4aVnzWssLH8rXqupS+K
# NO+VCcfQTF9OgURlejhBiXIrJHhY3w4B2oxj+SNuKcHRMGrflX+X9KFvRKXSSA+D
# Bwt+dNBNd5LK04wfLrGfbggkM0dDEUH+6YTud5/Q2tiAUJ45CQCpn+Tz49LqWuz6
# 9FBKQnp8mYVruvo2s+4WE75Z2zPV7BMD/5rqSJRlhGPPuWxmzGhAph/OQoytx8n9
# /B2baPlbGj5xe6JlaBEI9Kd5pv/txcJeW1JhR9i0cHEXZNeE2XdjcpsygylbilpG
# 6A==
# SIG # End signature block
