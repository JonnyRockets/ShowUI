## Select-GraphicalFilteredObject.ps1
## Use a graphical interface to select (and pass-through) pipeline objects
## by Lee Holmes (http://www.leeholmes.com/blog)

Import-Module PowerBoots

## Get the item as it would be displayed by Format-Table
function Get-StringRepresentation($object)
{
    $formatted = $object | Format-Table | Out-String
    $formatted -split '\r\n' | ? { $_ } | Select -Last 1
}

## Store the items that came from the pipeline
$GLOBAL:items = New-Object "System.Collections.ObjectModel.ObservableCollection``1[[System.Object, mscorlib]]"
$GLOBAL:originalItems = @{}
$GLOBAL:orderedItems = New-Object System.Collections.ArrayList

## Convert input to string representations
@($input) | % {
    $stringRepresentation = Get-StringRepresentation $_

    $GLOBAL:originalItems[$stringRepresentation] = $_
    $null = $orderedItems.Add($stringRepresentation)
    $GLOBAL:items.Add($stringRepresentation)
}

## Send the selected items down the pipeline
function global:OK_Click
{
    $selectedItems = Select-BootsElement "Object Filter" SelectedItems
    $source = $selectedItems.Items
    
    if($selectedItems.SelectedIndex -ge 0)
    {
        $source = $selectedItems.SelectedItems
    }

    $source | % { $GLOBAL:originalItems[$_] } | Write-BootsOutput
    $bootsWindow.Close()
}

## Send the selected items down the pipeline
function global:SelectedItems_DoubleClick
{
    $item = $args[1].OriginalSource.DataContext
    $GLOBAL:originalItems[$item] | Write-BootsOutput
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
Boots -Title "Object Filter" -MinWidth 400 -MaxWidth 1000 -Height 600 {
    GridPanel -Margin 5 -RowDefinitions @(
        RowDefinition -Height Auto
        RowDefinition -Height *
        RowDefinition -Height Auto
        RowDefinition -Height Auto
    ) {
        TextBlock -Margin 5 -Row 0 {
            "Type or click to search. Press Enter or click OK to pass the items down the pipeline." }
        
        ScrollViewer -Margin 5 -Row 1 {
            ListBox -SelectionMode Multiple -Name SelectedItems -FontFamily "Courier New" `
                -ItemsSource (,$items) -On_MouseDoubleClick  SelectedItems_DoubleClick
        } 
        
        TextBox -Margin 5 -Name SearchText -On_KeyUp SearchText_KeyUp -Row 2
        
        GridPanel -Margin 5 -HorizontalAlignment Right -ColumnDefinitions @(
            ColumnDefinition -Width 65
            ColumnDefinition -Width 10
            ColumnDefinition -Width 65
        ) {
            Button "OK" -IsDefault -Width 65 -On_Click OK_Click -"Grid.Column" 0
            Button "Cancel" -IsCancel -Width 65 -"Grid.Column" 2
        } -"Grid.Row" 3 -Passthru
        
   } -On_Loaded { (Select-BootsElement $this SearchText).Focus() }
}
Remove-BootsWindow "Object Filter"

# SIG # Begin signature block
# MIIIDQYJKoZIhvcNAQcCoIIH/jCCB/oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUPJz6PEWsj4tA+FFw0Zi/3a6d
# 4IqgggUrMIIFJzCCBA+gAwIBAgIQKQm90jYWUDdv7EgFkuELajANBgkqhkiG9w0B
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
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUSAMz/vVL
# n82iZXNyDNA+KEMznWcwDQYJKoZIhvcNAQEBBQAEggEAGb/HM7YKuHR3iwODw1fb
# GhGCUsEXLyOXfEMnfsvn7dVZRqM27KZbCPzJRZq3zneTTlsp0GPlNB21PKbdXthq
# RFYfjW9mPcNDd1PhYlCEqSe4fJTY0UcxVnsb6szM+L8QHGVCuD7+fgvPONyvfwdD
# DoByC/8RNJgHN0HYISno/b5LeMldhCzLmq+X8navE3QzNbfZ0hZv3w9OdOYyootr
# hPAupC5mWgsxZjaO0wbv5V7L3UOTmeESC4JzsaP4OJeT4OBZTCOEG/qyIqWRjoSP
# nv83F2bftJ02L2194Ma1uIFcKnKl2sTd+fDP1JAu5KoP5PpObeAjUiDH5B+Z1WXV
# 0Q==
# SIG # End signature block
