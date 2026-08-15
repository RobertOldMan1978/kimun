# Música de fondo de KIMÜN

El juego reproduce música de fondo en loop según el contexto. Los archivos son
**opcionales**: si no existen, el juego funciona igual (solo no suena música).

## Archivos que el juego busca

| Archivo | Cuándo suena | Ánimo sugerido |
|---|---|---|
| `musica-menu.mp3` | Inicio, expediciones, mapa, quiz, tienda | Tranquila, motivadora, positiva |
| `musica-jefe.mp3` | Jefe Final (intro, duelo y victoria) | Épica, tensa, más rápida |

## Especificaciones

- **Formato:** MP3 (máxima compatibilidad en celulares, incluido iPhone).
- **Loop perfecto:** que empiece y termine de forma que el bucle no tenga corte.
- **Duración:** 30–90 s (se repite en loop; no hace falta que sea larga).
- **Peso objetivo:** < 1 MB por pista (comprimir a ~96 kbps; mono está bien).
- **Volumen:** grabada suave; el juego además la baja al ~40 %.

## Dónde conseguir música libre de regalías

- Pixabay Music (https://pixabay.com/music/) — libre, sin atribución.
- FreePD (https://freepd.com/) — dominio público.
- Incompetech / Kevin MacLeod — CC-BY (requiere créditos).
- OpenGameArt (https://opengameart.org/) — revisar licencia de cada track.

> Al usar CC-BY hay que dar crédito al autor (agregarlo aquí o en los créditos del juego).

## Cómo probar

Deja los archivos con esos nombres exactos en `assets/audio/` y recarga el juego.
El botón 🎵 (arriba a la derecha) activa o silencia la música; el 🔊 controla los
efectos, por separado.
