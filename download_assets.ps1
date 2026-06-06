$indexPath = "c:\Users\Henry\Documents\wedeliverlogistic\mbs-miner-central\index.html"
$previewHost = 'https://id-preview--39ea59ef-38bd-4a92-be4d-65603fe4c4ff.lovable.app'

$html = Get-Content $indexPath -Raw
$matches = [regex]::Matches($html,'(?:src|href)=["\'](?<url>/[^"\']+)["\']','IgnoreCase') | ForEach-Object { $_.Groups['url'].Value }
$urls = $matches | Sort-Object -Unique

Write-Host "Found $($urls.Count) unique asset paths"

foreach ($url in $urls) {
    # Skip data: URIs
    if ($url -like 'data:*') { continue }
    $full = $previewHost + $url
    $local = Join-Path (Get-Location) ($url.TrimStart('/'))
    $dir = Split-Path $local -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Write-Host "Downloading $full -> $local"
    try {
        Invoke-WebRequest -Uri $full -OutFile $local -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Host "Failed with Invoke-WebRequest, trying curl: $full"
        curl -sS -L $full -o $local
    }
}
Write-Host "Download complete" 
