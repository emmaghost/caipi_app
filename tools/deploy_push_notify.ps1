# Deploy Edge Function notify-chat + secret FCM (Base64, compatible con PowerShell)
$ErrorActionPreference = "Stop"
$Root = "c:\laragon\www\app-caipi"
Set-Location $Root

$saPath = Join-Path $Root "secrets\firebase-service-account.json"
if (-not (Test-Path $saPath)) {
  Write-Host "Falta $saPath" -ForegroundColor Red
  exit 1
}

$bytes = [System.IO.File]::ReadAllBytes($saPath)
$b64 = [Convert]::ToBase64String($bytes)

Write-Host "Login Supabase (navegador si lo pide)..." -ForegroundColor Cyan
npx --yes supabase login

Write-Host "Link proyecto qxldfqnuwpucptajcazf ..." -ForegroundColor Cyan
npx --yes supabase link --project-ref qxldfqnuwpucptajcazf

Write-Host "Secret FIREBASE_SERVICE_ACCOUNT_B64 ..." -ForegroundColor Cyan
npx --yes supabase secrets set "FIREBASE_SERVICE_ACCOUNT_B64=$b64"

Write-Host "Deploy notify-chat ..." -ForegroundColor Cyan
npx --yes supabase functions deploy notify-chat --no-verify-jwt

Write-Host ""
Write-Host "OK. Ahora en Dashboard:" -ForegroundColor Green
Write-Host "Database > Webhooks > Create hook"
Write-Host "  Table: mensajes_chat | INSERT | Edge Function: notify-chat"
Write-Host "Opcional: solicitudes_recogida | INSERT | notify-chat"
Write-Host ""
Write-Host "Guia: INSTRUCCIONES_PUSH_SERVIDOR.md"
