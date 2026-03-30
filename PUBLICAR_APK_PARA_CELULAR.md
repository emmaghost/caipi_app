# 📱 CÓMO PUBLICAR LA APP CAIPI EN TU CELULAR

## 🎯 **2 OPCIONES:**

### **OPCIÓN 1: APK DE PRUEBA** (5 minutos) ⚡
✅ Rápido y fácil  
✅ Para probar en tu celular  
❌ No para producción  
❌ No se puede subir a Play Store  

### **OPCIÓN 2: APK FIRMADO** (15 minutos) 🏆
✅ Profesional y seguro  
✅ Listo para distribuir  
✅ Se puede subir a Play Store  
✅ Permite actualizaciones  

---

## ⚡ **OPCIÓN 1: APK DE PRUEBA (RECOMENDADO PARA EMPEZAR)**

### **Paso 1: Generar APK de Debug**

```powershell
cd C:\laragon\www\app-caipi
C:\dev\flutter_windows_3.41.2-stable\flutter\bin\flutter.bat build apk --debug
```

⏱️ **Tiempo:** ~3-5 minutos

✅ **Resultado:** 
```
APK generado en:
build\app\outputs\flutter-apk\app-debug.apk
```

---

### **Paso 2: Transferir al Celular**

**Método A: Cable USB**
1. Conecta tu celular a la PC con cable USB
2. En el celular: acepta "Transferir archivos"
3. Copia `app-debug.apk` a la carpeta `Descargas` del celular

**Método B: Google Drive / WhatsApp / Email**
1. Sube `app-debug.apk` a Drive/WhatsApp/Email
2. Ábrelo desde tu celular

**Método C: Compartir por Red Local**
```powershell
# Servidor simple para descargar
cd C:\laragon\www\app-caipi\build\app\outputs\flutter-apk
python -m http.server 8080
```
Luego en tu celular: `http://TU-IP-PC:8080` y descarga el APK

---

### **Paso 3: Instalar en el Celular**

1. **Habilitar instalación de fuentes desconocidas:**
   - Ve a: **Configuración → Seguridad → Fuentes desconocidas**
   - O: **Configuración → Apps → Acceso especial → Instalar apps desconocidas**
   - Habilita para **Chrome/Archivos/WhatsApp** (lo que uses)

2. **Instalar:**
   - Abre el archivo `app-debug.apk` desde tu celular
   - Click **Instalar**
   - Click **Abrir**

✅ **¡Listo!** La app CAIPI estará instalada 🎉

---

## 🏆 **OPCIÓN 2: APK FIRMADO (PRODUCCIÓN)**

### **Paso 1: Crear Keystore (Solo 1 vez)**

```powershell
cd C:\laragon\www\app-caipi\android

keytool -genkey -v -keystore caipi-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias caipi
```

**Te pedirá:**
- 🔑 **Contraseña del keystore:** `TuContraseñaSegura123`
- 🔑 **Contraseña del alias:** `TuContraseñaSegura123` (misma)
- 📝 **Nombre y apellido:** `Escuela CAIPI`
- 📝 **Unidad organizativa:** `Educación`
- 📝 **Organización:** `CAIPI`
- 📝 **Ciudad:** `Tu Ciudad`
- 📝 **Estado:** `Tu Estado`
- 📝 **Código país (MX):** `MX`

⚠️ **IMPORTANTE:** Guarda estas contraseñas en un lugar seguro. Las necesitarás para cada actualización.

---

### **Paso 2: Configurar Keystore**

Crea archivo: `android/key.properties`

```properties
storePassword=TuContraseñaSegura123
keyPassword=TuContraseñaSegura123
keyAlias=caipi
storeFile=caipi-release-key.jks
```

⚠️ **SEGURIDAD:** Agrega a `.gitignore`:
```
android/key.properties
android/*.jks
```

---

### **Paso 3: Actualizar build.gradle**

Edita: `android/app/build.gradle`

**Agrega ANTES de `android {`:**

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

**Agrega DENTRO de `android { ... }` DESPUÉS de `defaultConfig {}`:**

```gradle
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
```

---

### **Paso 4: Actualizar AndroidManifest.xml**

Edita: `android/app/src/main/AndroidManifest.xml`

**Agrega permisos ANTES de `<application>`:**

```xml
    <!-- Permisos necesarios -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

**Actualiza el label:**

```xml
<application
    android:label="CAIPI"
    ...
```

---

### **Paso 5: Generar APK Release**

```powershell
cd C:\laragon\www\app-caipi
C:\dev\flutter_windows_3.41.2-stable\flutter\bin\flutter.bat build apk --release
```

⏱️ **Tiempo:** ~5-10 minutos

✅ **Resultado:**
```
APK generado en:
build\app\outputs\flutter-apk\app-release.apk
```

**Tamaño:** ~15-30 MB (optimizado)

---

### **Paso 6: Instalar en Celular**

Igual que la Opción 1:
1. Transfiere `app-release.apk` a tu celular
2. Instala desde **Archivos**

---

## 📦 **COMPARACIÓN:**

| Característica | APK Debug | APK Release |
|----------------|-----------|-------------|
| **Tamaño** | ~40-60 MB | ~15-30 MB |
| **Velocidad** | Lenta | Rápida ⚡ |
| **Optimización** | ❌ No | ✅ Sí |
| **Play Store** | ❌ No | ✅ Sí |
| **Firma** | Temporal | Permanente |
| **Actualizaciones** | ❌ No | ✅ Sí |
| **Tiempo build** | 3-5 min | 5-10 min |

---

## 🌐 **OPCIONES DE DISTRIBUCIÓN:**

### **1. Instalación Directa (Sin Store)** 🔓
✅ Más rápido  
✅ Sin costos  
✅ Sin revisión  
❌ Requiere "fuentes desconocidas"  
❌ Sin actualizaciones automáticas  

**Ideal para:** Pruebas internas, staff de la escuela

---

### **2. Google Play Store** 🏪
✅ Actualizaciones automáticas  
✅ Confianza del usuario  
✅ Estadísticas de uso  
💰 **Costo:** $25 USD (una sola vez, de por vida)  
⏱️ **Revisión:** 1-3 días  

**Ideal para:** Distribución a todos los padres

---

### **3. App Bundle (Recomendado para Play Store)** 📦

En lugar de APK, genera AAB:

```powershell
C:\dev\flutter_windows_3.41.2-stable\flutter\bin\flutter.bat build appbundle --release
```

**Ventajas:**
- ✅ Tamaño más pequeño (~30% menos)
- ✅ Optimizado por dispositivo
- ✅ Requerido por Play Store (desde 2021)

**Resultado:**
```
build\app\outputs\bundle\release\app-release.aab
```

---

## 🍎 **¿Y PARA iOS (iPhone/iPad)?**

### **Requisitos:**
- 💻 **Mac** con macOS
- 🍎 **Xcode** instalado
- 💳 **Apple Developer Account** ($99 USD/año)

### **Comando:**
```bash
flutter build ios --release
```

### **Distribución iOS:**
1. **TestFlight** (beta testing)
2. **App Store** (producción)

**⚠️ Limitación:** No se puede compilar para iOS desde Windows directamente.

**Alternativa:** Servicios cloud como **Codemagic** o **AppCenter**

---

## 🚀 **RECOMENDACIÓN PARA TU CASO:**

### **FASE 1: PRUEBAS (AHORA)** 🧪
```powershell
flutter build apk --debug
```
- Distribuye a: Directora + 2-3 profesoras
- Prueba todas las funciones
- Recopila feedback

---

### **FASE 2: PILOTO (1-2 SEMANAS)** 🎯
```powershell
flutter build apk --release
```
- Distribuye a: Todo el staff + 10 padres
- Verifica estabilidad
- Ajusta según feedback

---

### **FASE 3: PRODUCCIÓN (1 MES)** 🏆
```powershell
flutter build appbundle --release
```
- Publica en: Google Play Store
- Distribuye a: Todos los padres
- Actualizaciones automáticas

---

## 📝 **CHECKLIST ANTES DE PUBLICAR:**

### **Información de la App:**
- [ ] Nombre: **CAIPI**
- [ ] Package: `com.escuela.caipi`
- [ ] Versión: `1.0.0`
- [ ] Ícono: Logo CAIPI
- [ ] Splash screen: Logo + colores

### **Permisos:**
- [ ] Internet ✅
- [ ] Notificaciones ✅
- [ ] Almacenamiento (fotos) ✅

### **Testing:**
- [ ] Login funciona
- [ ] Roles funcionan (directora, profesor, padre)
- [ ] CRUD de alumnos
- [ ] Pagos
- [ ] Notificaciones

---

## 🔧 **COMANDOS RÁPIDOS:**

### **Para Pruebas (Rápido):**
```powershell
cd C:\laragon\www\app-caipi
C:\dev\flutter_windows_3.41.2-stable\flutter\bin\flutter.bat build apk --debug
```

### **Para Producción (Optimizado):**
```powershell
cd C:\laragon\www\app-caipi
C:\dev\flutter_windows_3.41.2-stable\flutter\bin\flutter.bat build apk --release
```

### **Ver APK Generado:**
```powershell
explorer build\app\outputs\flutter-apk
```

---

## 📲 **INSTALAR EN TU CELULAR:**

### **Opción A: WhatsApp** (Más Fácil)
1. Envíate el APK por WhatsApp (a ti mismo)
2. Descárgalo en tu celular
3. Abre desde WhatsApp
4. Instala

### **Opción B: USB**
1. Conecta celular con cable
2. Copia APK a carpeta Descargas
3. Abre desde explorador de archivos
4. Instala

### **Opción C: Drive**
1. Sube APK a Google Drive
2. Comparte link
3. Descarga desde celular
4. Instala

---

## ⚠️ **IMPORTANTE:**

### **Primera instalación:**
Tu celular dirá: **"App no verificada"** o **"Fuente desconocida"**

**Esto es normal** ✅

**Solución:**
1. Ve a **Configuración → Seguridad**
2. Busca **"Instalar apps desconocidas"**
3. Activa para la app que usas (Chrome/Archivos/WhatsApp)
4. Regresa e instala

---

## 🎨 **PERSONALIZACIÓN FINAL:**

Antes de generar el APK, verifica:

### **1. Nombre de la App**
Edita: `android/app/src/main/AndroidManifest.xml`
```xml
<application
    android:label="CAIPI"
```

### **2. Package Name**
Edita: `android/app/build.gradle`
```gradle
defaultConfig {
    applicationId "com.escuela.caipi"
```

### **3. Versión**
Edita: `pubspec.yaml`
```yaml
version: 1.0.0+1
```
(Formato: `versión+número_build`)

---

## 🚀 **COMANDO COMPLETO - COPIA Y PEGA:**

```powershell
# 1. Ir a la carpeta del proyecto
cd C:\laragon\www\app-caipi

# 2. Limpiar builds anteriores
C:\dev\flutter_windows_3.41.2-stable\flutter\bin\flutter.bat clean

# 3. Actualizar dependencias
C:\dev\flutter_windows_3.41.2-stable\flutter\bin\flutter.bat pub get

# 4. Generar APK de prueba
C:\dev\flutter_windows_3.41.2-stable\flutter\bin\flutter.bat build apk --debug

# 5. Abrir carpeta con el APK
explorer build\app\outputs\flutter-apk
```

**Resultado:** Se abrirá la carpeta con `app-debug.apk` listo para transferir 📱

---

## 📊 **TAMAÑOS ESPERADOS:**

- **APK Debug:** ~40-60 MB
- **APK Release:** ~15-30 MB
- **AAB (Play Store):** ~12-25 MB

---

## 🔐 **PARA APK FIRMADO (PRODUCCIÓN):**

Si quieres el APK profesional firmado, necesitas:

### **1. Crear Keystore:**
```powershell
cd C:\laragon\www\app-caipi\android

"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore caipi-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias caipi
```

**Datos a ingresar:**
- Password del keystore: `Caipi2026@Key` (ejemplo)
- Password del alias: `Caipi2026@Key` (misma)
- Nombre: `Escuela CAIPI`
- Organización: `CAIPI`
- Ciudad: `Tu Ciudad`
- Estado: `Tu Estado`
- Código país: `MX`

⚠️ **¡GUARDA ESTAS CONTRASEÑAS!** Las necesitarás siempre.

---

### **2. Crear key.properties:**

Crea: `android/key.properties`

```properties
storePassword=Caipi2026@Key
keyPassword=Caipi2026@Key
keyAlias=caipi
storeFile=caipi-release-key.jks
```

---

### **3. Configurar build.gradle:**

Edita: `android/app/build.gradle`

**AGREGA ANTES DE `android {`:**

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

**AGREGA DENTRO DE `android { ... }` ANTES DE `buildTypes {}`:**

```gradle
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
```

**MODIFICA `buildTypes { release { ... } }`:**

```gradle
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
```

---

### **4. Generar APK Firmado:**

```powershell
cd C:\laragon\www\app-caipi
C:\dev\flutter_windows_3.41.2-stable\flutter\bin\flutter.bat build apk --release
```

✅ **Resultado:** `build\app\outputs\flutter-apk\app-release.apk` (FIRMADO)

---

## 📱 **DIFERENCIAS APK DEBUG vs RELEASE:**

### **APK Debug:**
```
✅ Rápido de generar (3-5 min)
✅ Fácil de crear (1 comando)
❌ Grande (~50 MB)
❌ Lento al ejecutar
❌ No optimizado
❌ No se puede actualizar
✅ Perfecto para PROBAR
```

### **APK Release:**
```
✅ Optimizado (~20 MB)
✅ Rápido al ejecutar
✅ Firmado y seguro
✅ Se puede actualizar
✅ Listo para producción
⏱️ Tarda más en generar (5-10 min)
🔧 Requiere configuración inicial
✅ Perfecto para DISTRIBUIR
```

---

## 🎯 **MI RECOMENDACIÓN:**

### **PARA HOY (PROBAR):**
```powershell
flutter build apk --debug
```
- Pruébala en tu celular
- Verifica que todo funcione
- Comparte con 2-3 profesoras

### **PARA MAÑANA (DISTRIBUIR):**
```powershell
# Configura keystore (15 min)
# Genera APK firmado (10 min)
flutter build apk --release
```
- Comparte con todo el staff
- Listo para padres de familia

---

## 🏪 **PUBLICAR EN PLAY STORE (OPCIONAL):**

Si quieres que los padres la descarguen desde Play Store:

### **Requisitos:**
- 💳 **$25 USD** (una sola vez, de por vida)
- 📱 **Cuenta Google Developer**
- 📋 **Descripción de la app**
- 🖼️ **Screenshots** (mínimo 2)
- 🎨 **Banner/Ícono** de alta calidad

### **Proceso:**
1. Crea cuenta en: [play.google.com/console](https://play.google.com/console)
2. Paga $25 USD (una sola vez)
3. Genera **AAB** (no APK):
   ```powershell
   flutter build appbundle --release
   ```
4. Sube `app-release.aab`
5. Completa información (nombre, descripción, screenshots)
6. Envía a revisión
7. ⏱️ Espera 1-3 días
8. ✅ ¡App publicada!

---

## 🎨 **ANTES DE PUBLICAR - MEJORAS FINALES:**

### **1. Actualizar Ícono:**
Ya configurado en `pubspec.yaml`:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/logo_caipi.jpg"
```

**Generar íconos:**
```powershell
C:\dev\flutter_windows_3.41.2-stable\flutter\bin\flutter.bat pub run flutter_launcher_icons
```

### **2. Actualizar Splash Screen:**
Edita: `android/app/src/main/res/drawable/launch_background.xml`

---

## 🔧 **SOLUCIÓN DE PROBLEMAS:**

### **Error: "Failed to install"**
- ✅ Desinstala versión anterior
- ✅ Habilita fuentes desconocidas
- ✅ Verifica espacio disponible

### **Error: "App keeps stopping"**
- ✅ Genera APK release (no debug)
- ✅ Verifica permisos en AndroidManifest.xml
- ✅ Revisa logs: `flutter logs`

### **Error: "keystore not found"**
- ✅ Verifica ruta en `key.properties`
- ✅ Keystore debe estar en `android/`

---

## ✅ **RESUMEN RÁPIDO:**

### **AHORA (5 MINUTOS):**
```powershell
cd C:\laragon\www\app-caipi
C:\dev\flutter_windows_3.41.2-stable\flutter\bin\flutter.bat build apk --debug
explorer build\app\outputs\flutter-apk
```
→ Copia `app-debug.apk` a tu celular e instala

### **DESPUÉS (15 MINUTOS):**
1. Crea keystore
2. Configura key.properties
3. Actualiza build.gradle
4. `flutter build apk --release`
5. Distribuye `app-release.apk`

---

## 📞 **NECESITAS AYUDA?**

Si algo no funciona:
1. Copia el error exacto
2. Copia el comando que ejecutaste
3. Pregúntame y lo resolvemos

---

🎉 **¡Tu app CAIPI lista para el celular en minutos!** 📱
