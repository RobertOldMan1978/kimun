# Camino de aprendizaje de Matemáticas — Plan 3 (Cap 3: Geometría)

> **Para el trabajador agéntico:** SUB-SKILL: superpowers:subagent-driven-development.
> Pasos con casillas `- [ ]`. **NO commitear** (solo con "orden 66"); cada tarea termina en
> verificación en el navegador. Idioma: **español latino neutro**; matemática correcta 8°.

**Objetivo:** agregar la **Unidad 3 (Geometría, OA11–14)** al camino de aprendizaje de
Matemáticas, reusando el motor de lecciones. Se suman 3 widgets (`triangulo`, `solido`,
`transformacion`) y se activa el capítulo `mate-geometria` (hoy "🔒 Pronto").

**Arquitectura:** sin cambios de motor. Widgets al catálogo `DIAGRAMAS` en `index.html`;
4 lecciones a `contenido/matematicas-8basico/lecciones.json`; se edita la entrada `'mate'`
de `CAMPAÑAS` para activar el capítulo 3 (se abre al completar Álgebra). El código de los
widgets ya se prototipó y validó visualmente.

**Verificación:** en el navegador (`preview_start {name:"kimun"}`, navegar EXPLÍCITAMENTE a
`http://localhost:8765/`). Banco: OA11–14 tienen 30 preguntas cada uno (verificado).

---

## Tarea 1: Widgets `triangulo` (Pitágoras) y `solido` (prisma/cilindro)

**Archivos:** Modificar `index.html` (bloque "CATÁLOGO DE DIAGRAMAS", junto a los otros `DIAGRAMAS.*`)

- [ ] **Paso 1: Implementar `triangulo`**

```js
// triangulo: triángulo rectángulo con los cuadrados de los catetos (Pitágoras).
// params: {a=3, b=4}  (c = √(a²+b²) se calcula)
DIAGRAMAS.triangulo=function(p,nodo){
 const a=p.a||3, b=p.b||4, c=Math.sqrt(a*a+b*b);
 const sc=Math.min(14,120/Math.max(a,b)), ox=88, oy=152;
 const svg=svgEl('svg',{viewBox:'0 0 320 200',role:'img','aria-label':'Triángulo rectángulo (Pitágoras)'});
 svg.appendChild(svgEl('rect',{x:ox,y:oy,width:a*sc,height:a*sc,fill:'#8f6bff33',stroke:'#8f6bff','stroke-width':1.5}));
 svg.appendChild(svgEl('rect',{x:ox-b*sc,y:oy-b*sc,width:b*sc,height:b*sc,fill:'#4dd8ff33',stroke:'#4dd8ff','stroke-width':1.5}));
 svg.appendChild(svgEl('polygon',{points:`${ox},${oy} ${ox+a*sc},${oy} ${ox},${oy-b*sc}`,fill:'#3ee08944',stroke:'#3ee089','stroke-width':2}));
 svg.appendChild(svgEl('path',{d:`M${ox+11},${oy} L${ox+11},${oy-11} L${ox},${oy-11}`,fill:'none',stroke:'#eee6ff','stroke-width':1.5}));
 function tx(x,y,s,col,fs,fam){const t=svgEl('text',{x,y,'text-anchor':'middle',fill:col,'font-size':fs||12});if(fam)t.setAttribute('font-family',fam);t.textContent=s;svg.appendChild(t);}
 tx(ox+a*sc/2, oy+a*sc/2+4, 'a²', '#c9b8ff', 13);
 tx(ox-b*sc/2, oy-b*sc/2+4, 'b²', '#bfeeff', 13);
 tx(ox+a*sc/2, oy-8, 'a='+a, '#8f6bff', 12);
 tx(ox-10, oy-b*sc/2, 'b='+b, '#4dd8ff', 12);
 tx(ox+a*sc/2+18, oy-b*sc/2-2, 'c='+(Number.isInteger(c)?c:c.toFixed(2)), '#3ee089', 12);
 tx(234, 44, `${a}² + ${b}² = ${a*a+b*b}`, '#ffc93c', 15, "'Titan One',sans-serif");
 tx(234, 64, `${a*a} + ${b*b} = ${a*a+b*b}`, '#a99fd0', 12);
 nodo.appendChild(svg);
};
```

- [ ] **Paso 2: Implementar `solido` (prisma y cilindro)**

```js
// solido: prisma recto o cilindro (pseudo-3D), con etiquetas y fórmula.
// params: {tipo:'prisma'|'cilindro'}
DIAGRAMAS.solido=function(p,nodo){
 const tipo=p.tipo||'prisma';
 const svg=svgEl('svg',{viewBox:'0 0 320 190',role:'img','aria-label':'Cuerpo geométrico'});
 function tx(x,y,s,col,fs,fam,rot){const t=svgEl('text',{x,y,'text-anchor':'middle',fill:col,'font-size':fs||12});if(fam)t.setAttribute('font-family',fam);if(rot)t.setAttribute('transform',`rotate(-90 ${x} ${y})`);t.textContent=s;svg.appendChild(t);}
 if(tipo==='cilindro'){
  const cx=120,rx=50,ry=15,topY=52,h=88;
  svg.appendChild(svgEl('line',{x1:cx-rx,y1:topY,x2:cx-rx,y2:topY+h,stroke:'#4dd8ff','stroke-width':2}));
  svg.appendChild(svgEl('line',{x1:cx+rx,y1:topY,x2:cx+rx,y2:topY+h,stroke:'#4dd8ff','stroke-width':2}));
  svg.appendChild(svgEl('path',{d:`M${cx-rx},${topY+h} A${rx},${ry} 0 0 0 ${cx+rx},${topY+h}`,fill:'none',stroke:'#4dd8ff','stroke-width':2}));
  svg.appendChild(svgEl('path',{d:`M${cx-rx},${topY+h} A${rx},${ry} 0 0 1 ${cx+rx},${topY+h}`,fill:'none',stroke:'#5a4b8f','stroke-width':1,'stroke-dasharray':'3 3'}));
  svg.appendChild(svgEl('ellipse',{cx:cx,cy:topY,rx:rx,ry:ry,fill:'#8f6bff55',stroke:'#8f6bff','stroke-width':1.5}));
  svg.appendChild(svgEl('line',{x1:cx,y1:topY,x2:cx+rx,y2:topY,stroke:'#ffc93c','stroke-width':1.5}));
  tx(cx+rx/2, topY-5, 'r', '#ffc93c', 12);
  tx(cx-rx-12, topY+h/2, 'altura', '#3ee089', 12, null, true);
  tx(234, 150, 'V = π·r²·altura', '#ffc93c', 13, "'Titan One',sans-serif");
 } else {
  const x=78,y=72,w=96,h=84,dx=44,dy=28;
  svg.appendChild(svgEl('path',{d:`M${x},${y} L${x+dx},${y-dy} M${x},${y+h} L${x+dx},${y+h-dy} L${x+w+dx},${y+h-dy} L${x+w+dx},${y-dy}`,fill:'none',stroke:'#5a4b8f','stroke-width':1,'stroke-dasharray':'3 3'}));
  svg.appendChild(svgEl('polygon',{points:`${x},${y} ${x+dx},${y-dy} ${x+w+dx},${y-dy} ${x+w},${y}`,fill:'#8f6bff55',stroke:'#8f6bff','stroke-width':1.5}));
  svg.appendChild(svgEl('polygon',{points:`${x+w},${y} ${x+w+dx},${y-dy} ${x+w+dx},${y+h-dy} ${x+w},${y+h}`,fill:'#6f52cc55',stroke:'#8f6bff','stroke-width':1.5}));
  svg.appendChild(svgEl('rect',{x:x,y:y,width:w,height:h,fill:'#4dd8ff33',stroke:'#4dd8ff','stroke-width':2}));
  tx(x+w/2, y+h+18, 'base', '#4dd8ff', 12);
  tx(x-12, y+h/2, 'altura', '#3ee089', 12, null, true);
  tx(234, 150, 'V = base × altura', '#ffc93c', 13, "'Titan One',sans-serif");
 }
 nodo.appendChild(svg);
};
```

- [ ] **Paso 3: Verificar en el navegador**

`preview_start {name:"kimun"}`, navega a `http://localhost:8765/`. En consola:

```js
var n=document.createElement('div');document.body.appendChild(n);
montarDiagrama('triangulo',{a:3,b:4},n);
n.querySelector('svg')!==null;   // true; debe verse la ecuación "3² + 4² = 25"
montarDiagrama('solido',{tipo:'prisma'},n);   n.querySelector('polygon')!==null;  // true (caras del prisma)
montarDiagrama('solido',{tipo:'cilindro'},n); n.querySelector('ellipse')!==null;  // true (tapa del cilindro)
```

Confirma que `triangulo` muestra el triángulo con los dos cuadrados de catetos y la ecuación; `solido` prisma muestra un cuerpo 3D con "base"/"altura"; `solido` cilindro muestra la tapa elíptica con "V = π·r²·altura". Sin errores nuevos.

---

## Tarea 2: Widget `transformacion` (reflexión, traslación, rotación)

**Archivos:** Modificar `index.html` (bloque "CATÁLOGO DE DIAGRAMAS")

- [ ] **Paso 1: Implementar `transformacion`**

```js
// transformacion: una figura y su imagen tras reflexión, traslación o rotación (90°).
// params: {tipo:'reflexion'|'traslacion'|'rotacion', vector:[vx,vy], figura:[[x,y],...], etiqueta}
DIAGRAMAS.transformacion=function(p,nodo){
 const tipo=p.tipo||'reflexion';
 const fig=p.figura||[[1,1],[4,1],[1,3.5]];
 const cx=160,cy=100,sc=17;
 const svg=svgEl('svg',{viewBox:'0 0 320 190',role:'img','aria-label':'Transformación en el plano'});
 for(let i=-4;i<=4;i++){const gx=cx+i*sc,gy=cy+i*sc;
  if(gx>=8&&gx<=312)svg.appendChild(svgEl('line',{x1:gx,y1:12,x2:gx,y2:188,stroke:'#2c2350','stroke-width':1}));
  if(gy>=12&&gy<=188)svg.appendChild(svgEl('line',{x1:8,y1:gy,x2:312,y2:gy,stroke:'#2c2350','stroke-width':1}));}
 svg.appendChild(svgEl('line',{x1:8,y1:cy,x2:312,y2:cy,stroke:'#7a6ab0','stroke-width':1.5}));
 svg.appendChild(svgEl('line',{x1:cx,y1:12,x2:cx,y2:188,stroke:'#7a6ab0','stroke-width':1.5}));
 const S=(x,y)=>`${cx+x*sc},${cy-y*sc}`;
 let img, rotulo;
 if(tipo==='traslacion'){ const v=p.vector||[-5,0]; img=fig.map(q=>[q[0]+v[0],q[1]+v[1]]); rotulo='Traslación'; }
 else if(tipo==='rotacion'){ img=fig.map(q=>[-q[1],q[0]]); rotulo='Rotación (90°)'; }
 else { img=fig.map(q=>[-q[0],q[1]]); rotulo='Reflexión (eje y)'; }
 if(tipo==='reflexion') svg.appendChild(svgEl('line',{x1:cx,y1:12,x2:cx,y2:188,stroke:'#ffc93c','stroke-width':2,'stroke-dasharray':'5 4'}));
 svg.appendChild(svgEl('polygon',{points:fig.map(q=>S(q[0],q[1])).join(' '),fill:'#8f6bff66',stroke:'#8f6bff','stroke-width':2}));
 svg.appendChild(svgEl('polygon',{points:img.map(q=>S(q[0],q[1])).join(' '),fill:'#3ee08944',stroke:'#3ee089','stroke-width':2,'stroke-dasharray':'4 3'}));
 if(tipo==='traslacion'){ // flecha del vector, del primer vértice a su imagen
  svg.appendChild(svgEl('line',{x1:cx+fig[0][0]*sc,y1:cy-fig[0][1]*sc,x2:cx+img[0][0]*sc,y2:cy-img[0][1]*sc,stroke:'#ffc93c','stroke-width':2}));
 }
 const t=svgEl('text',{x:160,y:184,'text-anchor':'middle',fill:'#ffc93c','font-size':11});
 t.textContent=p.etiqueta||rotulo; svg.appendChild(t);
 nodo.appendChild(svg);
};
```

- [ ] **Paso 2: Verificar en el navegador**

```js
var n=document.createElement('div');document.body.appendChild(n);
['reflexion','traslacion','rotacion'].forEach(t=>{montarDiagrama('transformacion',{tipo:t},n);});
montarDiagrama('transformacion',{tipo:'reflexion'},n); n.querySelectorAll('polygon').length===2;  // figura + imagen
```

Confirma que los 3 tipos dibujan la figura (violeta) y su imagen (verde punteada) sin lanzar: `reflexion` con el eje dorado y la imagen al otro lado del eje y; `traslacion` con la imagen desplazada y una flecha; `rotacion` con la imagen girada 90°. Sin errores nuevos.

---

## Tarea 3: Contenido (4 lecciones OA11–14) y activación del capítulo

**Archivos:** Modificar `contenido/matematicas-8basico/lecciones.json` y `index.html` (entrada `'mate'`)

- [ ] **Paso 1: Agregar 4 lecciones a `lecciones.json`** (después de `ma-oa10`). Ids
  `ma-oa11`..`ma-oa14`, oa `"MA08 OA 11"`..`"MA08 OA 14"` (formato EXACTO). Matemática
  correcta, español neutro.

- **`ma-oa11` — "Área y volumen de prismas y cilindros":**
  - `texto`: un prisma recto tiene dos bases iguales y caras rectangulares. Su volumen es el área de la base multiplicada por la altura.
  - `diagrama` `solido` `{"tipo":"prisma"}`, `intro`: "El volumen mide cuánto cabe dentro: base × altura."
  - `texto`: el cilindro es como un prisma de base circular; su volumen es π·r²·altura (el área del círculo por la altura).
  - `diagrama` `solido` `{"tipo":"cilindro"}`
  - `ejemplo` `["Prisma de base 4 × 3 y altura 5","Área de la base = 4 · 3 = 12","Volumen = 12 · 5 = 60"]`
  - `practica` `{"oa":"MA08 OA 11","n":3}`
- **`ma-oa12` — "El teorema de Pitágoras":**
  - `texto`: en un triángulo rectángulo, el cuadrado de la hipotenusa (el lado más largo) es igual a la suma de los cuadrados de los catetos: a² + b² = c².
  - `diagrama` `triangulo` `{"a":3,"b":4}`, `intro`: "Los cuadrados de los catetos (a² y b²) suman el cuadrado de la hipotenusa."
  - `texto`: sirve para hallar un lado cuando conoces los otros dos.
  - `ejemplo` `["Catetos a = 3 y b = 4","3² + 4² = 9 + 16 = 25","c = √25 = 5"]`
  - `practica` `{"oa":"MA08 OA 12","n":3}`
- **`ma-oa13` — "Movimientos en el plano":**
  - `texto`: una figura se puede mover sin cambiar su forma ni su tamaño. Hay tres movimientos: trasladar (deslizar), reflejar (como un espejo) y rotar (girar).
  - `diagrama` `transformacion` `{"tipo":"reflexion"}`, `intro`: "La reflexión crea una imagen espejo al otro lado de un eje."
  - `diagrama` `transformacion` `{"tipo":"traslacion"}`, `intro`: "La traslación desliza la figura según un vector."
  - `texto`: la reflexión usa un eje; la traslación, un vector; la rotación, un punto y un ángulo.
  - `ejemplo` `["Reflejar el punto (2, 3) sobre el eje y","Cambia el signo de x","La imagen es (−2, 3)"]`
  - `practica` `{"oa":"MA08 OA 13","n":3}`
- **`ma-oa14` — "Componer transformaciones y simetría":**
  - `texto`: puedes aplicar varias transformaciones seguidas (componer). Una figura tiene simetría si, al reflejarla, se ve igual.
  - `diagrama` `transformacion` `{"tipo":"rotacion"}`, `intro`: "Al rotar 90°, la figura gira alrededor de un punto."
  - `texto`: las teselaciones cubren el plano repitiendo una figura con estos movimientos, sin dejar huecos.
  - `ejemplo` `["Rotar el punto (1, 0) un cuarto de vuelta (90°)","Gira alrededor del origen","La imagen es (0, 1)"]`
  - `practica` `{"oa":"MA08 OA 14","n":3}`

- [ ] **Paso 2: Activar el capítulo `mate-geometria` en `index.html`** — en la entrada
  `'mate'` de `CAMPAÑAS`, quita `proximamente:true` del capítulo `mate-geometria` y pon:

```js
    {id:'mate-geometria', titulo:'Geometría', lecciones:['ma-oa11','ma-oa12','ma-oa13','ma-oa14']},
```

- [ ] **Paso 3: Verificar**

1. Valida JSON y códigos OA:
```
python -c "import json;d=json.load(open('contenido/matematicas-8basico/lecciones.json',encoding='utf-8'));print(len(d['lecciones']),'lecciones');[print(l['id'],l['oa']) for l in d['lecciones']]"
python -c "import json;b=set(q['oa'] for q in json.load(open('contenido/matematicas-8basico/preguntas.json',encoding='utf-8'))['preguntas']);L=json.load(open('contenido/matematicas-8basico/lecciones.json',encoding='utf-8'))['lecciones'];[print(l['id'],'OK' if all(fb['fromBank']['oa'] in b for fb in l['bloques'] if fb['t']=='practica') else 'FALTA') for l in L]"
```
   Esperado: 14 lecciones (ma-oa01..ma-oa14), todas OK.
2. En el navegador: `localStorage.clear()`, recarga, simula Números y Álgebra completos:
```js
S.mateLecciones={}; ['ma-oa01','ma-oa02','ma-oa03','ma-oa04','ma-oa05','ma-oa06','ma-oa07','ma-oa08','ma-oa09','ma-oa10'].forEach(id=>S.mateLecciones[id]=1); guardar();
```
   JUGADOR → Matemáticas: el capítulo **Geometría** debe estar ABIERTO (0/4). Entra: 4 lecciones. Abre `ma-oa12` (triangulo), `ma-oa11` (solido prisma+cilindro) y `ma-oa13` (transformacion reflexión+traslación); confirma que cada diagrama se ve y que la práctica carga 3 preguntas del OA correcto y marca ✓.
3. read_console_messages: sin errores nuevos (benignos: "Diagrama rota", `navigator.vibrate`, 404 de portadas).

---

## Tarea 4: Revisión final (Cap 3)

- [ ] **Paso 1: Recorrido end-to-end + regresión.** Con Números y Álgebra completos, juega
  una lección de Geometría completa (recomendado `ma-oa12` Pitágoras: texto → triangulo →
  texto → ejemplo → práctica → ✓). Confirma que registra dominio (OA12) y desbloquea la
  siguiente. Verifica que las Unidades 1 y 2 siguen jugables, que Historia/Ciencias/Lenguaje
  y el Reto no cambiaron, y que no hay errores nuevos de consola. Revisa que las cuentas de
  los ejemplos OA11–14 sean correctas (V=60; 3²+4²=25, c=5; (2,3)→(−2,3); (1,0)→(0,1)).

---

## Auto-revisión del plan
- **Cobertura:** OA11 (solido), OA12 (triangulo), OA13/OA14 (transformacion) → 3 widgets
  (T1–T2) + 4 lecciones (T3) + activación (T3 P2) + verificación/regresión (T4).
- **Sin placeholders:** código de los 3 widgets completo y ya prototipado; contenido de las
  4 lecciones especificado bloque por bloque con sus cuentas.
- **Consistencia:** widgets registrados en `DIAGRAMAS` como el resto; lecciones con el mismo
  esquema; capítulo activado quitando `proximamente` y poblando `lecciones`.
