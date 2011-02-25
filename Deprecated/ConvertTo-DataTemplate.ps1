function ConvertTo-DataTemplate
{
<#
  .Synopsis
      Converts the UIElement to a data template
  .Description
      Converts the UIElement to a data template by stripping its resources, 
      outputting the control as XAML, and enclosing within <DateTemplate> tags
  .Example
      New-Image | ConvertTo-DataTemplate @{"Source" = "MySource"} -outputXaml            
  .Example
      New-ListBox -ItemsSource { Get-Process } -ItemTemplate {
         New-StackPanel -Orientation Horizontal -Children {
            New-Label -Name ProcessName -FontSize 14 
            New-Label -Name Id -FontSize 8
         } | ConvertTo-DataTemplate -binding @{
            "ProcessName.Content" = "ProcessName"
            "Id.Content" = "Id"
         }    
      } -show            
  .Parameter control
      The UIElement to turn into a data
  .Parameter binding
      A dictionary of UIElements
  .Parameter outputXaml
      If set, will output the Xaml for the data template rather than the object
#>
PARAM(
   [Parameter(ValueFromPipeline=$true, Position=0)]
   $control
,
   [Parameter(Position=1)]
   [Hashtable]$binding
,
   [switch]$AsXaml
)
        
   process
   {
      if($control -is [ScriptBlock]) {
         $control = &$control
      } elseif($control -isnot [Windows.UIElement]) {
         throw "Control must be a UIElement or a PowerBoots ScriptBlock"
      }
      
      $control | Get-ChildControl | ForEach-Object {
         if ($_.Resources) {
            foreach ($kv in @($_.Resources.GetEnumerator())) {
               $null = $_.Resources.Remove($kv.Key)
            }
         }
      }
      $xaml = [Windows.Markup.XamlWriter]::Save($control)
      $xml = [xml]$xaml       
        
      if ($binding) {
         $binding.GetEnumerator() | ForEach-Object {
            $value = $_.Value
            if ($_.Key -like "*.*" ) {
               $chunks = $_.Key.Split(".")
               $targetName = $chunks[0]
               $bind = $chunks[1]
               $xml | Select-Xml "//*" | 
                     Where-Object { $_.Node.Name -eq $targetName } | 
                     ForEach-Object { $_.Node.SetAttribute($bind, "{Binding $value}") }
            } else {
               $property = $_.Key
               $value = $_.Value
               $xml | Select-Xml "." | ForEach-Object { @($_.Node.GetEnumerator())[0].SetAttribute($property, "{Binding $value}") }
            }
         }
      }
        
        
      $xaml = @"
<DataTemplate xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation' xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'>
   $($xml.OuterXml)
</DataTemplate>
"@
      if ($AsXaml) {
         $strWrite = New-Object IO.StringWriter
         [xml]$newXml = $xaml
         $newXml.Save($strWrite)
         return "$strWrite"
      } else {        
         [Windows.Markup.XamlReader]::Parse($xaml)
      }
   }
}
# SIG # Begin signature block
# MIIIDQYJKoZIhvcNAQcCoIIH/jCCB/oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGTJqLq2GwUKOtzTz364xwwrl
# 0/qgggUrMIIFJzCCBA+gAwIBAgIQKQm90jYWUDdv7EgFkuELajANBgkqhkiG9w0B
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
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUitugcSBt
# qvRZ2/q7dfDg7Y5+dIQwDQYJKoZIhvcNAQEBBQAEggEAtYaEl8Q2NjPM97NhYqjY
# qefnzlblIqYZgZnotexpbk+TpxKhYFR+pKpAliPigrbfb2lgS4AJQBp48h1QwwFU
# V77Wc3Vg/bfHqvcdK5LsGegPVXFQX80N9MgW2fRYrD8GvUbrQ9nxHY9j2h7P6ejt
# AmIm+tIdqKYSJguYylyjgIKzKGHOtfyW/lhCpeLW4MlvaYeZcnGuc3VrajIXhxlJ
# 1xYIMDpCFT3zN1JQ8YGvUj1GmBpNY834c27Xu5NnmPAdbT07VWj5Z6ZPlgTEzZNA
# 82CkYz+KKjffVHUvj8pvb2JlpR7wpqT0Nr0/61l/VxMXQd54tTNz7GGHlhcyGSF1
# iw==
# SIG # End signature block
