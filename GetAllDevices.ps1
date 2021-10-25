<#
.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
#>

[Cmdletbinding()]
Param(
    [Parameter(Mandatory = $true)][string]$ClientID,
    [Parameter(Mandatory = $true)][string]$ClientSecret,
    [Parameter(Mandatory = $true)][string]$TenantId,
    [Parameter(Mandatory = $false)][datetime]$DeviceSyncDate
)

####################################################

function Get-AuthToken {

<#
.SYNOPSIS
This function is used to authenticate with the Graph API REST interface
.DESCRIPTION
The function authenticate with the Graph API Interface with the tenant name
.EXAMPLE
Get-AuthToken
Authenticates you with the Graph API interface
.NOTES
NAME: Get-AuthToken
#>

[cmdletbinding()]

param
(
	[Parameter(Mandatory = $true)][string]$ClientID,
    [Parameter(Mandatory = $true)][string]$ClientSecret,
    [Parameter(Mandatory = $true)][string]$TenantId
)

	$body = @{grant_type = "client_credentials"; scope = "https://graph.microsoft.com/.default"; client_id = $ClientID; client_secret = $ClientSecret }

    $response = Invoke-RestMethod -Uri https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token -Method Post -Body $body
    $token = $response.access_token

        # If the accesstoken is valid then create the authentication header
	if($token){
		$expiresOn = (get-date).AddSeconds($response.expires_in)

		# Creating header for Authorization token
        $authHeader = @{
            'Content-Type'='application/json'
            'Authorization'="Bearer " + $token
            'ExpiresOn'=$expiresOn
            }

        return $authHeader
			
	}

	else {

        Write-Host
        Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
        Write-Host
        break

	}
}

####################################################
Function Get-ManagedDevices(){
<#
.SYNOPSIS
This function is used to get Intune Managed Devices from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any Intune Managed Device
.EXAMPLE
Get-ManagedDevices
Returns all managed devices but excludes EAS devices registered within the Intune Service
.NOTES
NAME: Get-ManagedDevices
#>

# Defining Variables
$graphApiVersion = "beta"
$Resource = "deviceManagement/managedDevices"

try {

        if($DevideSyncDate) {
            $formatedDate = $DevideSyncDate.ToString('yyyy-MM-dd')
            $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource`?`$filter=lastSyncDateTime le $formatedDate"
        }
        else {
            $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
        }
        
        Write-Host $uri

        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
    
    }

    catch {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break
    }
}

####################################################

#region Authentication

# Getting the authorization token
$global:authToken = Get-AuthToken -ClientID $ClientID -ClientSecret $ClientSecret -TenantId $TenantId
#endregion

####################################################

$ManagedDevices = Get-ManagedDevices

if($ManagedDevices){
$ManagedDevices | Select-Object -Property id, deviceName, deviceType, OperatingSystem, serialNumber, ownerType, lastSyncDateTime, command, newDeviceName, newOwnership | 
	Export-Csv -Path ./Devices.csv -NoTypeInformation

    foreach($Device in $ManagedDevices){

    #$DeviceID = $Device.id

    write-host "Managed Device" $Device.deviceName "found..." -ForegroundColor Yellow
    Write-Host
        #$Device

        # if($Device.deviceRegistrationState -eq "registered"){

        # $UserId = Get-ManagedDeviceUser -DeviceID $DeviceID

        # $User = Get-AADUser $userId

        # Write-Host "Device Registered User:" $User.displayName -ForegroundColor Cyan
        # Write-Host "User Principle Name:" $User.userPrincipalName
        # }
    #Write-Host

    }
}

else {

Write-Host
Write-Host "No Managed Devices found..." -ForegroundColor Red
Write-Host

}