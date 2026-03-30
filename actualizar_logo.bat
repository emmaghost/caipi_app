@echo off
echo ========================================
echo   ACTUALIZANDO LOGO DE CAIPI
echo   (Verificando logo_caipi.jpeg)
echo ========================================
echo.

if not exist "assets\images\logo_caipi.jpeg" (
    echo ERROR: No se encuentra logo_caipi.jpeg
    echo.
    echo Por favor guarda tu logo nuevo como:
    echo   C:\laragon\www\app-caipi\assets\images\logo_caipi.jpeg
    echo.
    pause
    exit /b 1
)

echo Logo encontrado! Continuando...
echo.

cd C:\laragon\www\app-caipi

echo [1/5] Limpiando cache...
C:\dev\flutter_windows_3.41.2-stable\flutter\bin\flutter.bat clean

echo.
echo [2/5] Obteniendo dependencias...
C:\dev\flutter_windows_3.41.2-stable\flutter\bin\flutter.bat pub get

echo.
echo [3/5] Generando icono de la app...
C:\dev\flutter_windows_3.41.2-stable\flutter\bin\flutter.bat pub run flutter_launcher_icons

echo.
echo [4/5] Construyendo APK con nuevo logo...
C:\dev\flutter_windows_3.41.2-stable\flutter\bin\flutter.bat build apk --release

echo.
echo ========================================
echo   LISTO! APK GENERADA
echo ========================================
echo.
echo Ubicacion: build\app\outputs\flutter-apk\app-release.apk
echo.
echo Abriendo carpeta...
explorer build\app\outputs\flutter-apk

pause
