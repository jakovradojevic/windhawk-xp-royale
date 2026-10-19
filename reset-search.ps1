# Elevated: restart Windows Search and the Start search host with its WebView2 processes.
Restart-Service WSearch -Force
Get-CimInstance Win32_Process -Filter "Name='msedgewebview2.exe'" |
    Where-Object { $_.CommandLine -match 'MicrosoftWindows\.Client\.CBS' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Get-Process SearchHost -ErrorAction SilentlyContinue | Stop-Process -Force
