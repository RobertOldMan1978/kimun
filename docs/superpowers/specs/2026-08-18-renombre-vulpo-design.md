# Diseño · Renombre a Vulpo

Fecha: 2026-08-18
Estado: aprobado por Roberto · **la ejecución está bloqueada hasta confirmar la marca en INAPI**

## Problema

El nombre **KIMÜN** ya existe como marca de terceros, incluida al menos una del rubro de
enseñanza y colegios. Eso impide lanzar la plataforma a producción con ese nombre.

El conflicto es doble, porque hoy "Kimün" es dos cosas a la vez: la plataforma y el zorro
mascota que aparece en todo el juego.

> **Aviso:** este documento no es asesoría legal. La verificación de disponibilidad y el
> eventual registro corresponden a INAPI y, idealmente, a un abogado de marcas. Aquí solo se
> define el cambio técnico y editorial.

## Decisiones tomadas

| Decisión | Elección |
| --- | --- |
| Alcance del cambio | Cambian **ambos**: la plataforma y la mascota |
| Tipo de nombre | Palabra **de fantasía** (la más registrable y la que más protege) |
| Tono buscado | Juego y aventura, antes que "colegio" |
| Nombre de la plataforma | **Vulpo** |
| Nombre de la mascota | **Vulpi** |

Ambos derivan de *vulpes*, zorro en latín, así que el zorro sigue estando en el ADN del
nombre sin nombrarlo. La separación da un nombre sobrio para colegios y apoderados, y uno
cariñoso para el compañero de juego de los niños.

**Descartado en el camino:** *Zorbi*, porque ya existe como aplicación educativa activa, con
dominio propio y presencia en tiendas. Es el mismo tipo de choque que motivó este cambio.

**Sobre Vulpi:** existen empresas brasileñas con ese nombre (una de reclutamiento de
programadores y una agencia de diseño). No se consideran un impedimento porque las marcas se
protegen por país y por clase, y ninguna es chilena ni del rubro educativo. Dos
consecuencias prácticas: el dominio `.com` probablemente no está disponible, y una eventual
expansión a Brasil quedaría complicada.

## Condición previa, bloqueante

Antes de ejecutar el renombrado hay que confirmar:

1. **Vulpo** en [INAPI](https://www.inapi.cl/marcas), en las clases de software y educación.
2. El dominio `vulpo.cl` en [NIC Chile](https://www.nic.cl/).
3. Ausencia del nombre en Google Play y App Store.

Renombrar antes de esa verificación arriesga tener que hacer el trabajo dos veces.

## Alcance medido

| Elemento | Cantidad |
| --- | --- |
| Apariciones del nombre en `index.html` | 85 |
| Archivos de arte con el nombre en el nombre de archivo | 34 |
| Funciones de Supabase con prefijo `kimun_` | ~20 |
| Claves de almacenamiento del navegador | 6 |
| Documentos del proyecto que lo mencionan | ~20 |

**Hallazgo importante:** el nombre **nunca está dibujado dentro del arte**. El logo es texto
con tipografía web (`<h1>KIMÜN</h1>`) y el SVG no contiene texto. **No hay que regenerar
ninguna ilustración**: el trabajo es editorial, no gráfico.

## Qué cambia

Todo lo que ve un usuario o un lector del proyecto:

- El título de la pestaña y el logo de la portada.
- Cada texto donde se nombra al zorro o habla la mascota. Por ejemplo, "🦊 Kimün te
  cuenta…" pasa a "🦊 Vulpi te cuenta…".
- Los nombres de las skins de recompensa: "Kimün Historiador" pasa a "Vulpi Historiador", y
  lo mismo con Científico, Escritor, Calculista y Maestro.
- La sección de créditos.
- `README.md`, `CLAUDE.md` y los títulos del tablero de avance.

## Qué NO cambia, a propósito

| Qué | Por qué |
| --- | --- |
| Claves del navegador (`kimun_save`, `kimun_intro`, `kimun_music`, `kimun_sound`, `kimun_music_vol`, `kimun_rank`) | Cambiarlas **borra el progreso** de quien ya juega: campañas, skins, monedas y récords |
| Las funciones de Supabase (`kimun_perfil`, `kimun_ranking`, `kimun_prof_*`…) | Renombrarlas exige sincronizar backend y cliente al milímetro; un desajuste deja el juego inservible, y nadie las ve |
| Los 34 archivos de arte (`kimun-feliz.png`…) | Solo aparecen en el código fuente y en las peticiones de red. Mucho riesgo de romper referencias a cambio de ningún beneficio |

Ninguno de estos identificadores es visible para un usuario ni constituye uso de marca. Si
más adelante se quiere una limpieza total por prolijidad, se hace como trabajo aparte y sin
urgencia.

## La dirección pública

El juego vive hoy en `robertoldman1978.github.io/kimun/`. Al renombrar el repositorio a
`vulpo`, la URL cambia y GitHub deja una redirección automática desde la anterior, de modo
que los enlaces que ya circulan siguen funcionando.

Para producción con marca propia, lo natural es un dominio `vulpo.cl` apuntando a esa
página.

## Fases

1. **El juego** (`index.html`): es donde está todo lo visible.
2. **La documentación** (`README.md`, `CLAUDE.md`, `dev/tablero.html` y el script que lo
   genera).
3. **El repositorio y la URL**: al final, porque es lo único que puede romper enlaces que ya
   estén circulando.

## Riesgos y limitaciones

- **El progreso guardado depende de las claves internas.** Es la razón de fondo por la que
  no se tocan. Cualquiera que las cambie después debe migrar los datos, no solo renombrar.
- **Coexistencia de nombres en el código:** durante mucho tiempo convivirán la marca nueva
  (visible) y los identificadores antiguos (internos). Es intencional y queda documentado
  aquí para que nadie lo lea como un descuido.
- **La redirección de GitHub no es eterna:** si algún día se crea otro repositorio llamado
  `kimun`, la redirección se pierde. Un dominio propio elimina esa dependencia.

## Verificación

1. Buscar `kim[uü]n` en `index.html` sin distinguir mayúsculas: los únicos resultados deben
   ser los identificadores internos de la tabla de arriba, ninguno visible.
2. Recorrer el juego en el navegador: inicio, campaña, quiz, tienda, perfil, duelo, créditos
   e intro. En ninguna pantalla debe aparecer el nombre anterior.
3. El progreso de un jugador existente sigue intacto tras el cambio: mismas campañas, skins
   y monedas.
4. La documentación no menciona el nombre anterior salvo en la bitácora histórica, donde es
   correcto que quede registrado.
