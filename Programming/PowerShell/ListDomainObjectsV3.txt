function Write-UserInfo
{
	Write-Host "user info:";
	Write-Host "$($env:USERDOMAIN)\$($env:USERNAME)";
	Write-Host "$(hostname)"
}

#$global:sb = (get-command "Write-UserInfo" -CommandType Function).ScriptBlock
$sb = ${function:Write-UserInfo};

function Test-ADSI
{
	param(
		[string]$DomainName,
		$fn1
	)
	
Write-Host "$($env:USERDOMAIN)\$($env:USERNAME)"
#Invoke-Command -Scriptblock ${function:Write-UserInfo};
#Invoke-Command -Scriptblock $global:sb;
#& $global:sb;
& $fn1.Scriptblock;
[string]$domainTail = "DC=" + $DomainName.Replace(".", ",DC=");
Write-Host "Deleting object in the '$($domainTail)' namespace";
$ouList = @(
	"OU=AT_GroupPolicyObjects,$($domainTail)",
	"OU=AT_ObjectsForAlerts,$($domainTail)",
	"OU=AT_ObjectsFullCollection,$($domainTail)",
	"OU=AT_ObjectsTargetOU,$($domainTail)"
	   )

$resultCollection = @();

foreach ($ouIdentity in $ouList) { 
	Write-Host "Cleaning up the '$($ouIdentity)' organizationalUnit";
	$ou = [adsi]"LDAP://at-root-dc:389/$($ouIdentity)"; 
	$resultCollection += $ou;
	$ou.children | %{
			try {
				Write-Host "Deleting object of class $($_.Class)";
				if ("organizationalUnit" -eq $_.Class) {
					Write-Host "Deleting 'OU=$($_.Name)'";
					#$ou.Delete($_.Class, "OU=$($_.Name)");
				} else {
					Write-Host "Deleting 'CN=$($_.cn)'";
					#$ou.Delete($_.Class, "CN=$($_.cn)");
				}
				Write-Host "success";
			}
			catch {}
			}
}

1..5 | %{
	WRite-Host "waiting 5 seconds for changes being caught by DirSync";
	sleep -Seconds 5;
	}

return $resultCollection;
}

$results = @();
$results += Invoke-Command -ComputerName vl-w2k12-dc.castaway.at.local -Scriptblock ${function:Test-ADSI} -ArgumentList "castaway.at.local",$sb;
