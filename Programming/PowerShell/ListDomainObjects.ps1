function Test-ADSI
{
	param(
		[string]$DomainName
	)
	
"$($env:USERDOMAIN)\$($env:USERNAME)"
[string]$domainTail = "DC=" + $DomainName.Replace(".", ",DC=");
WRite-Host "Deleting object in the '$($domainTail)' namespace";
$ouList = @(
	"OU=AT_GroupPolicyObjects,$($domainTail)",
	"OU=AT_ObjectsForAlerts,$($domainTail)",
	"OU=AT_ObjectsFullCollection,$($domainTail)",
	"OU=AT_ObjectsTargetOU,$($domainTail)"
	   )

foreach ($ouIdentity in $ouList) { 
	WRite-Host "Cleaning up the '$($ouIdentity)' organizationalUnit";
	$ou = [adsi]"LDAP://at-root-dc:389/$($ouIdentity)"; 
	$ou.children | %{
			try {
				WRite-Host "Deleting object of class $($_.Class)";
				if ("organizationalUnit" -eq $_.Class) {
					WRite-Host "Deleting 'OU=$($_.Name)'";
					#$ou.Delete($_.Class, "OU=$($_.Name)");
				} else {
					WRite-Host "Deleting 'CN=$($_.cn)'";
					#$ou.Delete($_.Class, "CN=$($_.cn)");
				}
				WRite-Host "success";
			}
			catch {}
			}
}

1..5 | %{
	WRite-Host "waiting 5 seconds for changes being caught by DirSync";
	sleep -Seconds 5;
	}

}

Invoke-Command -ComputerName vl-w2k12-dc.castaway.at.local -Scriptblock ${function:Test-ADSI} -ArgumentList "castaway.at.local";
