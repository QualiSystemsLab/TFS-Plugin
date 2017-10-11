[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation
try {
	Import-VstsLocStrings "$PSScriptRoot\task.json"

	$suiteName = Get-VstsInput -Name 'suiteName'


	$csurl = $env:CLOUDSHELL_QUALIAPIURL
	$csusername = $env:CLOUDSHELL_USERNAME
	$cspassword = Get-VstsTaskVariable -Name "cloudshell.password"
	$csdomain = $env:CLOUDSHELL_DOMAIN

	[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $True }

	$url = "$csurl/Api/Auth/Login"
	write-host "URL: $url"
	$body = "username=${csusername}&password=${cspassword}&domain=${csdomain}"
	# write-host "Body: $body"

	$token = Invoke-RestMethod -Method Put -Uri $url -ContentType 'application/x-www-form-urlencoded' -Body $body
	# write-host "CloudShell Token: $token"


	$url = "$csurl/API/Scheduling/SuiteTemplates/$suiteName"
	write-host "URL: $url"
	$headers = @{ "Authorization"="Basic $token"; }
	# write-host "Headers: $($headers | out-string)"
	$r = Invoke-RestMethod -Method Get -Uri $url -Headers $headers
	write-host "result: $($r | convertto-json -depth 100)"

	$template = $r

	$r.SuiteName = "$suiteName - TFS"

	$url = "$csurl/API/Scheduling/Suites"
	write-host "URL: $url"
	$headers = @{ "Authorization"="Basic $token"; }
	# write-host "Headers: $($headers | out-string)"
	$body = $template | convertto-json -depth 100
	$body = $body.replace('.0', '')
	write-host "Body: $body"
	$suiteid = Invoke-RestMethod -Method Post -Uri $url -ContentType 'application/json' -Headers $headers -Body $body

	do {
		write-host 'Sleep 5'
		sleep 5
		
		$url = "$csurl/API/Scheduling/Suites/Status/$suiteid"
		write-host "URL: $url"
		$headers = @{ "Authorization"="Basic $token"; }
		# write-host "Headers: $($headers | out-string)"
		$r = Invoke-RestMethod -Method Get -Uri $url -ContentType 'application/json' -Headers $headers
		write-host "Result: $($r | out-string)"
		
		$state = $r.SuiteStatus

	} while("$state" -ne "Ended")

	# Write-VstsTaskError -Message (Get-VstsLocString -Key 'PS_ExitCode' -ArgumentList $LASTEXITCODE)
	# Write-VstsSetResult -Result 'Failed' -Message "Error detected" -DoNotThrow

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
