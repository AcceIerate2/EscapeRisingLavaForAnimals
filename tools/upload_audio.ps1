# Uploads a sound to Roblox through Open Cloud and prints its asset ID.
# Usage: powershell -ExecutionPolicy Bypass -File upload_audio.ps1 -File <path.wav> -Name <DisplayName> [-UserId 1850876647]
param(
	[Parameter(Mandatory = $true)][string]$File,
	[Parameter(Mandatory = $true)][string]$Name,
	[string]$UserId = "1850876647"
)

$key = $env:ROBLOX_API_KEY
if (-not $key) { $key = [Environment]::GetEnvironmentVariable("ROBLOX_API_KEY", "User") }
if (-not $key) { Write-Error "ROBLOX_API_KEY is not set"; exit 1 }

$request = '{"assetType":"Audio","displayName":"' + $Name + '","description":"SFX","creationContext":{"creator":{"userId":"' + $UserId + '"}}}'
# Windows PowerShell strips quotes from native arguments, so the JSON goes through a file.
$requestFile = [IO.Path]::GetTempFileName()
[IO.File]::WriteAllText($requestFile, $request)
$response = curl.exe -s -X POST "https://apis.roblox.com/assets/v1/assets" -H "x-api-key: $key" -F "request=<$requestFile" -F "fileContent=@$File;type=audio/wav"
Remove-Item $requestFile
$operation = ($response | ConvertFrom-Json).path
if (-not $operation) { Write-Output "UPLOAD FAILED: $response"; exit 1 }

for ($i = 0; $i -lt 30; $i++) {
	$result = curl.exe -s "https://apis.roblox.com/assets/v1/$operation" -H "x-api-key: $key" | ConvertFrom-Json
	if ($result.done) {
		Write-Output "ASSET $($result.response.assetId) ($Name) moderation: $($result.response.moderationResult.moderationState)"
		exit 0
	}
	Start-Sleep -Seconds 2
}
Write-Output "TIMED OUT waiting on $operation"
exit 1
