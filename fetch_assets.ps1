$index = Get-Content -Path "index.html" -Raw
$previewHost = 'https://id-preview--39ea59ef-38bd-4a92-be4d-65603fe4c4ff.lovable.app'
$urls = @()
foreach ($m in [regex]::Matches($index,'src="(/[^"\s>]+)"')) { $urls += $m.Groups[1].Value }
foreach ($m in [regex]::Matches($index,"src='(/[^'\s>]+)'") ) { $urls += $m.Groups[1].Value }
foreach ($m in [regex]::Matches($index,'href="(/[^"\s>]+)"')) { $urls += $m.Groups[1].Value }
foreach ($m in [regex]::Matches($index,"href='(/[^'\s>]+)'") ) { $urls += $m.Groups[1].Value }
$urls = $urls | Sort-Object -Unique
Write-Host "Found $($urls.Count) asset paths"

foreach ($u in $urls) {
    if ($u -like 'data:*') { continue }
    $full = $previewHost + $u
    $local = Join-Path (Get-Location) ($u.TrimStart('/'))
    $dir = Split-Path $local -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Write-Host "Downloading $u -> $local"
    try {
        Invoke-WebRequest -Uri $full -OutFile $local -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Host "Invoke-WebRequest failed for $full, trying curl"
        curl.exe -sSL $full -o $local
    }
}
Write-Host 'All done'
