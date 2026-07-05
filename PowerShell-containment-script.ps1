# Load Active Directory module for Get-ADUser, Disable-ADAccount, etc.
Import-Module ActiveDirectory

# Expected API token for authentication
$ExpectedToken = "LabToken123"

# Port and URL prefix for the HTTP listener
$Port = 8085
$Prefix = "http://+:$Port/disable/"

# Create and start the HTTP listener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($Prefix)
$listener.Start()

Write-Host "SOAR Disable User API listening on $Prefix"

# Helper function to send JSON responses back to the client
function Send-JsonResponse {
    param(
        $Context,
        [int]$StatusCode,
        $Object
    )

    # Convert object to JSON and write it to the HTTP response
    $json = $Object | ConvertTo-Json -Depth 5
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)

    $Context.Response.StatusCode = $StatusCode
    $Context.Response.ContentType = "application/json"
    $Context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
    $Context.Response.OutputStream.Close()
}

# Main API loop — keeps listening for incoming requests
while ($listener.IsListening) {
    $context = $listener.GetContext()

    try {
        # Only allow POST requests
        if ($context.Request.HttpMethod -ne "POST") {
            Send-JsonResponse $context 405 @{
                success = $false
                error = "Only POST allowed"
            }
            continue
        }

        # Read and parse JSON body
        $reader = New-Object System.IO.StreamReader($context.Request.InputStream)
        $body = $reader.ReadToEnd()
        $data = $body | ConvertFrom-Json

        # Validate API token
        if ($data.token -ne $ExpectedToken) {
            Send-JsonResponse $context 401 @{
                success = $false
                error = "Unauthorized"
            }
            continue
        }

        # Raw username from request
        $samRaw = ([string]$data.samaccountname).Trim()

        # Clean username (remove domain\user or user@domain formats)
        $sam = $samRaw
        if ($sam -match "\\") { $sam = ($sam -split "\\")[-1] }
        if ($sam -match "@") { $sam = ($sam -split "@")[0] }
        $sam = $sam.Trim()

        # Validate cleaned username format
        if ($sam -notmatch '^[a-zA-Z0-9._-]{1,64}$') {
            Send-JsonResponse $context 400 @{
                success = $false
                error = "Invalid SamAccountName"
                raw_value = $samRaw
                cleaned_value = $sam
            }
            continue
        }

        # Prevent disabling critical system accounts
        if ($sam -in @("Administrator", "krbtgt", "binduser")) {
            Send-JsonResponse $context 403 @{
                success = $false
                error = "Protected account cannot be disabled"
                raw_value = $samRaw
                cleaned_value = $sam
            }
            continue
        }

        # Get user status before disabling
        $userBefore = Get-ADUser -Identity $sam -Properties Enabled

        # Disable the AD account
        Disable-ADAccount -Identity $sam

        # Small delay to allow AD to update
        Start-Sleep -Seconds 1

        # Get user status after disabling
        $userAfter = Get-ADUser -Identity $sam -Properties Enabled

        # Verify the account is now disabled
        $verifiedDisabled = -not $userAfter.Enabled

        # Send success response
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
        # Catch unexpected errors and return 500
        Send-JsonResponse $context 500 @{
            success = $false
            error = $_.Exception.Message
        }
    }
}
