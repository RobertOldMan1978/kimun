# Diseño · Mapa de dominio por objetivo de aprendizaje

Fecha: 2026-08-18
Estado: aprobado por Roberto (pendiente de plan de implementación)

## Problema

El profesor tiene un panel donde administra cursos y ve el XP de sus alumnos, pero el XP
solo mide cuánto juega un niño, no **qué entiende**. Para decidir qué reforzar en clase
necesita lo segundo, y hoy el servidor no lo sabe: el progreso de campañas y los resultados
de cada quiz viven en `localStorage`, en el teléfono del alumno. Lo único que viaja es el XP
total.

La materia prima existe: **cada pregunta del banco trae su objetivo de aprendizaje** (campo
`oa`, por ejemplo `HI08 OA 01`) y la función `responder()` conoce la pregunta y si el alumno
acertó. Falta guardarlo y mostrarlo.

Esta es la primera pieza de la plataforma pensada para el adulto y no para el niño: es lo
que permite a un profesor justificar el uso de VULPO ante su colegio.

## Decisiones tomadas

| Decisión | Elección |
| --- | --- |
| Qué ve el profesor | **El curso y también cada alumno** |
| Qué se guarda | **Contadores por alumno y objetivo** (respondidas y correctas) |
| Qué actividades cuentan | **Solo campaña y jefes finales** |

Sobre la tercera: el duelo es competitivo y contra el reloj, donde se falla por apuro más
que por desconocimiento, y el Reto de Cálculo genera sus operaciones al vuelo, sin objetivo
asociado. Mezclarlos daría un dato sucio para una decisión pedagógica.

**Dos exclusiones adicionales**, necesarias aunque no se preguntaron:

- **El modo QA (`?qa=1`) no registra nada.** Marca las respuestas correctas en pantalla, así
  que contarlo ensuciaría el mapa con las pruebas del desarrollador.
- **El Modo Difícil sí cuenta**: usa las mismas preguntas del banco.

## Modelo de datos

```sql
-- NUEVO: una fila por alumno y objetivo de aprendizaje
dominio(
  perfil_id   uuid references perfiles(id) on delete cascade,
  oa          text not null,              -- "HI08 OA 01"
  respondidas int  not null default 0,
  correctas   int  not null default 0,
  actualizado timestamptz not null default now(),
  primary key (perfil_id, oa)
)
```

Se guarda el mínimo que responde la pregunta del profesor. **No** queda registro de qué
pregunta falló ni de cuándo respondió cada una, así que no se puede reconstruir la sesión de
un niño. Los datos se borran junto con el alumno, por el `on delete cascade`.

Volumen: un curso de 35 alumnos con los ~60 objetivos de una asignatura son unas 2.000 filas
en todo el año.

## Cómo se registra

Al terminar una etapa de campaña o un jefe, el juego envía **un resumen agregado de esa
partida**: por cada objetivo tocado, cuántas preguntas respondió y cuántas acertó. Una
llamada por etapa terminada, no una por pregunta.

```
kimun_dominio(p_datos jsonb)   -- [{"oa":"HI08 OA 04","n":6,"ok":4}, ...]
```

La función **suma** sobre los contadores existentes (`insert ... on conflict do update set
respondidas = dominio.respondidas + excluded.respondidas`, e igual con las correctas).

Registra contra el perfil del dispositivo, tenga curso o no. Un niño que juega sin haber
canjeado su código genera igualmente sus contadores; simplemente no los ve ningún profesor,
porque las funciones de lectura parten del curso. Si más tarde canjea un código, esos datos
quedan asociados al perfil del alumno y pasan a contar. Es el comportamiento deseable: nada
se pierde y nadie ve lo que no le corresponde.

Si el envío falla —sin señal, por ejemplo— el resumen queda pendiente en el teléfono y se
reintenta en la siguiente oportunidad. **El niño nunca ve nada de esto** y el juego no se
interrumpe: es best-effort, como la sincronización del XP.

## Lectura desde el panel

Dos funciones nuevas, sujetas al aislamiento entre profesores que ya existe:

| Función | Devuelve |
| --- | --- |
| `kimun_prof_dominio(p_curso_codigo)` | Por objetivo: respondidas y correctas sumadas de todo el curso |
| `kimun_prof_dominio_alumno(p_codigo_acceso)` | Lo mismo, para un alumno |
| `kimun_prof_dominio_reiniciar(p_curso_codigo)` | Pone en cero los contadores del curso; devuelve cuántas filas borró |

Ambas verifican la propiedad del curso con `kimun_prof_es_mio` antes de devolver nada.

## Lo que ve el profesor

En cada curso del panel, un botón **"Ver avance"** abre una tabla ordenada **de peor a mejor
porcentaje**, para que lo que hay que reforzar aparezca primero:

| Objetivo | Curso | Base |
| --- | --- | --- |
| Analizar el impacto de la conquista | 45% | 38 preguntas |
| Ubicar procesos en el tiempo | 78% | 52 preguntas |
| Comprender la Reforma y sus efectos | 87% | 41 preguntas |

Tres reglas de presentación, cada una por un motivo concreto:

- **Se muestra el texto del objetivo, no su código.** `HI08 OA 04` no le dice nada a nadie;
  el texto ya existe en los archivos `contenido/<asignatura>/oa.json`, que el panel carga.
  Sin esto la herramienta es ilegible para un profesor.
- **Se muestra cuántas preguntas respaldan cada porcentaje.** Un 45% de 4 preguntas no
  significa lo mismo que uno de 40; los objetivos con menos de diez respuestas se ven
  atenuados.
- **Un objetivo sin datos no aparece.** Mostrarlo como 0% se leería como "no lo entienden"
  cuando en realidad es "todavía no lo juegan".

Al pinchar un alumno se abre la misma tabla con sus propios números.

## Reiniciar mediciones

Un botón por curso, con confirmación, que pone los contadores en cero.

Existe por una limitación real del modelo: **los contadores acumulan todo el año**, así que
un alumno que falló mucho en marzo y hoy domina el tema arrastra un porcentaje bajo. Guardar
historial con fechas lo resolvería, pero fue descartado por volumen y por privacidad. El
reinicio al empezar una unidad o un semestre es el punto medio: el profesor decide desde
cuándo medir.

## Privacidad

- Estos datos describen el desempeño individual de menores. Solo los ve el profesor dueño
  del curso, apoyándose en el aislamiento ya verificado con dos cuentas reales.
- Se guarda el mínimo necesario: contadores, no respuestas.
- El alumno no ve nada de esto; el juego no cambia para él.
- La tabla `dominio` va con RLS activo y sin políticas de lectura, como el resto del
  esquema: solo se accede por funciones `SECURITY DEFINER`.

## Límites conocidos

- **No sirve para calificar.** El dato lo reporta el teléfono del alumno, igual que el XP, y
  es falsificable por alguien que sepa. Es una brújula para decidir qué repasar, no una nota.
  Conviene que el panel lo diga con todas sus letras.
- **Empieza de cero:** lo ya jugado no se puede recuperar, porque nunca se guardó.
- **Un alumno que juega poco** deja objetivos con base mínima; de ahí la columna de respaldo.
- **El acumulado castiga al que mejoró**, que es lo que mitiga el botón de reinicio.

## Fuera de alcance

- Evolución en el tiempo y comparación entre periodos (exigiría guardar historial).
- Detectar preguntas mal formuladas a partir de los fallos (exigiría guardar cada respuesta).
- Incluir el duelo y el Reto de Cálculo.
- Exportar el mapa a PDF o planilla.
- Que el alumno vea su propio mapa.

## Verificación

1. Jugar una etapa completa y comprobar que los contadores del objetivo suben **exactamente**
   con los números de esa partida (6 respondidas, 4 correctas si así fue).
2. Repetir con `?qa=1` y confirmar que **no** se registra nada.
3. Comprobar que un objetivo que nadie jugó **no aparece** en la tabla.
4. Aislamiento: un profesor de otro curso llama directamente a `kimun_prof_dominio` con el
   código del curso ajeno y recibe `no_autorizado`.
5. Sin conexión: el resumen queda pendiente, el juego sigue igual, y se envía al recuperar la
   señal.
6. El botón de reinicio deja los contadores del curso en cero y no toca los de otros cursos.
