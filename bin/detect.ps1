echo "running windows credhub buildpack detect step"

if ($env:OS -eq "Windows_NT") {
  exit 0
} else {
  exit 1
}