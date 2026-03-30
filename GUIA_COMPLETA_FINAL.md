# 🚀 GUÍA COMPLETA FINAL - SISTEMA CAIPI

## ✅ **TODO LO QUE NECESITAS EJECUTAR**

Esta es la guía definitiva. Sigue estos pasos EN ORDEN y tendrás todo funcionando.

---

## 📋 **CHECKLIST COMPLETO:**

### ☑️ **PASO 1: Ejecutar SQL Maestro** (10 minutos)

1. Abre **Supabase Dashboard**
2. Ve a **SQL Editor**
3. Abre el archivo: `SQL_MAESTRO_COMPLETO.sql`
4. Copia TODO el contenido
5. Pega en Supabase SQL Editor
6. Click **Run** ▶️

**¿Qué hace?**
- ✅ Crea 22 tablas
- ✅ Configura RLS en todas
- ✅ Crea sistema de permisos completo
- ✅ Inserta datos iniciales (grados, roles, permisos, tipos incidentes)
- ✅ Crea triggers y funciones

**Resultado esperado:** "Success. No rows returned"

---

### ☑️ **PASO 2: Crear Bucket de Storage** (2 minutos)

1. En Supabase Dashboard → **Storage**
2. Click **New bucket**
3. Name: `galeria`
4. **Public bucket:** ✅ Marca como público
5. Click **Create bucket**

---

### ☑️ **PASO 3: Crear Usuario Directora** (3 minutos)

#### **3.1 Crear en Authentication:**
1. Supabase → **Authentication** → **Users**
2. Click **Add user** → **Create new user**
3. Email: `viri@caipi.com`
4. Password: `Caipi2026`
5. ✅ **Auto Confirm User** (marcar)
6. Click **Create user**
7. **COPIA EL UUID** (algo como: `75a24887-ed15...`)

#### **3.2 Insertar en tabla usuarios:**
```sql
INSERT INTO usuarios (id, email, rol, nombre, apellidos, telefono, whatsapp, activo)
VALUES (
  'PEGA-AQUI-EL-UUID',  -- ← Pega el UUID que copiaste
  'viri@caipi.com',
  'directora',
  'Viridiana',
  'García',
  '0000000000',
  '0000000000',
  true
)
ON CONFLICT (id) DO NOTHING;
```

---

### ☑️ **PASO 4: Configurar Emails** (5 minutos)

#### **4.1 Email de Confirmación:**
1. Supabase → **Authentication** → **Email Templates**
2. Click **Confirm signup**
3. Borra todo y pega:

```html
<h2>🎉 ¡Bienvenido a CAIPI!</h2>
<p>Hola,</p>
<p>Gracias por registrarte en el <strong>Sistema Escolar CAIPI</strong>.</p>
<p>Para completar tu registro, confirma tu correo electrónico:</p>
<p style="text-align: center; margin: 30px 0;">
  <a href="{{ .ConfirmationURL }}" style="display: inline-block; background: linear-gradient(135deg, #4A90E2 0%, #7B68EE 100%); color: #ffffff; text-decoration: none; padding: 16px 40px; border-radius: 12px; font-weight: 600; font-size: 16px;">
    ✅ Confirmar mi cuenta
  </a>
</p>
<p style="color: #666; font-size: 14px;">
  <strong>⚠️ Importante:</strong> Si no solicitaste esta cuenta, ignora este correo.
</p>
<p style="color: #999; font-size: 12px; margin-top: 30px; border-top: 1px solid #eee; padding-top: 20px;">
  <strong>Sistema Escolar CAIPI</strong><br>
  Gestionando la educación con tecnología 💙
</p>
```

4. Click **Save**

---

#### **4.2 Email de Recuperación de Contraseña:**
1. Click **Reset Password**
2. Borra todo y pega:

```html
<h2>🔑 Recupera tu contraseña - CAIPI</h2>
<p>Hola,</p>
<p>Recibimos una solicitud para restablecer tu contraseña del <strong>Sistema Escolar CAIPI</strong>.</p>
<p>Para crear una nueva contraseña:</p>
<p style="text-align: center; margin: 30px 0;">
  <a href="{{ .ConfirmationURL }}" style="display: inline-block; background: linear-gradient(135deg, #4A90E2 0%, #7B68EE 100%); color: #ffffff; text-decoration: none; padding: 16px 40px; border-radius: 12px; font-weight: 600; font-size: 16px;">
    🔒 Restablecer contraseña
  </a>
</p>
<div style="background-color: #FFF9E6; border-left: 4px solid #FFB800; padding: 15px; border-radius: 8px; margin: 20px 0;">
  <p style="color: #856404; font-size: 14px; margin: 0;">
    <strong>⚠️ Seguridad:</strong> Si no solicitaste esto, ignora este correo.
  </p>
</div>
<p style="color: #666; font-size: 13px;">
  Este enlace expira en 1 hora por seguridad.
</p>
<p style="color: #999; font-size: 12px; margin-top: 30px; border-top: 1px solid #eee; padding-top: 20px;">
  <strong>Sistema Escolar CAIPI</strong> 💙
</p>
```

3. Click **Save**

---

#### **4.3 Email de Invitación:**
1. Click **Invite user**
2. Borra todo y pega:

```html
<h2>🎓 Invitación a CAIPI</h2>
<p>Hola,</p>
<p>Has sido invitado/a a unirte al <strong>Sistema Escolar CAIPI</strong>.</p>
<p>Para aceptar la invitación:</p>
<p style="text-align: center; margin: 30px 0;">
  <a href="{{ .ConfirmationURL }}" style="display: inline-block; background: linear-gradient(135deg, #4A90E2 0%, #7B68EE 100%); color: #ffffff; text-decoration: none; padding: 16px 40px; border-radius: 12px; font-weight: 600; font-size: 16px;">
    📚 Aceptar invitación
  </a>
</p>
<p style="color: #999; font-size: 12px; margin-top: 30px;">
  <strong>Sistema Escolar CAIPI</strong> 💙
</p>
```

3. Click **Save**

---

#### **4.4 Email de Cambio de Correo:**
1. Click **Change Email Address**
2. Borra todo y pega:

```html
<h2>✉️ Confirma tu nuevo correo - CAIPI</h2>
<p>Hola,</p>
<p>Recibimos una solicitud para cambiar el correo de tu cuenta CAIPI.</p>
<p>Para confirmar:</p>
<p style="text-align: center; margin: 30px 0;">
  <a href="{{ .ConfirmationURL }}" style="display: inline-block; background: linear-gradient(135deg, #4A90E2 0%, #7B68EE 100%); color: #ffffff; text-decoration: none; padding: 16px 40px; border-radius: 12px; font-weight: 600; font-size: 16px;">
    ✅ Confirmar nuevo correo
  </a>
</p>
<p style="color: #999; font-size: 12px; margin-top: 30px;">
  <strong>Sistema Escolar CAIPI</strong> 💙
</p>
```

3. Click **Save**

---

#### **4.5 Magic Link (Opcional):**
1. Click **Magic Link**
2. Borra todo y pega:

```html
<h2>🔐 Tu enlace de acceso - CAIPI</h2>
<p>Hola,</p>
<p>Usa este enlace para acceder al <strong>Sistema Escolar CAIPI</strong>:</p>
<p style="text-align: center; margin: 30px 0;">
  <a href="{{ .ConfirmationURL }}" style="display: inline-block; background: linear-gradient(135deg, #4A90E2 0%, #7B68EE 100%); color: #ffffff; text-decoration: none; padding: 16px 40px; border-radius: 12px; font-weight: 600; font-size: 16px;">
    🚀 Acceder ahora
  </a>
</p>
<p style="color: #666; font-size: 13px;">
  Este enlace expira en 24 horas.
</p>
<p style="color: #999; font-size: 12px; margin-top: 30px;">
  <strong>Sistema Escolar CAIPI</strong> 💙
</p>
```

3. Click **Save**

---

### ☑️ **PASO 5: Ejecutar la App** (2 minutos)

```powershell
cd C:\laragon\www\app-caipi
flutter pub get
flutter run
```

**Login:**
- Email: `viri@caipi.com`
- Password: `Caipi2026`

---

## 🎯 **VERIFICACIÓN:**

### **1. Base de Datos:**
```sql
-- Verificar tablas creadas
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

**Deberías ver 22 tablas:**
- usuarios
- grados
- profesores
- alumnos
- personas_autorizadas
- pagos
- calificaciones
- tipos_incidentes
- incidentes
- anuncios
- eventos
- bitacora_diaria
- control_salidas
- menu_maternal
- notificaciones
- galeria
- clases_extracurriculares
- participantes_clases
- roles
- permisos
- roles_permisos
- usuarios_permisos

---

### **2. Grados:**
```sql
SELECT nombre, edad_minima, edad_maxima, cupo_maximo 
FROM grados 
ORDER BY edad_minima;
```

**Deberías ver 6 grados:**
- Maternal 1, 2, 3
- Kinder 1, 2, 3

---

### **3. Permisos:**
```sql
SELECT COUNT(*) as total FROM permisos;
```

**Deberías ver:** ~24 permisos

---

### **4. Roles:**
```sql
SELECT * FROM roles ORDER BY nivel_jerarquia;
```

**Deberías ver 4 roles:**
- directora
- profesor_admin
- profesor
- padre

---

### **5. Tipos de Incidentes:**
```sql
SELECT nombre, nivel, categoria FROM tipos_incidentes ORDER BY nivel;
```

**Deberías ver 15 tipos de incidentes**

---

## 📊 **ESTADO FINAL:**

| Categoría | Items | Estado |
|-----------|-------|--------|
| Tablas | 22 | ✅ |
| Grados | 6 | ✅ |
| Roles | 4 | ✅ |
| Permisos | ~24 | ✅ |
| Tipos Incidentes | 15 | ✅ |
| RLS Policies | Todas | ✅ |
| Email Templates | 5 | ✅ |
| Notificaciones | Listas | ✅ |

---

## 🚨 **ERRORES COMUNES:**

### **Error: relation already exists**
**Solución:** Normal, significa que esa tabla ya existe. El SQL usa `IF NOT EXISTS`.

### **Error: duplicate key**
**Solución:** Normal, significa que esos datos ya existen. El SQL usa `ON CONFLICT DO NOTHING`.

### **Error: flutter not recognized**
**Solución:**
```powershell
$env:Path += ";C:\dev\flutter_windows_3.41.2-stable\flutter\bin"
```

### **Error: No se puede login**
**Solución:** Verifica que:
1. Creaste el usuario en Authentication
2. Insertaste el registro en la tabla `usuarios`
3. El UUID coincide en ambos

---

## 📱 **MÓDULOS COMPLETOS:**

1. ✅ Login y Autenticación
2. ✅ Gestión de Alumnos
3. ✅ Gestión de Pagos
4. ✅ Gestión de Profesores
5. ✅ Gestión de Padres
6. ✅ Personas Autorizadas
7. ✅ Eventos
8. ✅ Incidentes (con catálogo)
9. ✅ Bitácora Diaria
10. ✅ Control de Salidas
11. ✅ Calificaciones
12. ✅ Anuncios
13. ✅ Menú Maternal
14. ✅ Galería de Fotos
15. ✅ Clases Extracurriculares
16. ✅ Sistema de Permisos
17. ✅ Emails Personalizados
18. ✅ Notificaciones In-App

**TOTAL: 18/18 módulos (100%)** 🎉

---

## 🎯 **SIGUIENTE PASO (OPCIONAL):**

### **Sistema QR para Personas Autorizadas**
- Genera QR por persona
- Escanea al recoger niño
- Registro automático

**Complejidad:** Media (2-3 horas)  
**¿Lo implemento?** Avísame si lo necesitas.

---

## ✅ **¡LISTO!**

Sigue los 5 pasos en orden y tendrás todo funcionando.

**¿Dudas?** Avísame y te ayudo. 🚀
