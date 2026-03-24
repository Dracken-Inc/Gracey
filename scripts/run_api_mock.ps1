Param(
    [int]$Port = 8080
)

$ErrorActionPreference = "Stop"

Write-Host "Starting Gracey API in mock mode on port $Port"
Push-Location "$PSScriptRoot\..\interfaces\api"

try {
    if (-not (Test-Path ".venv")) {
        python -m venv .venv
    }

    .\.venv\Scripts\python -m pip install --upgrade pip
    .\.venv\Scripts\pip install -r requirements.txt
    .\.venv\Scripts\python -m uvicorn app.main:app --host 0.0.0.0 --port $Port --reload
}
finally {
    Pop-Location
}
