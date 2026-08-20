---
name: titanic
description: Genera el prompt de traspaso para empezar una sesión nueva de VULPO sin perder el hilo. Activate cuando el usuario diga "Titanic", "/titanic", "hagamos el traspaso", "prepara el prompt para la sesión nueva", "vamos a hacer clear" o similar. Revisa el estado real del repositorio y la bitácora, y entrega un prompt listo para copiar, hacer /clear y pegar.
---

# Titanic — Traspaso a una sesión nueva

Se activa cuando la conversación creció demasiado y conviene empezar de cero sin perder el
hilo. El nombre viene de la idea de abandonar el barco a tiempo, llevándose lo que importa.

## Qué hace y qué no

**Hace:** revisar el estado real del proyecto y entregar un prompt de traspaso, en un solo
bloque, listo para copiar.

**No hace, porque no puede:** ejecutar `/clear` ni pegar el prompt en la sesión nueva. Las
dos cosas son del usuario. Dilo con claridad al entregar el prompt, sin prometer que la
transición es automática.

## Cómo se arma el prompt

El prompt NO debe repetir lo que la sesión nueva ya va a cargar sola. `CLAUDE.md` se lee
automáticamente al iniciar, y ahí están la descripción del proyecto, el estado, las reglas
de trabajo, las órdenes 66 y 99, los trámites pendientes y la bitácora completa. Repetir eso
gasta contexto y envejece mal.

**El prompt es el delta:** lo que vive solo en la conversación que se está cerrando.

### Pasos

1. **Mira el estado real, no la memoria de la conversación:**

```bash
git -C C:/Proyectos/kimun log --oneline -8
git -C C:/Proyectos/kimun status --short
```

2. **Revisa los pendientes** de la sección "Pendientes" de la última sesión de la bitácora en
   `CLAUDE.md`, y los documentos recientes de `docs/superpowers/specs/` y
   `docs/superpowers/plans/`.

3. **Detecta lo que quedó a medias:** cambios sin commitear, un plan escrito y sin ejecutar,
   una verificación que quedó pendiente del usuario, SQL escrito y sin aplicar en Supabase.

4. **Escribe el prompt** con esta estructura, en español latino neutro y en un solo bloque de
   código para que se copie de una vez:

```
Retomo VULPO. Ya leíste CLAUDE.md, así que no repitas lo que está ahí.

DÓNDE QUEDAMOS
<dos o tres frases sobre lo último que se hizo y por qué>

ESTADO DEL REPOSITORIO
<limpio, o qué archivos están sin commitear y por qué>
Último commit: <hash y título>

LO QUE ESPERA POR MI LADO
<acciones del usuario: aplicar SQL, probar algo en el panel, canjear códigos.
 Si no hay ninguna, decir "nada">

LO SIGUIENTE
<la tarea inmediata, con el archivo o documento donde está definida>

CUIDADO CON
<una o dos trampas concretas descubiertas en la sesión que se cierra y que no
 estén ya en CLAUDE.md; si no hay ninguna, omitir esta sección>
```

5. **Entrega el prompt y las instrucciones**, en este orden: copiar el bloque, ejecutar
   `/clear`, pegar.

## Reglas

- **Sé breve.** Un prompt de traspaso largo es un prompt que nadie lee y que llena de ruido
  la sesión nueva. Apunta a algo que quepa en una pantalla.
- **No inventes estado.** Si no estás seguro de si algo se aplicó en Supabase o se probó,
  escríbelo como pendiente de confirmar, no como hecho.
- **Nada de commits.** Esta skill no commitea ni sube nada; la regla de la orden 66 sigue
  vigente. Si hay cambios sin commitear, dilo en el prompt para que la sesión nueva lo sepa.
- **Si hay trabajo sin commitear que se perdería de vista**, sugiere al usuario dar la orden
  66 antes del clear. Sugerir, no hacer.
