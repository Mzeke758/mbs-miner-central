$index = Get-Content -Path "index.html" -Raw
$urls = @()
foreach ($m in [regex]::Matches($index,'src="(/[^"\s>]+)"')) { $urls += $m.Groups[1].Value }
foreach ($m in [regex]::Matches($index,"src='(/[^'\s>]+)'") ) { $urls += $m.Groups[1].Value }
foreach ($m in [regex]::Matches($index,'href="(/[^"\s>]+)"')) { $urls += $m.Groups[1].Value }
foreach ($m in [regex]::Matches($index,"href='(/[^'\s>]+)'") ) { $urls += $m.Groups[1].Value }
$urls = $urls | Sort-Object -Unique
$urls | Out-File -FilePath assets.txt -Encoding ASCII
Write-Host "Wrote $($urls.Count) asset paths to assets.txt"
