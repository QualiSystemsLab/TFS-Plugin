[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation
try {
    Import-VstsLocStrings "$PSScriptRoot\task.json"

    $cmdinputs = Get-VstsInput -Name 'commandInputs'

    write-host "cmdinputs = $cmdinputs"

    $cmdinputjson = ""
    foreach($line in ($cmdinputs -split '\r?\n')) {
        if("$line" -ne "") {
        	write-host "line: $line"
            if("$cmdinputjson" -ne "") {
            	$cmdinputjson += ", "
            }
            $cmdinputjson += "{{""name"": ""{0}"", ""value"": ""{1}""}}" -f $line.split('=')
        }
    }
    $cmdinputjson = "[$cmdinputjson]"

    write-host "cmdinputjson = $cmdinputjson"

    $commandName = Get-VstsInput -Name 'commandName' -Require

    $targetType = Get-VstsInput -Name 'targetType' -Require
    if("$targetType" -eq "Resource or Service") {
	    $targetPattern = Get-VstsInput -Name 'targetPattern' -Require
    }


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

    if($targetType -eq "Environment") {
		$url = "$csurl/api/v2/sandboxes/$resid/components/$compid/commands/$commandname/start"
		write-host "URL: $url"
		$body = @"
{
  "params": $cmdinputjson,
  "printOutput": true
}
"@

		$headers = @{ "Authorization"="Basic $token"; }
		# write-host "Headers: $($headers | out-string)"
		write-host "Body: $body"

		$r = Invoke-RestMethod -Method Post -Uri $url -ContentType 'application/json' -Headers $headers -Body $body
		write-host "Result: $($r | out-string)"

		$exid = $r.executionId   
    } else {
	 	$url = "$csurl/api/v2/sandboxes/$resid/components"
		write-host "URL: $url"

		$headers = @{ "Authorization"="Basic $token"; }
		# write-host "Headers: $($headers | out-string)"

		$r = Invoke-RestMethod -Method Get -Uri $url -ContentType 'application/json' -Headers $headers
		write-host "Result: $($r | out-string)"

		$components = $r
		$compid = ""
		foreach($comp in $components) {
			if($comp.Name -match $targetPattern) {
				$compid = $comp.id
				break
			}
		}
		if("$compid" -eq "") {
			Write-VstsSetResult -Result 'Failed' -Message "Could not find a component matching $targetPattern in sandbox $resid" -DoNotThrow
			exit
		}
		$url = "$csurl/api/v2/sandboxes/$resid/components/$compid/commands/$commandName/start"
		write-host "URL: $url"
		$body = @"
{
  "params": $cmdinputjson,
  "printOutput": true
}
"@

		$headers = @{ "Authorization"="Basic $token"; }
		# write-host "Headers: $($headers | out-string)"

		write-host "Body: $body"

		$r = Invoke-RestMethod -Method Post -Uri $url -ContentType 'application/json' -Headers $headers -Body $body
		write-host "Result: $($r | out-string)"

		$exid = $r.executionId   
    }


	do {
		write-host 'Sleep 5'
		sleep 5
		$url = "$csurl/api/v2/executions/$exid"
		write-host "URL: $url"
		$headers = @{ "Authorization"="Basic $token"; }
		# write-host "Headers: $($headers | out-string)"
		$r = Invoke-RestMethod -Method Get -Uri $url -ContentType 'application/json' -Headers $headers
		write-host "Result: $($r | out-string)"
		$status = $r.status

	} while(("$status" -ne "Finished") -and ("$status" -ne "Completed") -and ("$status" -ne "Error") -and ("$status" -ne "Failed"))

	if(("$status" -eq "Error") -or ("$status" -eq "Failed")) {
		Write-VstsSetResult -Result 'Failed' -Message "Error detected" -DoNotThrow
	}


} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}