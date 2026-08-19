# Diseño · Rol de profesor

Fecha: 2026-08-18
Estado: aprobado por Roberto (pendiente de plan de implementación)

## Problema

Hoy no existen usuarios administrativos: existe **una clave global**
(`config.admin_clave`, hoy `112358`) que abre el Modo Admin y da acceso total a **todos**
los cursos y alumnos. La tabla `cursos` no tiene dueño, así que quien tiene la clave crea,
edita y borra cualquier cosa. Además esa clave está en el repositorio, porque se comparte
con el tablero de avance: es un bloqueo suave, no seguridad.

Ese modelo alcanzaba mientras el único administrador era Roberto. Deja de alcanzar en
cuanto entran profesores de un colegio real, porque cada uno administraría datos de niños
que no son suyos y podría borrar los cursos de los demás.

## Decisiones tomadas

| Decisión | Elección |
| --- | --- |
| Quiénes serán profesores | Docentes de un colegio real, no solo gente de confianza |
| Cómo nace una cuenta | **Roberto autoriza el correo**; el profesor se registra con él |
| Qué puede hacer un profesor | **Autonomía total sobre sus cursos**, nada sobre los ajenos |
| Por dónde entra | Una **página propia** (`profesor.html`), separada del juego |
| Autenticación | **Correo y contraseña** (Supabase Auth), con lista blanca de correos |
| El juego | Queda **solo con Jugador y Duelo**: el Modo Admin desaparece de la vista de los niños |

Sobre la última: fue una corrección de Roberto al diseño inicial y mejora el resultado. Los
niños dejan de ver un botón que no es para ellos, hay un único lugar administrativo, y el
tablero de avance pasa a estar detrás de una cuenta real en vez de una clave escrita en el
repositorio.

## Modelo de datos

```sql
-- NUEVO: profesores (uno por cuenta de Supabase Auth)
profesores(
  id       uuid primary key,          -- auth.uid() de su cuenta
  correo   text unique not null,
  nombre   text,
  es_admin boolean not null default false,
  creado   timestamptz not null default now()
)

-- NUEVO: lista blanca de correos que pueden registrarse
profesores_autorizados(
  correo       text primary key,
  invitado_por uuid references profesores(id),
  como_admin   boolean not null default false,   -- la primera alta hereda esta marca
  usado        boolean not null default false,
  creado       timestamptz not null default now()
)

-- cursos gana su dueño
alter table cursos add column profesor_id uuid references profesores(id) on delete set null;
```

**Ser administrador no es un sistema aparte**: es un profesor con `es_admin = true`, que ve
todos los cursos y además puede autorizar correos nuevos. Un solo mecanismo, menos código.

**Los permisos viven en `profesores`, no en la cuenta.** Cualquiera puede crear un usuario
en Supabase Auth (la API es pública), pero sin fila en `profesores` no puede hacer nada:
todas las funciones exigen esa fila. La fila solo se crea si el correo está en la lista
blanca.

## Registro y altas

1. Roberto agrega el correo del profesor a `profesores_autorizados` desde su panel.
2. El profesor entra a la página del profesor, elige "Crear mi cuenta", escribe ese correo
   y una contraseña.
3. Tras el registro, el cliente llama a `kimun_prof_alta(nombre)`, que verifica que el
   correo del usuario autenticado esté autorizado y sin usar, crea su fila en `profesores`
   y marca el correo como usado. El correo no se pasa por parámetro: la función lo toma de
   la sesión, para que nadie pueda registrarse con el correo autorizado de otra persona.
   `es_admin` se copia de `como_admin`, así la cuenta de Roberto queda administradora sin
   ningún paso manual en SQL.
4. Si el correo no estaba autorizado, la función falla y la cuenta queda sin permisos.

## Permisos y funciones

Las funciones nuevas **no reciben ninguna clave**: identifican al profesor por su sesión
(`auth.uid()`).

| Función | Para qué |
| --- | --- |
| `kimun_prof_yo()` | Mi fila de profesor, o null si no tengo permisos |
| `kimun_prof_alta(nombre)` | Completa el registro validando la lista blanca |
| `kimun_prof_listar()` | Mis cursos con sus alumnos, códigos y XP (todos si soy administrador) |
| `kimun_prof_curso_crear(nombre)` | Crea un curso a mi nombre |
| `kimun_prof_curso_quitar(codigo)` | Elimina un curso mío y sus alumnos |
| `kimun_prof_alumno_agregar(curso, nombre, avatar)` | Inscribe un alumno en un curso mío |
| `kimun_prof_alumno_quitar(codigo_acceso)` | Elimina un alumno de un curso mío |
| `kimun_prof_xp_fijar(codigo_acceso, xp)` | Corrige el XP de un alumno mío |
| `kimun_prof_autorizar(correo)` | **Solo administrador:** autoriza un correo |
| `kimun_prof_profesores()` | **Solo administrador:** lista de profesores |
| `kimun_prof_limpiar_pruebas(ejecutar)` | **Solo administrador:** reemplaza a `kimun_admin_limpiar_pruebas` |

Un helper `kimun_prof_es_mio(curso_id)` centraliza la comprobación: el curso me pertenece o
soy administrador. **El aislamiento es real**: si un profesor llama directamente a una
función con el código de un curso ajeno, el servidor la rechaza.

## La página del profesor

Archivo nuevo `profesor.html`, con tres estados: **ingresar**, **crear mi cuenta** y el
**panel**.

El detalle técnico que lo hace posible: crea su propio cliente de Supabase con un
`storageKey` distinto al del juego. Sin eso, un profesor que inicia sesión en el mismo
teléfono donde juega su hijo **le borraría la identidad al niño**, porque Supabase mantiene
una sola sesión por navegador y por almacenamiento.

El panel muestra mis cursos con sus alumnos, códigos y XP, y las acciones de siempre. Para
el administrador, además: autorizar un correo, ver la lista de profesores y entrar al
tablero de avance.

## Lo que se desmonta

- **Las funciones `kimun_admin_*` con clave global se eliminan**, junto con
  `kimun_admin_ok` y la fila `admin_clave` de `config`. No pueden convivir con el modelo
  nuevo: esa clave está en el repositorio y daría acceso total a los cursos de todos los
  profesores.
- **El panel de cursos dentro del juego se retira**, junto con el botón "Modo Admin". La
  pantalla de inicio queda con Jugador, Duelo, "Tengo un código" y Créditos.
- El tablero de avance sigue existiendo; se accede desde la página del profesor.

Es trabajo reciente que se reemplaza. Se asume a conciencia: mantener las dos vías dejaría
una puerta trasera a los datos de alumnos de otros docentes.

## Migración

El orden importa, porque una secuencia equivocada deja el sistema sin nadie que pueda
administrarlo:

1. Crear las tablas nuevas y `cursos.profesor_id`.
2. Roberto crea su usuario desde el panel de Supabase (Authentication → Add user), que nace
   con el correo ya confirmado.
3. Marcarlo como administrador con una consulta única sobre `profesores`. **No se siembra su
   correo en `profesores_autorizados` con `como_admin = true`**: el repositorio es público,
   así que esa fila sería una cuenta de administrador esperando a que alguien la reclame
   registrándose con ese correo.
4. Asignar todos los cursos existentes a esa cuenta.
5. Recién entonces eliminar las funciones con clave y el panel del juego.

Los cursos y alumnos actuales —"8vo csfs" con sus cuatro alumnos— se conservan.

## Correo

Roberto configura un proveedor SMTP (Resend o Brevo, plan gratuito) en Supabase. Habilita
la recuperación de contraseña y, más adelante, las invitaciones. Es configuración, no
código.

**Mientras no esté configurado**, un profesor que olvide su contraseña depende de que
Roberto se la restablezca desde el panel de Supabase. El resto del sistema funciona igual.

## Seguridad

- `profesores` y `profesores_autorizados` con RLS activo y **sin políticas de lectura**:
  como el resto del esquema, solo se accede por funciones `SECURITY DEFINER`.
- Ninguna función administrativa recibe contraseñas por parámetro: la identidad viene de la
  sesión.
- Las funciones que usan pgcrypto necesitan `set search_path = public, extensions`, porque
  en Supabase esa extensión no vive en `public`.

## Limitaciones conocidas

- **Un profesor puede borrar a un alumno por error y no hay deshacer.** Es el precio de la
  autonomía; el borrado pide confirmación y explica qué arrastra.
- **Sin verificación de que la persona trabaje en el colegio**: la garantía es que Roberto
  autoriza cada correo a mano.
- **La confirmación de correo debe quedar activada.** Es lo que impide que alguien se
  registre con un correo autorizado que no le pertenece. Desactivarla convierte la lista
  blanca en una lista de cuentas reclamables.
- **Sin SMTP no hay autorrecuperación de contraseña.**
- El XP sigue siendo reportado por el teléfono del alumno y puede falsearse; el profesor lo
  corrige con `kimun_prof_xp_fijar`.

## Fuera de alcance

Colegios como entidad propia, jerarquías (coordinador, director), traspasar un curso a otro
profesor, invitaciones automáticas por correo, y que el profesor vea el detalle de
respuestas por objetivo de aprendizaje (para eso está el tablero).

## Verificación

1. Dos profesores con un curso cada uno: cada uno ve **solo el suyo** en su panel.
2. Aislamiento real: el profesor A llama por RPC a las funciones con el código del curso de
   B y el servidor lo rechaza en todas.
3. Un correo no autorizado que se registra queda sin permisos: `kimun_prof_yo()` devuelve
   null y el panel no se abre.
4. Convivencia de sesiones: un niño canjea su código en el juego y sigue jugando en el mismo
   navegador donde un profesor tiene sesión abierta en la página del profesor.
5. Migración: los cursos y alumnos existentes siguen visibles para el administrador.
6. El juego ya no muestra el botón Modo Admin y el resto funciona igual.
