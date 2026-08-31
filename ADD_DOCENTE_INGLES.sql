-- Docente titular + maestra de inglés en el mismo grupo.
-- La columna profesores.especialidad ya existe. No cambia el esquema.
--
-- Valores:
--   titular  = maestra de grupo (bitácora, chat, alumnos…)
--   ingles   = otro usuario; ve el grupo pero solo calificaciones de Inglés.
--
-- Pueden coexistir 2 filas con el mismo grado_id (titular + inglés).
-- Si la de inglés da a varios kínder, deja grado_id NULL.

COMMENT ON COLUMN public.profesores.especialidad IS
  'titular = maestra de grupo; ingles = maestra de inglés (menú limitado a calificaciones de Inglés).';
