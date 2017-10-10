[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation
try {
    Import-VstsLocStrings "$PSScriptRoot\task.json"

	$csurl = Get-VstsTaskVariable -Name "cloudshell.apiUrl"
	$csusername = Get-VstsTaskVariable -Name "cloudshell.username"
	$cspassword = Get-VstsTaskVariable -Name "cloudshell.password"
	$csdomain = Get-VstsTaskVariable -Name "cloudshell.domain"

    $resid = $env:SANDBOXID

    write-host "Sandbox id: $resid"
    
	[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $True }

	$url = "$csurl/api/login"
	write-host "URL: $url"
	$body = "{""username"":""$csusername"", ""password"": ""$cspassword"", ""domain"": ""$csdomain""}"
	# write-host "Body: $body"

	$token = Invoke-RestMethod -Method Put -Uri $url -ContentType 'application/json' -Body $body

	# write-host "CloudShell Token: $token"

    # $global:ErrorActionPreference = 'Continue'
    $failed = $false

	$url = "$csurl/api/v2/sandboxes/$resid/stop"
	write-host "URL: $url"

	$headers = @{ "Authorization"="Basic $token"; }
	# write-host "Headers: $($headers | out-string)"

	write-host "Body: $body"

	$r = Invoke-RestMethod -Method Post -Uri $url -ContentType 'application/json' -Headers $headers

	write-host "Result: $($r | out-string)"

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}