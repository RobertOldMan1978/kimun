# Camino de aprendizaje de Matemáticas — Plan 2 (Cap 2: Álgebra y funciones)

> **Para el trabajador agéntico:** SUB-SKILL: superpowers:subagent-driven-development.
> Los pasos usan casillas `- [ ]`. **Regla del proyecto: NO commitear** (se commitea solo
> con "orden 66"); cada tarea termina en verificación en el navegador, no en commit.

**Objetivo:** agregar la **Unidad 2 (Álgebra y funciones, OA06–10)** al camino de
aprendizaje de Matemáticas, reusando el motor de lecciones ya construido (Plan 1). Se
suman 3 widgets de diagrama (`funcion`, `algebra`, `balanza`); OA09 reusa el widget
`recta` existente. Se activa el capítulo `mate-algebra` (hoy "🔒 Pronto").

**Arquitectura:** sin cambios de motor. Se agregan widgets al catálogo `DIAGRAMAS`
(bloque "CATÁLOGO DE DIAGRAMAS" en `index.html`), 5 lecciones a
`contenido/matematicas-8basico/lecciones.json`, y se edita la entrada `'mate'` de
`CAMPAÑAS` para activar el capítulo 2. El desbloqueo secuencial ya está cableado
(`renderCampañaMate`: el capítulo 2 se abre cuando el 1 —Números— está completo).

**Verificación:** en el navegador (`preview_start {name:"kimun"}`, `http://localhost:8765/`),
como en el Plan 1. Sin framework de tests.

**Idioma:** todo el texto y los comentarios en **español latino neutro** (tratamiento
"tú"; sin voseo ni modismos). El contenido matemático debe ser correcto y de nivel 8°.

---

## Tarea 1: Widget `funcion` (recta f(x)=ax+b con deslizadores)

**Archivos:** Modificar `index.html` (bloque "CATÁLOGO DE DIAGRAMAS", junto a `recta`/`fracciones`/`potencias`)

- [ ] **Paso 1: Implementar el widget**

Agrega al bloque del catálogo:

```js
// funcion: recta f(x)=a·x+b sobre un plano cartesiano, con deslizadores de a y b.
// params: {a=1, b=0, interactivo=true}
DIAGRAMAS.funcion=function(p,nodo){
 const inter=p.interactivo!==false, a0=p.a??1, b0=p.b??0;
 const cx=150,cy=110,sc=13,W=300,H=220;   // sc = px por unidad
 const svg=svgEl('svg',{viewBox:`0 0 ${W} ${H}`,role:'img','aria-label':'Función lineal'});
 for(let i=-10;i<=10;i++){ if(i===0)continue;
  const gx=cx+i*sc, gy=cy+i*sc;
  if(gx>=0&&gx<=W) svg.appendChild(svgEl('line',{x1:gx,y1:0,x2:gx,y2:H,stroke:'#2c2350','stroke-width':1}));
  if(gy>=0&&gy<=H) svg.appendChild(svgEl('line',{x1:0,y1:gy,x2:W,y2:gy,stroke:'#2c2350','stroke-width':1}));
 }
 svg.appendChild(svgEl('line',{x1:0,y1:cy,x2:W,y2:cy,stroke:'#7a6ab0','stroke-width':1.5}));
 svg.appendChild(svgEl('line',{x1:cx,y1:0,x2:cx,y2:H,stroke:'#7a6ab0','stroke-width':1.5}));
 const linea=svgEl('line',{stroke:'#3ee089','stroke-width':3,'stroke-linecap':'round'});
 const punto=svgEl('circle',{r:4,fill:'#ff4d8d'});
 svg.appendChild(linea); svg.appendChild(punto);
 nodo.appendChild(svg);
 const eq=document.createElement('div'); eq.style.cssText='font-size:14px;margin-top:6px';
 nodo.appendChild(eq);
 function draw(a,b){
  eq.innerHTML=`f(x) = <b style="color:#4dd8ff">${a}</b>·x + <b style="color:#4dd8ff">${b}</b>`;
  const xL=-10,xR=10;
  linea.setAttribute('x1',cx+xL*sc); linea.setAttribute('y1',cy-(a*xL+b)*sc);
  linea.setAttribute('x2',cx+xR*sc); linea.setAttribute('y2',cy-(a*xR+b)*sc);
  punto.setAttribute('cx',cx); punto.setAttribute('cy',cy-b*sc);
 }
 if(inter){
  const mk=(lbl,min,max,st,val,on)=>{
   const r=document.createElement('div');
   r.style.cssText='display:flex;align-items:center;gap:8px;margin-top:6px;font-size:12px';
   const l=document.createElement('label');l.textContent=lbl;l.style.cssText='width:92px;color:#a99fd0';
   const inp=document.createElement('input');inp.type='range';inp.min=min;inp.max=max;inp.step=st;inp.value=val;
   inp.style.cssText='flex:1;accent-color:#8f6bff';
   const v=document.createElement('span');v.textContent=val;
   v.style.cssText='color:#ffc93c;font-family:"Titan One",sans-serif;min-width:24px;text-align:right';
   inp.addEventListener('input',()=>{v.textContent=inp.value;on();});
   r.append(l,inp,v); nodo.appendChild(r); return inp;
  };
  let aI,bI; const redo=()=>draw(parseFloat(aI.value),parseFloat(bI.value));
  aI=mk('pendiente a',-3,3,0.5,a0,redo);
  bI=mk('intercepto b',-5,5,1,b0,redo);
 }
 draw(a0,b0);
};
```

- [ ] **Paso 2: Verificar en el navegador**

`preview_start {name:"kimun"}`. En consola:

```js
var n=document.createElement('div');document.body.appendChild(n);
montarDiagrama('funcion',{a:2,b:0},n);
n.querySelector('svg')!==null;                       // true
n.querySelectorAll('input[type=range]').length;      // 2 (deslizadores a y b)
```

Debe verse el plano con la recta verde. Mueve un deslizador (`var s=n.querySelector('input');s.value=1;s.dispatchEvent(new Event('input'))`) y confirma que la ecuación de arriba cambia y la recta se redibuja. Prueba también no interactivo: `montarDiagrama('funcion',{a:1,b:2,interactivo:false},n)` → sin deslizadores, recta dibujada. Sin errores nuevos en consola.

---

## Tarea 2: Widgets `algebra` (fichas de términos) y `balanza` (ecuación)

**Archivos:** Modificar `index.html` (bloque "CATÁLOGO DE DIAGRAMAS")

- [ ] **Paso 1: Implementar `algebra`**

```js
// algebra: fichas de una expresión. Fichas altas = "x", cuadritos = unidades.
// params: {x=0, u=0, etiqueta:'2x + 3'}
DIAGRAMAS.algebra=function(p,nodo){
 const nx=Math.max(0,p.x||0), nu=Math.max(0,p.u||0);
 const svg=svgEl('svg',{viewBox:'0 0 320 92',role:'img','aria-label':'Términos algebraicos'});
 let cxp=14;
 for(let i=0;i<nx;i++){
  svg.appendChild(svgEl('rect',{x:cxp,y:18,width:26,height:46,rx:5,fill:'#8f6bff',stroke:'#4dd8ff','stroke-width':1.5}));
  const t=svgEl('text',{x:cxp+13,y:47,'text-anchor':'middle',fill:'#fff','font-family':"'Titan One',sans-serif",'font-size':16});
  t.textContent='x'; svg.appendChild(t); cxp+=32;
 }
 cxp+=10;
 for(let i=0;i<nu;i++){
  svg.appendChild(svgEl('rect',{x:cxp,y:40,width:22,height:22,rx:4,fill:'#4dd8ff',stroke:'#241a44','stroke-width':1}));
  const t=svgEl('text',{x:cxp+11,y:56,'text-anchor':'middle',fill:'#241a44','font-size':12});
  t.textContent='1'; svg.appendChild(t); cxp+=26;
 }
 if(p.etiqueta){const t=svgEl('text',{x:160,y:84,'text-anchor':'middle',fill:'#ffc93c','font-family':"'Titan One',sans-serif",'font-size':15});t.textContent=p.etiqueta;svg.appendChild(t);}
 nodo.appendChild(svg);
};
```

- [ ] **Paso 2: Implementar `balanza`**

```js
// balanza: una ecuación como equilibrio. Fichas "x" (altas) y unidades a cada lado.
// params: {izqX=0, izqU=0, derX=0, derU=0, etiqueta:'2x + 1 = 7'}
DIAGRAMAS.balanza=function(p,nodo){
 const svg=svgEl('svg',{viewBox:'0 0 320 152',role:'img','aria-label':'Ecuación en balanza'});
 svg.appendChild(svgEl('line',{x1:44,y1:40,x2:276,y2:40,stroke:'#7a6ab0','stroke-width':4,'stroke-linecap':'round'}));
 svg.appendChild(svgEl('line',{x1:160,y1:40,x2:160,y2:120,stroke:'#7a6ab0','stroke-width':4}));
 svg.appendChild(svgEl('path',{d:'M142 120 H178 L168 134 H152 Z',fill:'#5a4b8f'}));
 function plato(cxp,nx,nu){
  svg.appendChild(svgEl('line',{x1:cxp,y1:40,x2:cxp,y2:66,stroke:'#5a4b8f','stroke-width':2}));
  svg.appendChild(svgEl('rect',{x:cxp-46,y:66,width:92,height:8,rx:4,fill:'#5a4b8f'}));
  let bx=cxp-40;
  for(let i=0;i<nx;i++){
   svg.appendChild(svgEl('rect',{x:bx,y:42,width:18,height:22,rx:3,fill:'#8f6bff'}));
   const t=svgEl('text',{x:bx+9,y:58,'text-anchor':'middle',fill:'#fff','font-size':11});t.textContent='x';svg.appendChild(t);
   bx+=22;
  }
  for(let i=0;i<nu;i++){
   svg.appendChild(svgEl('rect',{x:bx,y:50,width:14,height:14,rx:2,fill:'#4dd8ff'}));
   bx+=17;
  }
 }
 plato(90,p.izqX||0,p.izqU||0);
 plato(230,p.derX||0,p.derU||0);
 if(p.etiqueta){const t=svgEl('text',{x:160,y:148,'text-anchor':'middle',fill:'#ffc93c','font-family':"'Titan One',sans-serif",'font-size':15});t.textContent=p.etiqueta;svg.appendChild(t);}
 nodo.appendChild(svg);
};
```

- [ ] **Paso 3: Verificar en el navegador**

```js
var n=document.createElement('div');document.body.appendChild(n);
montarDiagrama('algebra',{x:2,u:3,etiqueta:'2x + 3'},n);
n.querySelectorAll('rect').length;   // 5 (2 fichas x + 3 unidades)
montarDiagrama('balanza',{izqX:2,izqU:1,derU:7,etiqueta:'2x + 1 = 7'},n);
n.querySelectorAll('rect').length>=10;  // fichas + platos
```

Confirma que `algebra` muestra 2 fichas "x" grandes + 3 cuadritos "1" y la etiqueta; `balanza` muestra una balanza con 2 fichas "x" y 1 unidad a la izquierda, 7 unidades a la derecha, y la ecuación abajo. Sin errores nuevos.

---

## Tarea 3: Contenido (5 lecciones OA06–10) y activación del capítulo

**Archivos:** Modificar `contenido/matematicas-8basico/lecciones.json` y `index.html` (entrada `'mate'` de `CAMPAÑAS`)

- [ ] **Paso 1: Agregar 5 lecciones al arreglo `lecciones` de `lecciones.json`**

Agrega estas 5 lecciones (después de `ma-oa05`). Ids `ma-oa06`..`ma-oa10`, oa `"MA08 OA 06"`..`"MA08 OA 10"` (formato EXACTO del banco, con espacios). Matemática correcta y neutra. Bloques indicados:

- **`ma-oa06` — "Lenguaje algebraico y expresiones":** `texto` (una letra representa un número desconocido; "el doble de un número" se escribe 2·n); `diagrama` `algebra` `{"x":2,"u":3,"etiqueta":"2x + 3"}` con `intro` que explique "dos fichas x y tres unidades"; `texto` (términos semejantes: solo se juntan los que tienen la misma parte con letra; la propiedad distributiva: a(b+c)=ab+ac); `ejemplo` (`["2x + 3x","Son términos semejantes (los dos tienen x)","= 5x"]`); `ejemplo` (`["3·(x + 2)","Reparte el 3: 3·x + 3·2","= 3x + 6"]`); `practica` `{"oa":"MA08 OA 06","n":3}`.
- **`ma-oa07` — "La función lineal":** `texto` (una función relaciona dos cantidades: para cada valor de x hay un valor de y; la función lineal tiene la forma y = a·x y pasa por el origen); `diagrama` `funcion` `{"a":2,"b":0}` con `intro` "mueve la pendiente y observa cómo cambia la recta"; `texto` (la pendiente a indica cuánto sube y por cada 1 que avanza x); `ejemplo` (`["Si y = 3x","cuando x = 2","y = 3·2 = 6"]`); `practica` `{"oa":"MA08 OA 07","n":3}`.
- **`ma-oa08` — "Ecuaciones de primer grado":** `texto` (una ecuación es una igualdad con una incógnita; resolverla es hallar el valor de x que la hace verdadera; funciona como una balanza en equilibrio); `diagrama` `balanza` `{"izqX":2,"izqU":1,"derU":7,"etiqueta":"2x + 1 = 7"}` con `intro` "los dos lados pesan lo mismo"; `texto` (para despejar x haces lo MISMO a ambos lados: restar, sumar, dividir); `ejemplo` (`["2x + 1 = 7","Resta 1 a ambos lados: 2x = 6","Divide por 2: x = 3"]`); `practica` `{"oa":"MA08 OA 08","n":3}`.
- **`ma-oa09` — "Inecuaciones":** `texto` (una inecuación usa <, >, ≤ o ≥ en vez de =; su solución no es un solo número, sino un conjunto de números); `diagrama` `recta` `{"min":-6,"max":6,"marca":4,"interactivo":true,"intervalo":{"desde":2,"tipo":">"}}` con `intro` "el círculo abierto en el 2 significa que el 2 no entra; todos los mayores sí"; `texto` (se resuelve casi como una ecuación, PERO al multiplicar o dividir por un número negativo se INVIERTE el signo de la desigualdad); `ejemplo` (`["x + 3 > 5","Resta 3: x > 2"]`); `ejemplo` (`["−2x > 4","Divide por −2 e invierte el signo","x < −2"]`); `practica` `{"oa":"MA08 OA 09","n":3}`.
- **`ma-oa10` — "La función afín":** `texto` (la función afín tiene la forma f(x) = a·x + b; a es la pendiente —cuánto sube— y b es el valor inicial —dónde corta el eje y—); `diagrama` `funcion` `{"a":1,"b":2}` con `intro` "mueve a y b: b sube o baja la recta, a cambia su inclinación"; `texto` (si b = 0 es una función lineal; si b ≠ 0 la recta no pasa por el origen); `ejemplo` (`["f(x) = 2x + 1","en x = 0: f(0) = 1","en x = 1: f(1) = 3"]`); `practica` `{"oa":"MA08 OA 10","n":3}`.

- [ ] **Paso 2: Activar el capítulo `mate-algebra` en `CAMPAÑAS`**

En `index.html`, en la entrada `'mate'` de `CAMPAÑAS`, capítulo `mate-algebra`: quita
`proximamente:true` y pon sus lecciones. Debe quedar:

```js
    {id:'mate-algebra', titulo:'Álgebra y funciones', lecciones:['ma-oa06','ma-oa07','ma-oa08','ma-oa09','ma-oa10']},
```

- [ ] **Paso 3: Verificar**

1. Valida el JSON y los códigos OA:
```
python -c "import json;d=json.load(open('contenido/matematicas-8basico/lecciones.json',encoding='utf-8'));print(len(d['lecciones']),'lecciones');[print(l['id'],l['oa']) for l in d['lecciones']]"
python -c "import json;b=set(q['oa'] for q in json.load(open('contenido/matematicas-8basico/preguntas.json',encoding='utf-8'))['preguntas']);L=json.load(open('contenido/matematicas-8basico/lecciones.json',encoding='utf-8'))['lecciones'];[print(l['id'],'OK' if all(fb['fromBank']['oa'] in b for fb in l['bloques'] if fb['t']=='practica') else 'FALTA') for l in L]"
```
Esperado: 10 lecciones (ma-oa01..ma-oa10), todas OK.

2. En el navegador (`preview_start {name:"kimun"}`): `localStorage.clear()`, recarga.
   Como el capítulo 2 se abre solo si Números está completo, simula Números completo:
```js
S.mateLecciones={'ma-oa01':1,'ma-oa02':1,'ma-oa03':1,'ma-oa04':1,'ma-oa05':1}; guardar();
```
   Entra a JUGADOR → Matemáticas: el capítulo **Álgebra y funciones** debe estar **abierto** (0/5 lecciones), no "🔒 Pronto". Entra: 5 lecciones (ma-oa06..ma-oa10). Abre `ma-oa07` (función lineal) y recórrela: debe mostrar el widget `funcion` con deslizadores; la práctica carga 3 preguntas de "MA08 OA 07". Abre `ma-oa08`: debe mostrar la `balanza`. Abre `ma-oa09`: debe mostrar la `recta` con intervalo. Todas terminan marcando ✓.
3. `read_console_messages`: sin errores nuevos.

---

## Tarea 4: Revisión final del conjunto (Cap 2)

- [ ] **Paso 1: Recorrido end-to-end + coherencia**

En el navegador, con Números marcado completo (paso anterior), juega **una lección
completa de Álgebra** (recomendado `ma-oa08` ecuaciones, de punta a punta: texto →
balanza → texto → ejemplo → práctica → ✓). Confirma que registra dominio (OA08) y vuelve
a la lista con la lección en ✓ y la siguiente abierta.

- [ ] **Paso 2: Regresión**

Confirma que la **Unidad 1 (Números)** sigue jugable e intacta, que **Historia/Ciencias/
Lenguaje** y el **Reto de Cálculo** no cambiaron, y que no hay errores nuevos de consola
(los únicos benignos: el auto-test "Diagrama rota", `navigator.vibrate`, y 404 de portadas
`portada-mate-*.png`).

---

## Auto-revisión del plan

- **Cobertura:** los 5 OA de la Unidad 2 (OA06–10) → 5 lecciones (T3). Widgets nuevos
  `funcion` (OA07/OA10), `algebra` (OA06), `balanza` (OA08) en T1–T2; OA09 reusa `recta`.
  Activación del capítulo (T3 P2). Verificación end-to-end + regresión (T4).
- **Sin placeholders:** el código de los 3 widgets está completo; el contenido de las 5
  lecciones está especificado bloque por bloque (tipo, kind, params, fromBank) con los
  ejemplos y sus cuentas.
- **Consistencia:** `funcion`/`algebra`/`balanza` se registran en `DIAGRAMAS` igual que
  los widgets del Plan 1; las lecciones usan el mismo esquema; el capítulo se activa
  quitando `proximamente` y poblando `lecciones`, que `renderCampañaMate` ya sabe leer.
```
