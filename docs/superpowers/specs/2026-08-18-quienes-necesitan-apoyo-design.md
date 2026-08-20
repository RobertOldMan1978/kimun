# Diseño · Ver quiénes necesitan apoyo

Fecha: 2026-08-18
Estado: aprobado por Roberto (pendiente de plan de implementación)

## Problema

El mapa de dominio le dice al profesor **qué contenido está flojo**, pero no **quiénes**. Un
objetivo en 45% puede significar dos cosas opuestas: que el curso completo no lo entendió
—y hay que reenseñar, perdiendo una clase— o que seis niños arrastran el promedio —y basta
un grupo de refuerzo mientras el resto avanza.

Hoy la única forma de distinguirlas es abrir la ficha de los 35 alumnos uno por uno y anotar
en papel. Es decir: no se hace nunca.

Es el vacío que el informe pedagógico puso primero, y los datos **ya existen**: `dominio`
tiene una fila por alumno y objetivo. Falta una función de lectura y una vista.

## Decisiones tomadas

| Decisión | Elección |
| --- | --- |
| Qué se muestra de cada alumno | **Solo su grupo, sin porcentaje individual** |
| Umbrales de los grupos | **Los mismos del mapa**: 45% y 70% |
| Alumnos con muy pocas preguntas | **Grupo aparte**, junto a los que no jugaron |

Sobre la primera: mostrar el porcentaje de cada niño daría más información para priorizar,
pero convierte la pantalla en una lista de menores ordenable por rendimiento. El informe
pedagógico advirtió que ese es el artefacto que termina proyectado en un consejo de
profesores o pegado en un libro de notas. El profesor que necesita el detalle de un alumno
tiene su ficha individual, que ya existe.

Sobre la segunda: los cortes coinciden con los colores del mapa, que ya están calibrados al
piso del azar (con cuatro opciones, responder sin saber da 25%). Tener dos verdades distintas
en pantallas contiguas confundiría.

## Modelo de datos

**Ninguno.** No se agrega ni una columna: la información ya está en `dominio`.

## Función nueva

```sql
kimun_prof_dominio_oa(p_curso_codigo text, p_oa text)
  returns table(alumno text, avatar text, resp_1 int, ok_1 int)
```

Tres características deliberadas:

1. **Incluye a todos los alumnos inscritos del curso**, con un `left join` contra `dominio`,
   no solo a los que tienen datos. Quien no jugó ese objetivo aparece con ceros, y eso es
   información: "12 no lo han visto todavía". "Inscrito" significa **con código de acceso**:
   los perfiles sueltos que crea cada teléfono al abrir el juego no son alumnos del curso y
   quedan fuera, igual que en el resto del panel.
2. **Devuelve ordenado por nombre, no por porcentaje.** El orden alfabético es lo que impide
   que la pantalla se lea como un ranking.
3. Verifica la propiedad del curso con `kimun_prof_es_mio` antes de devolver nada, igual que
   el resto de las funciones de profesor, y colapsa "el curso no existe" en `no_autorizado`.

## Los cuatro grupos

La clasificación se hace en el cliente, sobre el porcentaje del primer intento
(`ok_1 / resp_1`):

| Grupo | Criterio | Estado |
| --- | --- | --- |
| Necesitan apoyo | 4 o más preguntas, bajo 45% | Abierto |
| En camino | 4 o más preguntas, entre 45% y 70% | Abierto |
| Lo lograron | 4 o más preguntas, 70% o más | Plegado |
| Todavía sin evidencia | Menos de 4 preguntas de primer intento, incluidos los que no jugaron | Plegado |

El cuarto grupo existe por un caso concreto: un alumno puede tocar un objetivo por primera
vez **durante un jefe final**, donde caen una o dos preguntas de cada objetivo. Con una sola
pregunta queda en 0% o 100%, y mandarlo al grupo de refuerzo por eso sería una decisión
injusta tomada sobre nada.

## Presentación

Al tocar una fila del mapa se despliega debajo, sin cambiar de pantalla:

```
Analizar la centralidad del ser humano…
████████░░  58%  ·  24 alumnos  ·  31 reintentos
   ▾ Necesitan apoyo (6)
     🦊 Matías   🐯 Emilia   🐼 Nicolás   🦄 Sofía   🐸 Diego   🐨 Javiera

   ▾ En camino (9)
     ...

   ▸ Lo lograron (12)
   ▸ Todavía sin evidencia (8)
```

Los nombres van como fichas en línea, no en lista vertical: 35 alumnos en columna serían
cuatro pantallas en un teléfono de 480 px.

La consulta se hace **al abrir el objetivo**, no al cargar la tabla: con 50 objetivos, pedir
todos los detalles por adelantado serían 50 llamadas para información que el profesor casi
nunca va a mirar entera.

## Lo que no incluye, a propósito

- **No se muestra el porcentaje de cada alumno.**
- **No se puede ordenar por rendimiento.**
- **No hay exportación de la lista.**

Las tres ausencias apuntan a lo mismo: una lista de nombres de menores ordenada por
rendimiento, con números al lado y un botón de exportar, es exactamente el archivo que
termina en un libro de notas. La herramienta debe servir para armar un grupo de refuerzo, no
para calificar.

## Privacidad

El profesor ya ve los nombres de sus alumnos en el panel; lo nuevo es agruparlos por
desempeño, que es información sensible sobre menores y es justamente el propósito de la
herramienta. Se acota con lo de siempre: solo el profesor dueño del curso, mediante el
aislamiento ya verificado con dos cuentas reales; y el alumno nunca ve nada de esto.

## Límites conocidos

- **Sigue sin servir para calificar**, por lo mismo de siempre: el dato lo reporta el
  teléfono del alumno.
- **Un grupo grande en "sin evidencia" no significa que el curso vaya mal**, sino que ese
  objetivo se ha jugado poco. Conviene que el rótulo lo diga con esas palabras.
- **La clasificación usa el primer intento**, así que un alumno que reforzó y ya domina el
  tema sigue apareciendo donde lo dejó su primera vez. Es coherente con el resto del mapa y
  con el botón de reiniciar mediciones, pero el profesor debe saberlo: el grupo de refuerzo
  se arma mirando el primer intento, no el estado actual.

## Fuera de alcance

- Marcar a un alumno como "ya reforzado" o llevar registro de la intervención.
- Enviar la lista por correo o exportarla.
- Ver la evolución de un alumno en el tiempo.
- Agrupar por eje o unidad dentro del detalle.

## Verificación

1. Un alumno con 2 aciertos de 6 en el primer intento cae en **Necesitan apoyo**.
2. Un alumno con 1 sola pregunta de primer intento cae en **Todavía sin evidencia**, no en el
   grupo bajo, aunque haya fallado.
3. Un alumno inscrito que nunca jugó ese objetivo aparece en **Todavía sin evidencia**.
4. **La suma de los cuatro grupos es igual al total de alumnos del curso.** Si no cuadra,
   alguien se está perdiendo por el camino.
5. Un profesor de otro curso llama directamente a `kimun_prof_dominio_oa` con el código
   ajeno y recibe `no_autorizado`.
6. En un teléfono de 375 px, un grupo de 15 alumnos se lee sin desbordar horizontalmente.
