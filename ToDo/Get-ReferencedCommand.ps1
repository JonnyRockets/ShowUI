function Get-ReferencedCommand { 
    <#
    .Synopsis
        Gets the commands referred to from within a function or external script
    .Description
        Uses the Tokenizer to get the commands referred to from within a function or external script    
    .Example
        Get-Command New-Button | Get-ReferencedCommand
    #>
    param(
    # The script block to search for command references
    [Parameter(Mandatory=$true,
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$true)]
    [ScriptBlock]
    $ScriptBlock
    ) 

    begin {
        if (-not ('WPK.GetReferencedCommand' -as [Type])) {
            Add-Type -IgnoreWarnings @"
using System;
using System.Collections.Generic;
using System.Management.Automation;
using System.Collections.ObjectModel;

namespace WPK {
    public class GetReferencedCommand {
        public static IEnumerable<CommandInfo> GetReferencedCommands(ScriptBlock scriptBlock, PSCmdlet cmdlet)
        {
            Dictionary<CommandInfo, bool> resolvedCommandCache = new Dictionary<CommandInfo, bool>();
            Queue<PSToken> tokenQueue = new Queue<PSToken>();
            Collection<PSParseError> errors;
            foreach (PSToken token in PSParser.Tokenize(new object[] { scriptBlock }, out errors))
            {
                tokenQueue.Enqueue(token);
            }
            if (tokenQueue.Count == 0) { 
                yield return null;
            }
            while (tokenQueue.Count > 0)
            {
                PSToken token = tokenQueue.Dequeue();
                if (token.Type == PSTokenType.Command)
                {
                    CommandInfo cmd = null;
                    cmd = cmdlet.SessionState.InvokeCommand.GetCommand(token.Content, CommandTypes.Alias);
                    if (cmd == null)
                    {
                        cmd = cmdlet.SessionState.InvokeCommand.GetCommand(token.Content, CommandTypes.Function);
                        if (cmd == null)
                        {
                            cmd = cmdlet.SessionState.InvokeCommand.GetCommand(token.Content, CommandTypes.Cmdlet);
                        }
                    }
                    else
                    {
                        while (cmd != null && cmd is AliasInfo)
                        {
                            AliasInfo alias = cmd as AliasInfo;
                            if (!resolvedCommandCache.ContainsKey(alias))
                            {
                                yield return alias;
                                resolvedCommandCache.Add(alias, true);
                            }
                            cmd = alias.ReferencedCommand;
                        }
                    }
                    if (cmd == null) { continue; }
                    if (cmd is FunctionInfo)
                    {
                        if (! resolvedCommandCache.ContainsKey(cmd))
                        {
                            FunctionInfo func = cmd as FunctionInfo;
                            yield return cmd;
                            foreach (PSToken t in PSParser.Tokenize(new object[] { func.ScriptBlock }, out errors))
                            {
                                tokenQueue.Enqueue(t);
                            }
                            resolvedCommandCache.Add(cmd, true);
                        }
                    } else {
                        if (!resolvedCommandCache.ContainsKey(cmd))
                        {
                            yield return cmd;
                            resolvedCommandCache.Add(cmd, true);
                        }
                    }
                }
            }
        }
    }
}
"@
        }
        $commandsEncountered = @{}
    }
    process {   
        [WPK.GetReferencedCommand]::GetReferencedCommands($ScriptBlock, $PSCmdlet)
    }
}
# SIG # Begin signature block
# MIIIDQYJKoZIhvcNAQcCoIIH/jCCB/oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUbxH6tuSg5vQ6gUMh3Km90nu9
# oWugggUrMIIFJzCCBA+gAwIBAgIQKQm90jYWUDdv7EgFkuELajANBgkqhkiG9w0B
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
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUVtFuILzy
# fSFZbSVcTd/JPXmRK28wDQYJKoZIhvcNAQEBBQAEggEAxxdxvAkMezLlpMCZrYxt
# tdqF3z6tdjwvhndTK7+nasKL1QEC4V2Mmf7nhxpYVmTatJWR1oY53qJ+qlo/isNZ
# IfSkztgwANTd8iKqfO7X5xkOTy9KpGZJ7La+8goQdj+ogM7WotLbJu5VzrBvhaoK
# 7DITwbtpsl8j7vwAywguHyddd2QZhxa9GKvW+Lg3qZMktRD16k+/7X+TN7stWzNe
# 5j8C15+eq/Ksi6orm2aZN3r4blpKTBYlzio2MRGa5b/YINDIK1QB4JI2kXQXftrD
# NxkBp5q/dRtUfYM8hhdIA9j/jxT/sFC9FEAV/OVPfOq3sYLyq8ui95reBcVC0iXM
# AQ==
# SIG # End signature block
