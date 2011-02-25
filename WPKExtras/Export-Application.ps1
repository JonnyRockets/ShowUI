function Export-Application
{
    <#
    .Synopsis
        Exports a PowerShell script into an executable
    .Description
        Embeds the specified script code into an execuable such that the executable can be run as a simple application which invokes the powershell script.
        This is merely a packaging convenience, as essentially the same effect can be achieved by running PowerShell with the -EncodedCommand parameter.
    .Example
        # Creates an .exe at the current path that runs digitalclock.ps1
        $clock = Get-Command $env:UserProfile\Documents\WindowsPowerShell\Modules\WPK\Examples\DigitalClock.ps1
        $clock | Export-Application 
    .Parameter Command
        The Command to turn into an application.
        The command should either be a function or an external script
    .Parameter Name
        The name of the .EXE to produce.  By default, the name will be the command name with an .EXE extension instead of a .PS1 extension
    .Parameter ReferencedAssemblies
        Additional Assemblies to Reference when compiling.
    .Parameter OutputPath
        If set, will output the executable into this path.
        By default, executables are outputted to the current directory.
    .Parameter TopModule
        The top level module to import.
        By default, this is the module that is exporting Export-Application
    #>
    param(
    [Parameter(ValueFromPipeline=$true)]
    [Management.Automation.CommandInfo]
    $Command,    
    [string]
    $Name,    
    [Reflection.Assembly[]]
    $ReferencedAssemblies = @(),
    [String]$OutputPath,
    [switch]$DoNotEmbed,
    [string]$TopModule = $myInvocation.MyCommand.ModuleName 
    ) 

    process {       
        $optimize = $true
        Set-StrictMode -Off
        if (-not $name) {
            $name = $command.Name
            if ($name -like "*.ps1") {
                $name = $name.Substring(0, $name.LastIndexOf("."))
            }
        }
        
        $referencedAssemblies+= [PSObject].Assembly
        $referencedAssemblies+= [Windows.Window].Assembly
        $referencedAssemblies+= [System.Windows.Threading.DispatcherFrame].Assembly
        $referencedAssemblies+= [System.Windows.Media.Brush].Assembly
        
        if (-not $outputPath)  {
            $outputPath = "$name.exe"
        }
        
        $initializeChunk = ""
        foreach ($r in $referencedAssemblies) {
            if ($r -notlike "*System.Management.Automation*") {
                $initializeChunk += "
          #      [Reflection.Assembly]::LoadFrom('$($r.Location)')
                "
            }
        }
        
        if ($optimize) {
            $iss = [Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
            $builtInCommandNames = $iss.Commands | 
                Where-Object { $_.ImplementingType } | 
                Select-Object -ExpandProperty Name         

            $aliases = @{}
            $outputChunk = "" 
            $command | 
                Get-ReferencedCommand | 
                ForEach-Object {
                    if ($_ -is [Management.Automation.AliasInfo]) {
                        $aliases.($_.Name) = $_.ResolvedCommand
                        $_.ResolvedCommand
                    }
                    $_        
                } | Foreach-Object {
                    if ($_ -is [Management.Automation.CmdletInfo]) {
                        if ($builtInCommandNames -notcontains $_.Name) {
                            $outputChunk+= "
                            Import-Module '$($_.ImplementingType.Assembly.Location)'
                            "
                        }
                    }
                    $_        
                } | ForEach-Object {
                    if ($_ -is [Management.Automation.FunctionInfo]) {
                        $outputChunk += "function $($_.Name) {
                            $($_.Definition)
                        }
                        "
                    }
                }
                
                $outputChunk += $aliases.GetEnumerator() | ForEach-Object {
                    "
                    Set-Alias $($_.Key) $($_.Value)
                    "
                }                
            $initializeChunk += $outputChunk
        } else {
            $initializeChunk += "
            Import-Module '$topModule'
            "
        }
        if (-not $DoNotEmbed) {
            if ($command.ScriptContents) {
                $base64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command.ScriptContents))
            } else {
                if ($command.Definition) {
                    $base64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command.Definition))
                }
            }
            $argsSection = @"
                sb.Append(System.Text.Encoding.Unicode.GetString(Convert.FromBase64String("$base64")));
"@        
        } else {
            $argsSection = @'
                if (args.Length == 2) {
                    if (String.Compare(args[0],"-encoded", true) == 0) {
                        sb.Append(System.Text.Encoding.Unicode.GetString(Convert.FromBase64String(args[1])));
                    }
                } else {
                    foreach (string a in args) {
                        sb.Append(a);
                        sb.Append(" ");                
                    }            
                }
'@        
        }
        
        $initBase64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($initializeChunk))
        
      
        $applicationDefinition = @"
    
    using System;
    using System.Text;
    using System.Management.Automation;
    using System.Management.Automation.Runspaces;
        
    public static class $name {
        public static void Main(string[] args) {
            StringBuilder sb = new StringBuilder();

            $argsSection

            PowerShell psCmd = PowerShell.Create();
            Runspace rs = RunspaceFactory.CreateRunspace();
            rs.ApartmentState = System.Threading.ApartmentState.STA;
            rs.ThreadOptions = PSThreadOptions.ReuseThread;
            rs.Open();
            psCmd.Runspace =rs;
            psCmd.AddScript(Encoding.Unicode.GetString(Convert.FromBase64String("$initBase64")), false).Invoke();
            psCmd.Invoke();            
            psCmd.Commands.Clear();           
            psCmd.AddScript(sb.ToString());
            try {
                psCmd.Invoke();
            } catch (Exception ex) {
                System.Windows.MessageBox.Show(ex.Message, ex.GetType().FullName);                
                rs.Close();
                rs.Dispose();     
            }
            foreach (ErrorRecord err in psCmd.Streams.Error) {
                System.Windows.MessageBox.Show(err.ToString());
            }
            rs.Close();
            rs.Dispose();                        
        }
    }   
"@   
        Write-Verbose $applicationDefinition
        Add-Type $applicationDefinition -IgnoreWarnings -ReferencedAssemblies $referencedAssemblies `
            -OutputAssembly $outputPath -OutputType WindowsApplication
    }
}
# SIG # Begin signature block
# MIIIDQYJKoZIhvcNAQcCoIIH/jCCB/oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUjq8rTjxcQDRDjTmQ3wRhr6hd
# MZmgggUrMIIFJzCCBA+gAwIBAgIQKQm90jYWUDdv7EgFkuELajANBgkqhkiG9w0B
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
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUYu0nW8yB
# IIyMEq3lszSr9CJmxEcwDQYJKoZIhvcNAQEBBQAEggEANrG4XThEukVwQ9Wkg84U
# Wuvx6GrgA76UD6zH/zS2btjsollnSNMu1EmV5+etQb0f3lMGVVfYBL7qlhGBIyha
# ggAA9AfzumToMWYCZT+0Jv0VtQ1CNUQHEPKjZaHu5hUpstLH32cnVx0IVkT3ir5+
# xpjxBLXAJG/5Tk+iaFvshGPK5OPmG6t3fmCq5h89yWqWfMvCQk0XAdoqmc2d7P8L
# q4Pfki0C+bZHtw+rCGe9RI6YnD9ZmPT1l2lgwIW6CKW3iCHP8dn1yIg3eto8ifQJ
# 6r5TeIZzMK0CIagI42SwOELUAql2Kmtug+o6kTQKf535zZK0ZeijGBaLTkcKfET4
# GQ==
# SIG # End signature block
