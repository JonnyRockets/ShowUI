## Use a graphical interface to select (and pass-through) pipeline objects
## Import-Module PowerBoots

## Get the item as it would be displayed by Format-Table
function Get-StringRepresentation($object)
{
    $formatted = $object | Format-Table | Out-String
    $formatted.split("`r`n") | ? { $_ } | Select -Last 1
}

## Store the items that came from the pipeline
## $GLOBAL:items = New-Object System.Collections.ObjectModel.ObservableCollection`[Object]
## V1 compatible
$GLOBAL:items = New-Object "System.Collections.ObjectModel.ObservableCollection``1[[System.Object, mscorlib]]"
$GLOBAL:originalItems = @{}
$GLOBAL:orderedItems = New-Object System.Collections.ArrayList

## Convert input to string representations
@($input) | % {
    $stringRepresentation = Get-StringRepresentation $_
Write-Verbose $stringRepresentation
    $GLOBAL:originalItems[$stringRepresentation] = $_
    $null = $orderedItems.Add($stringRepresentation)
    $GLOBAL:items.Add($stringRepresentation)
}

## Set an attached property of an item
## (for example, the position of an element in a grid)
## You should use Set-DependencyProperty or ... just pass it to the object at creation time!!
#  function Global:SetProperty($name, $value)
#  {
    #  $element = @($input)[0]
    
    #  $class,$property = $name -split '\.'
    #  $type = [type] "System.Windows.Controls.$class"
    #  $method = "Set$property"
    #  $null = $type::$method.Invoke($element, $value)
    #  $element
#  }

## Get an item by its name
## You should use Select-BootsElement
#function GLOBAL:BootsItem($name)
#{
#    [System.Windows.LogicalTreeHelper]::FindLogicalNode($bootsWindow, $name)
#}

## Get the scriptblock of an item. This lets Boots call the
## function with correct local variables.
## BUILT IN NOW -- Just use the function name (but make sure it's GLOBAL
#function Global:Action($name)
#{
#    (Get-Command $name -CommandType Function).ScriptBlock
#}

## Send the selected items down the pipeline
function global:OK_Click
{
    $selectedItems = Select-BootsElement "Object Filter" SelectedItems
    $source = $selectedItems.Items
    
    if($selectedItems.SelectedIndex -ge 0)
    {
        $source = $selectedItems.SelectedItems
    }
    
    $source | % { $GLOBAL:originalItems[$_] } | Write-Output
    $bootsWindow.Close()
}

## Send the selected items down the pipeline
function global:SelectedItems_DoubleClick
{
    $item = $args[1].OriginalSource.DataContext
    $GLOBAL:originalItems[$item] | Write-Output
    $bootsWindow.Close()
}

## Filter selected items to what's been typed
function global:SearchText_KeyUp
{
    if($this.Text)
    {
        $items.Clear()
        try
        {
            ## If this is a regex, do a regex match
            $orderedItems | ? { $_ -match $this.Text } | % { $items.Add($_) }
        }
        catch
        {
            ## If the regex threw, do simple text match
            $items.Clear()
            $orderedItems | 
                ? { $_ -like ("*" + [System.Management.Automation.WildcardPattern]::Escape($this.Text) + "*") } |
                    % { $items.Add($_) }
        }
    }
}

## Generate the window
$result = Boots -Title "Object Filter" -MinWidth 400 -MaxWidth 1000 -Height 600 {
    GridPanel -Margin 5 -RowDefinitions @(
        RowDefinition -Height Auto
        RowDefinition -Height *
        RowDefinition -Height Auto
        RowDefinition -Height Auto
    ) {
        TextBlock {
            "Type or click to search. Press Enter or click OK to pass the items down the pipeline." 
         } | Set-DependencyProperty "Grid.Row" 0 -Passthru | Set-DependencyProperty Margin 5 -passthru
        
        ScrollViewer -Margin 5 {
            ListBox -SelectionMode Multiple -Name SelectedItems -FontFamily "Courier New" `
                -ItemsSource (,$items) -On_MouseDoubleClick  SelectedItems_DoubleClick
        }  | Set-DependencyProperty "Grid.Row" 1 -Passthru
        
        TextBox -Margin 5 -Name SearchText -On_KeyUp SearchText_KeyUp | 
           Set-DependencyProperty "Grid.Row" 2 -Passthru
        
        GridPanel -Margin 5 -HorizontalAlignment Right -ColumnDefinitions @(
            ColumnDefinition -Width 65
            ColumnDefinition -Width 10
            ColumnDefinition -Width 65
        ) {
            Button "OK" -IsDefault -Width 65 -On_Click OK_Click | Set-DependencyProperty "Grid.Column" 0 -Passthru
            Button "Cancel" -IsCancel -Width 65 | Set-DependencyProperty "Grid.Column" 2 -Passthru
        }  | Set-DependencyProperty Grid.Row 3 -Passthru
        
   } -On_Loaded { (Select-BootsElement $this SearchText).Focus() }
#   } -On_Loaded { Select-BootsElement $this SearchText | measure | out-host }
} -Popup -Async

## Don't forget to remove the window (I think I might need to do this On_Close by default)
# Remove-BootsWindow "Object Filter"

## Stream the results, rather than write them as an array
## Now implemented in New-BootsWindow
$result ## :) | % { $_ }
# SIG # Begin signature block
# MIIIDQYJKoZIhvcNAQcCoIIH/jCCB/oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGPiReWQ3JbeJcahfEIzI+zAd
# 786gggUrMIIFJzCCBA+gAwIBAgIQKQm90jYWUDdv7EgFkuELajANBgkqhkiG9w0B
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
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUh9jha/Pf
# tCGL8iqKXU2ki5ZYnfkwDQYJKoZIhvcNAQEBBQAEggEARGIHQMdJ3a4IF6aPK+S6
# rNcSlbp3HBRla5h7A7RmUBMBTxkIVr2NBTmU85K6u6EY0o+hlkxJNZb5kOj8/+3R
# G0+ykgeRnD3TfgUkR7E9Mvw8uf3h0iPesSJ9dO8tQTJO3mcodhoWdpUcwxITYI0S
# AJPdhuOV0b0jzVOW5hRAy9q7dUXHr1nSCfP0zQDUdrdNOgunHvTDdCT9wfl2KQHR
# gO0Q+V1n4ZtQ1FsI6emt8Jp4zYqoWCd3/jY0yTP8h564pAQ/PDNgrJL14cEVf6sD
# 7/y21YyEdhe5/pWa/bSBU5C9oMKryO1QvU9U7XipZeZxFFsIJd2bKuEz8K/hI3hu
# 2Q==
# SIG # End signature block
