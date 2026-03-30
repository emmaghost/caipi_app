# ✅ EJECUCIÓN RÁPIDA: FORMULARIO ENTREVISTA A PADRES

## 🎯 RESUMEN EJECUTIVO

Se creó un **formulario completo de entrevista a padres** con 9 secciones que recoge toda la información necesaria antes de inscribir a un alumno.

---

## 🚀 PASOS PARA ACTIVAR (5 MIN)

### **1. EJECUTAR SQL EN SUPABASE** ⚡ (2 min)

1. Abre **Supabase** → Tu proyecto
2. Ve a **SQL Editor**
3. Click en **New Query**
4. Copia y pega el contenido de:

```
FIX_AGREGAR_ENTREVISTA_PADRES.sql
```

5. Click en **Run** (o presiona Ctrl+Enter)
6. ✅ Verifica que dice "Success" y no hay errores

---

### **2. REINICIAR LA APP** ⚡ (3 min)

La app ya se está reiniciando automáticamente...

Si necesitas hacerlo manualmente:
```bash
# Detener procesos
taskkill /F /IM java.exe /T
taskkill /F /IM dart.exe /T

# Reiniciar app
cd C:\laragon\www\app-caipi
flutter run --release -d emulator-5554
```

---

## 🧪 PRUEBA RÁPIDA (2 MIN)

### **Paso 1: Abrir formulario**
1. Abre la app
2. Menú → **Entrevista a Padres**
3. ✅ Debe abrir el formulario

### **Paso 2: Llenar primer paso**
1. Llena **Datos de la Madre**:
   - Nombre: María González
   - Edad: 32
   - Ocupación: Maestra
   - Dirección: Av. Juárez 123
   - Grado estudios: Licenciatura
   - Teléfono: 5512345678
2. Click en **Continuar**
3. ✅ Debe avanzar al Paso 2

### **Paso 3: Navegar pasos**
1. Click en **Atrás** → vuelve al Paso 1
2. Click en **Continuar** → avanza al Paso 2
3. Llena datos del padre (similares)
4. Click en **Continuar** → avanza al Paso 3
5. Así sucesivamente hasta el Paso 9

### **Paso 4: Guardar**
1. En el Paso 9, llena las expectativas
2. Click en **Guardar** (en lugar de "Continuar")
3. ✅ Debe mostrar: "Entrevista guardada exitosamente"
4. ✅ Debe regresar al dashboard

---

## 📋 SECCIONES DEL FORMULARIO

| Paso | Sección | Campos |
|------|---------|--------|
| 1️⃣ | Datos de la Madre | 6 campos |
| 2️⃣ | Datos del Padre | 6 campos |
| 3️⃣ | Dirección del Alumno | 6 campos (con dropdowns) |
| 4️⃣ | Información del Hogar | 9 campos (con switches) |
| 5️⃣ | Antecedentes | 5 campos |
| 6️⃣ | Padres Separados | 7 campos (opcional) |
| 7️⃣ | Aspecto Social del Hijo | 12 campos |
| 8️⃣ | Aspecto Social (Familia) | 13 campos |
| 9️⃣ | Expectativas | 3 campos |

**Total:** ~70 campos de información completa

---

## ✅ CARACTERÍSTICAS

- ✅ **Diseño:** Colores de CAIPI, iconos bonitos
- ✅ **Navegación:** Stepper con pasos (1-9)
- ✅ **Validación:** Campos requeridos
- ✅ **Condicional:** Secciones se muestran según respuestas
- ✅ **Permisos:** Solo directora puede crear/editar
- ✅ **Menú:** Acceso desde sección ALUMNOS
- ✅ **Guardado:** En Supabase con RLS

---

## 🎨 EJEMPLO VISUAL DEL FLUJO

```
📱 APP
 └─ 🏠 Dashboard
     └─ 📋 Menú
         └─ 👶 ALUMNOS
             └─ 📄 Entrevista a Padres
                 │
                 ├─ Paso 1: Datos Madre
                 ├─ Paso 2: Datos Padre
                 ├─ Paso 3: Dirección
                 ├─ Paso 4: Info Hogar
                 ├─ Paso 5: Antecedentes
                 ├─ Paso 6: Padres Separados (si aplica)
                 ├─ Paso 7: Aspecto Social Hijo
                 ├─ Paso 8: Aspecto Social Familia
                 └─ Paso 9: Expectativas
                     └─ 💾 Guardar
                         └─ ✅ Entrevista guardada!
```

---

## 🔧 VERIFICAR QUE TODO FUNCIONA

### ✅ **Checklist:**

- [ ] SQL ejecutado sin errores
- [ ] App reiniciada correctamente
- [ ] Opción "Entrevista a Padres" aparece en menú
- [ ] Formulario abre con Paso 1
- [ ] Botones "Continuar" y "Atrás" funcionan
- [ ] Switches y dropdowns funcionan
- [ ] Al guardar, muestra mensaje de éxito
- [ ] Regresa al dashboard después de guardar

---

## 🐛 SI HAY ERRORES

### **Error: "Table 'entrevistas_padres' does not exist"**
➡️ **Solución:** Ejecuta `FIX_AGREGAR_ENTREVISTA_PADRES.sql` en Supabase

### **Error: "Opción no aparece en menú"**
➡️ **Solución:** Reinicia la app completamente

### **Error: "Permission denied for table entrevistas_padres"**
➡️ **Solución:** Verifica que el SQL se ejecutó correctamente (crea RLS policies)

### **Error: "No se puede navegar entre pasos"**
➡️ **Solución:** Verifica que los campos requeridos estén llenos

---

## 📊 DATOS EN LA BASE DE DATOS

Después de guardar, verifica en Supabase:

1. Ve a **Table Editor**
2. Selecciona tabla: `entrevistas_padres`
3. ✅ Debe aparecer un registro nuevo con:
   - `id`: UUID generado
   - `alumno_id`: null (si no se asoció aún)
   - `padre_usuario_id`: ID de la directora que creó
   - `completado`: true
   - Todos los campos llenos

---

## 💡 USOS PRÁCTICOS

### **Caso 1: Inscripción nueva**
1. Padre llega con documentos
2. Directora llena entrevista
3. Guarda (se crea registro en BD)
4. Luego crea el alumno
5. (Opcional) Asocia entrevista al alumno

### **Caso 2: Actualizar información**
1. Buscar entrevista del alumno
2. Editar campos necesarios
3. Guardar cambios

---

## 📚 DOCUMENTACIÓN COMPLETA

Para más detalles, consulta:
- `GUIA_ENTREVISTA_PADRES.md` → Guía completa
- `FIX_AGREGAR_ENTREVISTA_PADRES.sql` → Script SQL
- `lib/screens/directora/entrevista_padres_screen.dart` → Código UI

---

## 🎯 SIGUIENTE PASO

**¿TODO FUNCIONA?** → Perfecto! Ya puedes usar la Entrevista a Padres.

**¿TIENES DUDAS?** → Revisa `GUIA_ENTREVISTA_PADRES.md`

**¿HAY ERRORES?** → Mándame screenshot del error

---

**¡Listo para usar!** 🚀

La app ya se está reiniciando automáticamente.
En 1-2 minutos podrás probar el formulario.
