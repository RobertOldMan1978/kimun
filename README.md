# KIMÜN 🎮📚

Plataforma de juegos educativos para escolares chilenos, alineada al currículum
del Ministerio de Educación de Chile. La idea: que estudiar sea entretenido,
desafiante y que genere comunidad entre compañeros.

> **Estado: v0.99** — completo y jugable de punta a punta (4 asignaturas con campaña
> y jefe final), en revisión antes de la v1.

## Piloto actual

**Campaña Historia — 8° básico** (los 22 OA del año, en orden).

Un juego tipo aventura con mapa de niveles, quiz con temporizador, combos, XP,
monedas, estrellas, logros y ranking de curso. **Kimün**, el zorro mascota,
acompaña y reacciona a cada respuesta. Incluye **Modo Difícil** desbloqueable.

La pantalla principal ofrece un **módulo por asignatura**. **Historia**, **Ciencias** y
**Lenguaje** se juegan como **campañas con hilo conductor**: capítulos en orden que cubren
todos los OA del año, con **Jefe Final multi-fase** (barra de vida, 3 corazones) y
**recompensas** (skin exclusiva, insignia coleccionable, corona y bono). **Matemáticas** es
un **Reto de Cálculo** (cálculo mental rápido, por niveles) con su propio Jefe Final. Cada
asignatura tiene un banco de preguntas de año completo (todos sus OA del currículum).
También hay **Duelo 1v1** en el mismo teléfono y en línea (Supabase), una **tienda de
skins** (incluidas skins deportivas ilustradas) y una **intro de bienvenida** en video que
se ve una vez. Todo en un solo archivo `index.html`, pensado para el celular.

## Cómo probarlo

Abre `index.html` en cualquier navegador moderno, o entra a la versión publicada
en GitHub Pages (ver la URL en la configuración del repositorio, sección *Pages*).

## Estado

Versión **v0**: prototipo funcional. El objetivo inmediato es verlo funcionar y
que sea visualmente atractivo. Login, multiusuario y modelo de negocio quedan
para más adelante.

Consulta [CLAUDE.md](CLAUDE.md) para el detalle de decisiones de diseño y el
roadmap.

## Tecnología

HTML + CSS + JavaScript puro, sin framework. Dependencias externas por CDN:
Google Fonts y `@supabase/supabase-js` (para el duelo 1v1 en línea).
Contenido de cada expedición en `contenido/<asignatura>/` (JSON). Mobile-first.

---

Proyecto personal de Roberto.
