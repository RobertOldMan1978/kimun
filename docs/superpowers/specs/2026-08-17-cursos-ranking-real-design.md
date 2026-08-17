# Diseño · Cursos y ranking real

Fecha: 2026-08-17
Estado: aprobado por Roberto (pendiente de plan de implementación)

## Problema

El "Ranking del curso" es falso. `renderRanking()` (index.html) arma la tabla con
cuatro nombres fijos —Vale, Nico, Fran y Diego, los mismos bots del duelo— con
puntajes inventados, y agrega al jugador con su XP local. Nadie compite contra nadie.

Dos restricciones del estado actual condicionan la solución:

1. **El XP vive solo en el teléfono** (localStorage). Supabase guarda perfiles y
   duelos, pero no tiene ninguna columna de XP.
2. **Un jugador solo existe en Supabase si entra al Duelo en línea.** `conectarKimun()`
   se llama únicamente al abrir esa pantalla. Quien juega campañas nunca crea perfil
   en el servidor.

Además, la identidad es anónima **por dispositivo**: el perfil *es* el usuario anónimo
(`perfiles.id = auth.uid()`). Si el niño limpia los datos del navegador o cambia de
teléfono, pierde su progreso y reaparece como jugador nuevo.

## Decisiones tomadas

| Decisión | Elección |
| --- | --- |
| Qué mide el ranking | **XP total** (campañas, Reto de Cálculo, duelos, jefes) |
| Contra quiénes se compite | **Por curso**, no global |
| Quién crea los cursos | **Solo el adulto**, desde el Modo Admin |
| Cómo entra un alumno | Con un **código de acceso** que le entrega el adulto |
| Dónde vive el panel del adulto | **Pantalla nueva dentro de `index.html`** |

Sobre la última: se descartó `dev/tablero.html` porque es un archivo estático que se
regenera con `generar-tablero.py` (lo escrito a mano se perdería), no está pensado para
móvil y obligaría a duplicar la configuración de Supabase. También se descartó administrar
por SQL: no se puede hacer desde el celular y convierte cada inscripción en una tarea de
programador.

## Modelo de datos

```sql
-- NUEVO
cursos(
  id     uuid primary key default gen_random_uuid(),
  nombre text not null,            -- "8° A"
  codigo text unique not null,     -- CUR-AB12
  creado timestamptz default now()
)

-- perfiles: tres columnas nuevas
alter table perfiles add column curso_id      uuid references cursos(id) on delete set null;
alter table perfiles add column xp            int not null default 0;
alter table perfiles add column codigo_acceso text unique;   -- ALU-XXXX

-- NUEVO: separa "sesión del dispositivo" de "perfil del alumno"
vinculos(
  auth_uid  uuid primary key,      -- auth.uid() del dispositivo
  perfil_id uuid not null references perfiles(id) on delete cascade,
  creado    timestamptz default now()
)
```

`vinculos` es la pieza central. Hoy el perfil y el usuario anónimo son lo mismo, y por eso
un alumno no puede cambiar de teléfono. Con la tabla de vínculo, cualquier dispositivo se
conecta a cualquier perfil: un alumno juega en el celular y en el tablet sin duplicarse, y
recupera su perfil si limpia el navegador.

### Impacto en las funciones existentes

Seis funciones asumen hoy que `auth.uid()` es la identidad del jugador: `kimun_perfil`,
`kimun_jugadores`, `kimun_crear_duelo`, `kimun_pendientes`, `kimun_responder` y
`kimun_historial`. Todas pasan a resolver la identidad con un helper nuevo:

```sql
create function kimun_yo() returns uuid   -- perfil_id del dispositivo actual
  select perfil_id from vinculos where auth_uid = auth.uid();
```

`kimun_perfil(nombre, avatar)` cambia de comportamiento: si el dispositivo ya tiene
vínculo, actualiza ese perfil; si no, crea el perfil (con `id = auth.uid()`, como hoy) y
además su vínculo.

**Migración de lo existente:** al aplicar el esquema se crea un vínculo
`(auth_uid = id, perfil_id = id)` para cada perfil real que ya exista, de modo que los
jugadores actuales sigan funcionando sin notar el cambio.

## Funciones nuevas

| Función | Para qué |
| --- | --- |
| `kimun_yo()` | Devuelve el `perfil_id` del dispositivo actual |
| `kimun_xp(p_xp)` | `xp = mayor(xp_actual, p_xp)` sobre mi perfil |
| `kimun_ranking()` | Alumnos de mi curso ordenados por XP |
| `kimun_canjear(p_codigo)` | Vincula este dispositivo al perfil de ese código |
| `kimun_admin_curso_crear(p_clave, p_nombre)` | Crea un curso y devuelve su código |
| `kimun_admin_alumno_agregar(p_clave, p_curso, p_nombre, p_avatar)` | Crea el alumno y su código de acceso |
| `kimun_admin_listar(p_clave)` | Cursos con sus alumnos, códigos y XP |
| `kimun_admin_alumno_quitar(p_clave, p_codigo_acceso)` | Elimina un alumno |

Las funciones de administración exigen la clave como parámetro y la comparan contra un
valor guardado en la base de datos.

**El alumno se crea como un perfil normal**, con `id = gen_random_uuid()` (igual que los
bots) y su propio código de amigo `KIM-XXXX` además del código de acceso `ALU-XXXX`. Así
puede participar del duelo desde el primer día, sin casos especiales en el resto del motor.

## Flujos

### Adulto

Inicio → **Modo Admin** → clave → dos opciones: *Tablero de avance* (lo actual, sin
cambios) y **Cursos** (nuevo). En Cursos: crear un curso ("8° A" → `CUR-AB12`), agregar
alumnos por nombre, y ver la lista con el código de acceso de cada uno y su XP actual.

### Alumno

En el inicio aparece **"Tengo un código"**. El niño escribe `ALU-XXXX` una vez y su
teléfono queda vinculado a ese perfil. Desde entonces el ranking muestra su curso y él
aparece con su nombre real.

Si ya venía jugando en ese teléfono sin código, **conserva su avance**: al vincularse se
toma el XP más alto entre el local y el del servidor.

Dos casos que el canje debe resolver de forma explícita:

- **El juego adopta el nombre y el avatar del perfil del alumno**, es decir los que escribió
  el adulto. Es lo que hace que el ranking muestre nombres reconocibles por el curso y no
  apodos que cada niño cambie a voluntad.
- **Si el teléfono ya estaba vinculado a otro perfil, el vínculo se reemplaza.** Es el caso
  de dos hermanos que comparten un tablet: cada uno canjea su código cuando le toca jugar.
  El progreso local (campañas, skins) es del teléfono y no se separa por alumno; esa
  limitación se asume.

## Sincronización del XP

`kimun_xp(p_xp)` aplica `xp = mayor(xp_actual, p_xp)`. Al ser **monótona**, el XP nunca
retrocede: si el niño juega en dos dispositivos, el servidor conserva el más alto en vez
de pisar el avance.

Se llama en los momentos donde el XP ya cambia —fin de etapa, jefe, ronda del Reto de
Cálculo y duelo—, no en cada respuesta, y como máximo una vez cada 15 segundos: si dos
eventos caen juntos, el segundo espera y se envía el valor más reciente. Es
**best-effort**: si falla, el juego sigue igual y se reintenta en el siguiente evento.

## Pantalla del ranking

`renderRanking()` pasa a tener tres estados:

| Situación | Qué se muestra |
| --- | --- |
| Tiene curso | Tabla real: posición, avatar, nombre, XP, con el jugador resaltado |
| Sin curso | "Pide tu código para entrar al ranking de tu curso" + botón **Tengo un código** |
| Sin conexión | El último ranking cargado (en caché), con un aviso discreto |

Los cuatro nombres inventados desaparecen. Un jugador sin curso verá el ranking vacío con
la invitación a pedir su código: es menos vistoso, pero honesto. Los bots quedan fuera
porque no pertenecen a ningún curso.

## Errores

Todo el ranking es **no bloqueante**: si Supabase falla, el juego funciona idéntico, igual
que hoy con el duelo. Un código equivocado responde "Ese código no existe, revísalo con tu
profesor". Que un mismo código se use en dos dispositivos **está permitido a propósito**:
es lo que permite jugar en el celular y en el tablet.

## Limitaciones conocidas

- **La clave de administración es un bloqueo suave.** Quedó mejor de lo previsto en este
  diseño: no vive en el JavaScript sino en la base de datos, guardada con hash, así que no
  se puede leer del código fuente como ocurre hoy en el tablero. Aun así no es seguridad
  fuerte: viaja desde el navegador y no hay límite de intentos. Suficiente para un uso
  familiar o de un curso.
- **El XP lo reporta el cliente**, así que puede falsearse editando el almacenamiento del
  navegador. Verificarlo exigiría subir cada respuesta al servidor, mucho más trabajo. Como
  el XP es monótono, un valor inflado sería irreversible; por eso el adulto cuenta con
  `kimun_admin_xp_fijar` para reajustar el XP de un alumno.
- Los nombres de los alumnos quedan visibles para el resto de su curso. Son los nombres que
  el adulto escribe, así que puede usar solo el nombre de pila o un apodo.

## Fuera de alcance

- Subir el progreso de campañas (estrellas, capítulos, skins): sigue siendo local, solo
  viaja el XP.
- Ranking global o comparación entre cursos.
- Editar alumnos en el panel: para corregir un nombre, se elimina y se agrega de nuevo.
- Notificaciones.
- Cambios en el duelo más allá de adaptar la identidad.

## Verificación

1. Crear un curso con dos alumnos y canjear sus códigos en dos perfiles distintos del
   navegador.
2. Jugar en ambos y comprobar que el ranking los ordena por XP y resalta al jugador.
3. Comprobar que el mismo código funciona en un segundo dispositivo sin duplicar el perfil.
4. Regresiones: el duelo en línea sigue operando con la identidad nueva; el juego sin
   conexión no se cae; un jugador sin curso ve el mensaje y no un error.
