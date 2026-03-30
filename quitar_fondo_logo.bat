@echo off
echo ========================================
echo   QUITAR FONDO NEGRO DEL LOGO
echo ========================================
echo.
echo PASOS:
echo.
echo 1. Se va a abrir remove.bg en tu navegador
echo 2. Sube la imagen: logo_caipi.jpeg
echo 3. Descarga el PNG sin fondo
echo 4. Guardalo como: logo_caipi.png
echo 5. Ponlo en: assets\images\
echo.
echo Abriendo remove.bg...
start https://www.remove.bg/es/upload
echo.
echo ========================================
echo.
echo Una vez que hayas guardado logo_caipi.png
echo en assets\images\, presiona cualquier tecla
echo para continuar con la actualizacion...
echo.
pause

echo.
echo Verificando que exista logo_caipi.png...
if not exist "assets\images\logo_caipi.png" (
    echo.
    echo ERROR: No se encuentra logo_caipi.png
    echo Por favor guardalo en: assets\images\logo_caipi.png
    echo.
    pause
    exit /b 1
)

echo.
echo Logo encontrado! Actualizando codigo...
echo.

echo [1/3] Limpiando cache...
C:\dev\flutter_windows_3.41.2-stable\flutter\bin\flutter.bat clean

echo.
echo [2/3] Obteniendo dependencias...
C:\dev\flutter_windows_3.41.2-stable\flutter\bin\flutter.bat pub get

echo.
echo [3/3] Generando nuevo icono...
C:\dev\flutter_windows_3.41.2-stable\flutter\bin\flutter.bat pub run flutter_launcher_icons

echo.
echo ========================================
echo   ICONO ACTUALIZADO
echo ========================================
echo.
echo Ahora reinicia la app en el emulador:
echo   Presiona 'R' en la terminal de Flutter
echo.
echo O genera APK final:
echo   flutter build apk --release
echo.
pause
