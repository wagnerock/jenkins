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
    [Parameter(Mandatory = $false)][string]$CSVFilePath,
    [Parameter(Mandatory = $false)][string]$DeviceID,
    [Parameter(Mandatory = $false)][string]$Command,
    [Parameter(Mandatory = $false)][string]$NewDeviceName,
    [Parameter(Mandatory = $false)][string]$NewOwnership
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

Function Invoke-DeviceAction(){

    <#
    .SYNOPSIS
    This function is used to set a generic intune resources from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and sets a generic Intune Resource
    .EXAMPLE
    Invoke-DeviceAction -DeviceID $DeviceID -Command $Command -NewDeviceName $NewDeviceName -NewOwnership $NewOwnership
    Command = delete or rename or changeOwnership
    if command = rename then new device name is required
    if command = changeOwnership then new ownership is required
    .NOTES
    NAME: Invoke-DeviceAction
    #>
    
    [cmdletbinding()]
    
    param
    (
        [Parameter(Mandatory = $true)][string]$DeviceID,
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $false)][string]$NewDeviceName,
        [Parameter(Mandatory = $false)][string]$NewOwnership
    )
    
    $graphApiVersion = "Beta"
    
        try {
    
            if($Command -eq ""){    
                write-host "No command specified" -f Red    
            }
            elseif($Command -eq "delete"){
                #First retire the device before delete
                $Resource = "deviceManagement/managedDevices/$DeviceID/retire"
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
                write-verbose $uri
                Write-Verbose "Sending retire command to $DeviceID"
                Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post

                #Run delete command
                $Resource = "deviceManagement/managedDevices/$DeviceID"
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
                write-verbose $uri
                Write-Verbose "Sending delete command to $DeviceID"
                Invoke-RestMethod -Uri $uri -Headers $authToken -Method Delete
            }
            elseif(($Command -eq "rename" -and $NewDeviceName -ne "")  -or ($Command -eq "changeOwnership"-and $NewOwnership -ne "")){
                if($Command -eq "rename" -and $NewDeviceName -ne ""){
                    $Json = "{""deviceName"":""$NewDeviceName""}"
                    $Resource = "deviceManagement/managedDevices/$DeviceID/setDeviceName"
                    $uri = "https://graph.microsoft.com/$graphApiVersion/$resource"
                    Write-Host $uri
                    Write-Host "Sending $Command command to $DeviceID command data $Json"
                    Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $Json -ContentType "application/json"
                }
                elseif ($Command -eq "changeOwnership" -and $NewOwnership -ne "") {
                    $Json = "{""ownerType"":""$NewOwnership""}"
                    $Resource = "deviceManagement/managedDevices/$DeviceID"
                    $uri = "https://graph.microsoft.com/$graphApiVersion/$resource"
                    Write-Host $uri
                    Write-Host "Sending $Command command to $DeviceID command data $Json"
                    Invoke-RestMethod -Uri $uri -Headers $authToken -Method Patch -Body $Json -ContentType "application/json"
                }
            }
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
<#
#region Authentication

# Getting the authorization token
$global:authToken = Get-AuthToken -ClientID $ClientID -ClientSecret $ClientSecret -TenantId $TenantId
#endregion

write-host $global:authToken.Authorization

write-host $global:authToken.ExpiresOn

if($CSVFilePath){ #Command to read from CSV file and process multiple devices/commmands
    $AllDevices = Import-Csv -Path $CSVFilePath

    $DevicesToProcess = $AllDevices | Where-Object -Property command -ne ""

    foreach($Device in $DevicesToProcess){
        if($Device.Command -eq "delete"){
            write-host "Managed Device" $Device.deviceName "command" $Device.command -ForegroundColor Yellow
            Write-Host   
            Invoke-DeviceAction -DeviceID $Device.id -Command delete  
        }
        elseif ($Device.command -eq "rename" -and $Device.newDeviceName -ne "") {
            write-host "Managed Device" $Device.deviceName "command" $Device.command " new device name " $Device.newDeviceName -ForegroundColor Yellow
            Write-Host 
            Invoke-DeviceAction -DeviceID $Device.id -Command rename -NewDeviceName $Device.newDeviceName
        }
        elseif ($Device.command -eq "changeOwnership" -and $Device.newOwnership -ne "") {
            write-host "Managed Device" $Device.deviceName "command" $Device.command " new device ownership " $Device.newOwnership -ForegroundColor Yellow
            Write-Host 
            Invoke-DeviceAction -DeviceID $Device.id -Command changeOwnership -NewOwnership $Device.newOwnership
        }

        Write-Host
    }
}
elseif ($DeviceID) { #Command for inividual device
    if($Command -eq "delete")
    {
        Invoke-DeviceAction -DeviceID $DeviceID -Command delete
    }
    elseif ($Command -eq "rename" -and $NewDeviceName) {
        Invoke-DeviceAction -DeviceID $DeviceID -Command rename -NewDeviceName $NewDeviceName
    }
    elseif ($Command -eq "changeOwnership" -and $NewOwnership) {
        Invoke-DeviceAction -DeviceID $DeviceID -Command changeOwnership -NewOwnership $NewOwnership
    }
}
#>
if($CSVFilePath){ Import-Csv $CSVFilePath | Write-Host}