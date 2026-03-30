# 🔥 Migración a Supabase - Instrucciones

## ✅ CAMBIOS REALIZADOS:

1. ✅ Dependencias actualizadas a Supabase
2. ✅ Servicios migrados (Auth, Database, Storage)
3. ✅ Modelos adaptados (toJson/fromJson)
4. ✅ Pantallas actualizadas
5. ✅ Credenciales configuradas

---

## 📋 SIGUIENTES PASOS:

### **PASO 1: Crear las Tablas en Supabase** ⏱️ 10 min

Ve a tu Dashboard de Supabase → **SQL Editor** y ejecuta estos scripts:

#### **1. Tabla usuarios:**

```sql
CREATE TABLE usuarios (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  nombre TEXT NOT NULL,
  telefono TEXT,
  rol TEXT NOT NULL CHECK (rol IN ('directora', 'padre')),
  hijos TEXT[] DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Habilitar RLS (Row Level Security)
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;

-- Políticas de seguridad
CREATE POLICY "Usuarios pueden ver su propia información"
  ON usuarios FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Directora puede ver todos los usuarios"
  ON usuarios FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM usuarios
    WHERE id = auth.uid() AND rol = 'directora'
  ));
```

#### **2. Tabla alumnos:**

```sql
CREATE TABLE alumnos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nombre TEXT NOT NULL,
  apellidos TEXT NOT NULL,
  fecha_nacimiento TIMESTAMP NOT NULL,
  grado TEXT NOT NULL,
  foto_url TEXT,
  padre_id UUID REFERENCES usuarios(id),
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE alumnos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Padres pueden ver sus hijos"
  ON alumnos FOR SELECT
  USING (padre_id = auth.uid());

CREATE POLICY "Directora puede ver todos los alumnos"
  ON alumnos FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM usuarios
    WHERE id = auth.uid() AND rol = 'directora'
  ));

CREATE POLICY "Directora puede modificar alumnos"
  ON alumnos FOR ALL
  USING (EXISTS (
    SELECT 1 FROM usuarios
    WHERE id = auth.uid() AND rol = 'directora'
  ));
```

#### **3. Tabla pagos:**

```sql
CREATE TABLE pagos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  alumno_id UUID REFERENCES alumnos(id) ON DELETE CASCADE,
  mes TEXT NOT NULL,
  monto DECIMAL(10,2) NOT NULL,
  concepto TEXT NOT NULL,
  pagado BOOLEAN DEFAULT false,
  fecha_limite TIMESTAMP NOT NULL,
  fecha_pago TIMESTAMP,
  metodo_pago TEXT,
  comprobante_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE pagos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Padres pueden ver pagos de sus hijos"
  ON pagos FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM alumnos
    WHERE alumnos.id = pagos.alumno_id
    AND alumnos.padre_id = auth.uid()
  ));

CREATE POLICY "Directora puede gestionar pagos"
  ON pagos FOR ALL
  USING (EXISTS (
    SELECT 1 FROM usuarios
    WHERE id = auth.uid() AND rol = 'directora'
  ));
```

#### **4. Tabla calificaciones:**

```sql
CREATE TABLE calificaciones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  alumno_id UUID REFERENCES alumnos(id) ON DELETE CASCADE,
  materia TEXT NOT NULL,
  calificacion DECIMAL(4,2) NOT NULL,
  periodo TEXT NOT NULL,
  comentarios TEXT,
  fecha TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE calificaciones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Padres pueden ver calificaciones de sus hijos"
  ON calificaciones FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM alumnos
    WHERE alumnos.id = calificaciones.alumno_id
    AND alumnos.padre_id = auth.uid()
  ));

CREATE POLICY "Directora puede gestionar calificaciones"
  ON calificaciones FOR ALL
  USING (EXISTS (
    SELECT 1 FROM usuarios
    WHERE id = auth.uid() AND rol = 'directora'
  ));
```

#### **5. Tabla incidentes:**

```sql
CREATE TABLE incidentes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  alumno_id UUID REFERENCES alumnos(id) ON DELETE CASCADE,
  tipo TEXT NOT NULL CHECK (tipo IN ('accidente', 'conducta', 'enfermedad')),
  descripcion TEXT NOT NULL,
  gravedad TEXT NOT NULL CHECK (gravedad IN ('leve', 'moderado', 'grave')),
  atendido BOOLEAN DEFAULT false,
  padre_notificado BOOLEAN DEFAULT false,
  fecha TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reportado_por UUID REFERENCES usuarios(id)
);

ALTER TABLE incidentes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Padres pueden ver incidentes de sus hijos"
  ON incidentes FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM alumnos
    WHERE alumnos.id = incidentes.alumno_id
    AND alumnos.padre_id = auth.uid()
  ));

CREATE POLICY "Directora puede gestionar incidentes"
  ON incidentes FOR ALL
  USING (EXISTS (
    SELECT 1 FROM usuarios
    WHERE id = auth.uid() AND rol = 'directora'
  ));
```

#### **6. Tabla anuncios:**

```sql
CREATE TABLE anuncios (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  titulo TEXT NOT NULL,
  mensaje TEXT NOT NULL,
  prioridad TEXT DEFAULT 'normal' CHECK (prioridad IN ('alta', 'normal')),
  fecha_publicacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  fecha_evento TIMESTAMP,
  leido_por TEXT[] DEFAULT '{}',
  creado_por UUID REFERENCES usuarios(id)
);

ALTER TABLE anuncios ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Todos pueden ver anuncios"
  ON anuncios FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Directora puede crear/editar anuncios"
  ON anuncios FOR ALL
  USING (EXISTS (
    SELECT 1 FROM usuarios
    WHERE id = auth.uid() AND rol = 'directora'
  ));
```

#### **7. Tabla grados:**

```sql
CREATE TABLE grados (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nombre TEXT NOT NULL UNIQUE,
  nivel TEXT NOT NULL,
  ciclo_escolar TEXT NOT NULL,
  total_alumnos INTEGER DEFAULT 0
);

ALTER TABLE grados ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Todos pueden ver grados"
  ON grados FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Directora puede gestionar grados"
  ON grados FOR ALL
  USING (EXISTS (
    SELECT 1 FROM usuarios
    WHERE id = auth.uid() AND rol = 'directora'
  ));
```

---

### **PASO 2: Configurar Storage (para fotos)** ⏱️ 3 min

1. En Supabase Dashboard, ve a **Storage**
2. Click **"Create bucket"**
3. Nombre: `fotos`
4. **Public:** Marca como público (para poder ver las fotos)
5. Click **"Create bucket"**

#### Configurar políticas de Storage:

Ve a Storage → fotos → **Policies** y crea:

```sql
-- Permitir lectura pública
CREATE POLICY "Fotos públicas para lectura"
ON storage.objects FOR SELECT
USING (bucket_id = 'fotos');

-- Permitir subida autenticada
CREATE POLICY "Usuarios autenticados pueden subir"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'fotos');

-- Permitir actualización autenticada
CREATE POLICY "Usuarios autenticados pueden actualizar"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'fotos');
```

---

### **PASO 3: Crear Usuario Directora** ⏱️ 2 min

1. Ve a **Authentication** → **Users**
2. Click **"Add user"** → **"Create new user"**
3. Email: `directora@escuela.com`
4. Password: `escuela123` (o la que prefieras)
5. Click **"Create user"**
6. **COPIA el UUID** del usuario creado

Luego ejecuta en SQL Editor:

```sql
INSERT INTO usuarios (id, email, nombre, telefono, rol, hijos)
VALUES (
  'UUID-QUE-COPIASTE',  -- Reemplaza con el UUID real
  'directora@escuela.com',
  'Ana María López',
  '5512345678',
  'directora',
  '{}'
);
```

---

### **PASO 4: Instalar Dependencias y Ejecutar** ⏱️ 5 min

En PowerShell:

```powershell
cd C:\laragon\www\app-caipi
flutter pub get
```

Espera 2-3 minutos.

Luego ejecuta:

```powershell
flutter run
```

---

## 🎉 ¡LISTO!

La app ahora usa Supabase:
- ✅ Sin tarjeta de crédito
- ✅ Storage incluido (fotos)
- ✅ Base de datos PostgreSQL
- ✅ Authentication seguro
- ✅ Todo gratis

---

## 📊 Resumen de Credenciales:

**Supabase:**
- URL: `https://qxldfqnuwpucptajcazf.supabase.co`
- Anon Key: (ya configurada en el código)

**Usuario Directora:**
- Email: `directora@escuela.com`
- Password: `escuela123`

---

¡A probar! 🚀
