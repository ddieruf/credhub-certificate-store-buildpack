$ErrorActionPreference = "Stop"

echo "Credhub supply buildpack: Validating environment variables"

# ensure we have services bound
if ((Test-Path env:VCAP_SERVICES) -eq $False) {
  Write-Error -Message "Credhub supply buildpack: VCAP_SERVICES environment variable has not been set, is the app bound to a service?" -ErrorAction Stop
  exit 1
}

echo "Credhub supply buildpack: Parsing environment variables"
# find all services tagged with windows-vault
$vcapservices = (echo $env:VCAP_SERVICES | ConvertFrom-Json)
if ($vcapservices -eq $False){
  Write-Error "Credhub supply buildpack: VCAP_SERVICES environment variable is empty, is the app bound to the Credhub service?" -ErrorAction Stop
  exit 1
}

#any bound service on the app that has a tag with the below value, will get added to the certificate store
$serviceTag = "certificate-store"
$creds = $vcapservices.psobject.properties.value | ? { $_.tags -eq $serviceTag } | % { $_.credentials }

if ($creds -eq $False){
  echo "Credhub supply buildpack: No certificates were found to store. Ignoring."
  return 0
}

echo "Credhub supply buildpack: Populating the CurrentUser certificate store"
foreach ($cred in $creds) {
  # ensure the creds match the schema we support
  if (-not ($cred.certificate -and $cred.password)) {
    Write-Error -Message 'Credhub supply buildpack: One or more properties are missing from the Credhub paramaters. Expecting "certificate" and "password" values.' -ErrorAction Stop
    exit 1
  }
  
  $bytes = [System.Convert]::FromBase64String($cred.certificate)

  if ($bytes.Length -eq 0) {
    Write-Error -Message "Credhub supply buildpack: Invalid or empty certificate bytes." -ErrorAction Stop
    exit 1
  }

  $xcert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
  $xcert.Import($bytes, $cred.password, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet)

  $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("My","CurrentUser")
  $store.Open("ReadWrite")
  $store.Add($xcert)
  $store.Close()

  echo "Credhub supply buildpack: Added certificate"
}