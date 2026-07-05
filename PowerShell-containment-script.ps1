Import-Module ActiveDirectory

$ExpectedToken = "LabToken123"
$Port = 8085
$Prefix = "http://+:$Port/disable/"

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($Prefix)
$listener.Start()

Write-Host "SOAR Disable User API listening on $Prefix"

function Send-JsonResponse {
    param(
        $Context,
        [int]$StatusCode,
        $Object
    )

    $json = $Object | ConvertTo-Json -Depth 5
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)

    $Context.Response.StatusCode = $StatusCode
    $Context.Response.ContentType = "application/json"
    $Context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
    $Context.Response.OutputStream.Close()
}

while ($listener.IsListening) {
    $context = $listener.GetContext()

    try {
        if ($context.Request.HttpMethod -ne "POST") {
            Send-JsonResponse $context 405 @{
                success = $false
                error = "Only POST allowed"
            }
            continue
        }

        $reader = New-Object System.IO.StreamReader($context.Request.InputStream)
        $body = $reader.ReadToEnd()
        $data = $body | ConvertFrom-Json

        if ($data.token -ne $ExpectedToken) {
            Send-JsonResponse $context 401 @{
                success = $false
                error = "Unauthorized"
            }
            continue
        }

        # Get raw username from Shuffle
        $samRaw = ([string]$data.samaccountname).Trim()

        # Clean username if Shuffle sends domain\user or user@domain
        $sam = $samRaw

        if ($sam -match "\\") {
            $sam = ($sam -split "\\")[-1]
        }

        if ($sam -match "@") {
            $sam = ($sam -split "@")[0]
        }

        $sam = $sam.Trim()

        # Validate cleaned SamAccountName
        if ($sam -notmatch '^[a-zA-Z0-9._-]{1,64}$') {
            Send-JsonResponse $context 400 @{
                success = $false
                error = "Invalid SamAccountName"
                raw_value = $samRaw
                cleaned_value = $sam
            }
            continue
        }

        # Protect important accounts
        if ($sam -in @("Administrator", "krbtgt", "binduser")) {
            Send-JsonResponse $context 403 @{
                success = $false
                error = "Protected account cannot be disabled"
                raw_value = $samRaw
                cleaned_value = $sam
            }
            continue
        }
$userBefore = Get-ADUser -Identity $sam -Properties Enabled

Disable-ADAccount -Identity $sam

Start-Sleep -Seconds 1

$userAfter = Get-ADUser -Identity $sam -Properties Enabled

$verifiedDisabled = -not $userAfter.Enabled

Send-JsonResponse $context 200 @{
    success = $true
    message = "Account disable action completed"
    raw_value = $samRaw
    disabled_user = $sam
    previous_enabled_status = $userBefore.Enabled
    current_enabled_status = $userAfter.Enabled
    verified_disabled = $verifiedDisabled
    time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}
    }
    catch {
        Send-JsonResponse $context 500 @{
            success = $false
            error = $_.Exception.Message
        }
    }
}
