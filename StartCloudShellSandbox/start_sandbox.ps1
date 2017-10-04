[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation
try {
    Import-VstsLocStrings "$PSScriptRoot\task.json"

    $bpname = Get-VstsInput -Name 'blueprintName' -Require

    $bpinputs = Get-VstsInput -Name 'blueprintInputs'

    write-host "bpinputs = $bpinputs"

    $bpinputjson = ""
    foreach($line in ($bpinputs -split '\r?\n')) {
        if("$line" -ne "") {
        	write-host "line: $line"
            if("$bpinputjson" -ne "") {
            	$bpinputjson += ", "
            }
            $bpinputjson += "{{""name"": ""{0}"", ""value"": ""{1}""}}" -f $line.split('=')
        }
    }
    $bpinputjson = "[$bpinputjson]"

    write-host "bpinputjson = $bpinputjson"

    $sbname = Get-VstsInput -Name 'sandboxName'
    if("$sbname" -eq "") {
    	$sbname = "$bpname - TFS"
    }

    $durationMinutes = Get-VstsInput -Name 'durationMinutes' -Require

    $csurl = $env:CLOUDSHELL_APIURL
    $csusername = $env:CLOUDSHELL_USERNAME
    $cspassword = $env:CLOUDSHELL_PASSWORD
    $csdomain = $env:CLOUDSHELL_DOMAIN

	[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $True }

	$url = "$csurl/api/login"
	write-host "URL: $url"
	$body = "{""username"":""$csusername"", ""password"": ""$cspassword"", ""domain"": ""$csdomain""}"
	# write-host "Body: $body"

	$token = Invoke-RestMethod -Method Put -Uri $url -ContentType 'application/json' -Body $body

	# write-host "CloudShell Token: $token"

    # $global:ErrorActionPreference = 'Continue'
    $failed = $false

	$url = "$csurl/api/v2/blueprints/$bpname/start"
	write-host "URL: $url"
	$body = @"
{
  "duration": "PT${durationMinutes}M",
  "name": "$sbname",
  "params": $bpinputjson
}
"@

	$headers = @{ "Authorization"="Basic $token"; }
	# write-host "Headers: $($headers | out-string)"

	write-host "Body: $body"

	$r = Invoke-RestMethod -Method Post -Uri $url -ContentType 'application/json' -Headers $headers -Body $body

	write-host "Result: $($r | out-string)"

	$resid = $r.id

	do {
		write-host 'Sleep 5'
		sleep 5
		$url = "$csurl/api/v2/sandboxes/$resid"
		write-host "URL: $url"
		$headers = @{ "Authorization"="Basic $token"; }
		write-host "Headers: $($headers | out-string)"
		$r = Invoke-RestMethod -Method Get -Uri $url -ContentType 'application/json' -Headers $headers
		write-host "Result: $($r | out-string)"
		$state = $r.state

	} while("$state" -ne "Ready")

    # Fail on $LASTEXITCODE

	$url = "$csurl/api/v2/sandboxes/$resid/components"
	write-host "URL: $url"

	$headers = @{ "Authorization"="Basic $token"; }
	# write-host "Headers: $($headers | out-string)"

	$r = Invoke-RestMethod -Method Get -Uri $url -ContentType 'application/json' -Headers $headers
	write-host "Result: $($r | out-string)"

	$components = $r

    # Write-VstsTaskError -Message (Get-VstsLocString -Key 'PS_ExitCode' -ArgumentList $LASTEXITCODE)

    # Fail if any errors.
    if ($failed) {
        Write-VstsSetResult -Result 'Failed' -Message "Error detected" -DoNotThrow
    }

    $componentsjson = $($components | convertto-json -Compress)
    write-host "components json: $componentsjson"

	Write-Output ("##vso[task.setvariable variable=SandboxId;]$resid")
	Write-Output ("##vso[task.setvariable variable=SandboxComponentsJSON;]$componentsjson")

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}