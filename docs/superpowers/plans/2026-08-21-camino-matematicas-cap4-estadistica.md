# Camino de aprendizaje de Matemáticas — Plan 4 (Cap 4: Probabilidad y estadística)

> **Para el trabajador agéntico:** SUB-SKILL: superpowers:subagent-driven-development.
> Pasos con casillas `- [ ]`. **NO commitear** (solo con "orden 66"); cada tarea termina en
> verificación en el navegador. Idioma: **español latino neutro**; matemática correcta 8°.

**Objetivo:** agregar la **Unidad 4 (Probabilidad y estadística, OA15–17)** al camino de
aprendizaje de Matemáticas —la última unidad—, reusando el motor de lecciones. Se suman 3
widgets (`cajon`, `barras`, `arbol`) y se activa el capítulo `mate-datos` (hoy "🔒 Pronto").
Con esto Matemáticas queda con las 4 unidades construidas.

**Arquitectura:** sin cambios de motor. Widgets al catálogo `DIAGRAMAS` en `index.html`;
3 lecciones a `contenido/matematicas-8basico/lecciones.json`; se edita la entrada `'mate'`
de `CAMPAÑAS` para activar el capítulo 4 (se abre al completar Geometría). El código de los
widgets ya se prototipó y validó visualmente.

**Verificación:** navegador (`preview_start {name:"kimun"}`, navegar EXPLÍCITAMENTE a
`http://localhost:8765/` en pestaña limpia). Banco: OA15–17 tienen 30 preguntas cada uno.

---

## Tarea 1: Widgets `cajon`, `barras` y `arbol`

**Archivos:** Modificar `index.html` (bloque "CATÁLOGO DE DIAGRAMAS", junto a los otros `DIAGRAMAS.*`)

- [ ] **Paso 1: Implementar `cajon`**

```js
// cajon: diagrama de cajón (mín, Q1, mediana, Q3, máx).
// params: {min, q1, mediana, q3, max}
DIAGRAMAS.cajon=function(p,nodo){
 const mn=p.min??2, q1=p.q1??5, md=p.mediana??7, q3=p.q3??10, mx=p.max??14;
 const x0=36,x1=284,yy=62;
 const svg=svgEl('svg',{viewBox:'0 0 320 116',role:'img','aria-label':'Diagrama de cajón'});
 const den=(mx-mn)||1, xf=v=>x0+(v-mn)/den*(x1-x0);
 svg.appendChild(svgEl('line',{x1:xf(mn),y1:yy,x2:xf(q1),y2:yy,stroke:'#7a6ab0','stroke-width':2}));
 svg.appendChild(svgEl('line',{x1:xf(q3),y1:yy,x2:xf(mx),y2:yy,stroke:'#7a6ab0','stroke-width':2}));
 [mn,mx].forEach(v=>svg.appendChild(svgEl('line',{x1:xf(v),y1:yy-9,x2:xf(v),y2:yy+9,stroke:'#7a6ab0','stroke-width':2})));
 svg.appendChild(svgEl('rect',{x:xf(q1),y:yy-16,width:Math.max(1,xf(q3)-xf(q1)),height:32,rx:4,fill:'#8f6bff44',stroke:'#8f6bff','stroke-width':2}));
 svg.appendChild(svgEl('line',{x1:xf(md),y1:yy-16,x2:xf(md),y2:yy+16,stroke:'#ffc93c','stroke-width':2.5}));
 function tx(x,y,s,c,fs){const t=svgEl('text',{x,y,'text-anchor':'middle',fill:c,'font-size':fs});t.textContent=s;svg.appendChild(t);}
 [['mín',mn],['Q1',q1],['Med',md],['Q3',q3],['máx',mx]].forEach(pp=>{tx(xf(pp[1]),yy-24,pp[0],'#a99fd0',10);tx(xf(pp[1]),yy+34,''+pp[1],'#eee6ff',12);});
 nodo.appendChild(svg);
};
```

- [ ] **Paso 2: Implementar `barras`**

```js
// barras: gráfico de barras cuyo eje puede empezar en `desde` (para mostrar distorsión).
// params: {datos:[{etiqueta,valor}], desde:0, top}
DIAGRAMAS.barras=function(p,nodo){
 const datos=p.datos||[{etiqueta:'A',valor:92},{etiqueta:'B',valor:95},{etiqueta:'C',valor:98}];
 const desde=p.desde||0;
 const maxV=Math.max.apply(null,datos.map(d=>d.valor));
 const top=p.top || (Math.ceil(maxV/10)*10) || (maxV+1);
 const x0=40,pt=22,pb=150,ph=pb-pt,W=320,area=W-x0-24;
 const bw=Math.min(56, area/datos.length*0.6), gap=(area-bw*datos.length)/(datos.length+1);
 const svg=svgEl('svg',{viewBox:`0 0 ${W} 176`,role:'img','aria-label':'Gráfico de barras'});
 svg.appendChild(svgEl('line',{x1:x0,y1:pb,x2:W-8,y2:pb,stroke:'#7a6ab0','stroke-width':1.5}));
 svg.appendChild(svgEl('line',{x1:x0,y1:pt,x2:x0,y2:pb,stroke:'#7a6ab0','stroke-width':1.5}));
 function tx(x,y,s,c,fs){const t=svgEl('text',{x,y,'text-anchor':'middle',fill:c,'font-size':fs});t.textContent=s;svg.appendChild(t);}
 tx(x0-14,pb,''+desde,'#a99fd0',10);
 const den=(top-desde)||1;
 datos.forEach((d,i)=>{
  const h=Math.max(2,(d.valor-desde)/den*ph), bx=x0+gap+i*(bw+gap);
  svg.appendChild(svgEl('rect',{x:bx,y:pb-h,width:bw,height:h,rx:3,fill:'#4dd8ff',stroke:'#8f6bff','stroke-width':1}));
  tx(bx+bw/2,pb-h-4,''+d.valor,'#ffc93c',12);
  tx(bx+bw/2,pb+15,d.etiqueta,'#a99fd0',11);
 });
 nodo.appendChild(svg);
};
```

- [ ] **Paso 3: Implementar `arbol`**

```js
// arbol: diagrama de árbol del principio multiplicativo (n1 × n2).
// params: {n1=2, n2=3}
DIAGRAMAS.arbol=function(p,nodo){
 const n1=Math.max(1,Math.min(4,p.n1||2)), n2=Math.max(1,Math.min(4,p.n2||3));
 const H=176, x0=26, x1=150, x2=262, cy=H/2;
 const svg=svgEl('svg',{viewBox:`0 0 320 ${H}`,role:'img','aria-label':'Diagrama de árbol'});
 const total=n1*n2, leafY=[];
 for(let k=0;k<total;k++) leafY.push(20+(H-40)*(total<=1?0.5:k/(total-1)));
 for(let i=0;i<n1;i++){
  const kids=leafY.slice(i*n2,i*n2+n2);
  const py=kids.reduce((a,b)=>a+b,0)/kids.length;
  svg.appendChild(svgEl('line',{x1:x0,y1:cy,x2:x1,y2:py,stroke:'#5a4b8f','stroke-width':1.5}));
  kids.forEach(ly=>{
   svg.appendChild(svgEl('line',{x1:x1,y1:py,x2:x2,y2:ly,stroke:'#5a4b8f','stroke-width':1.5}));
   svg.appendChild(svgEl('circle',{cx:x2,cy:ly,r:7,fill:'#4dd8ff'}));
  });
  svg.appendChild(svgEl('circle',{cx:x1,cy:py,r:10,fill:'#8f6bff'}));
 }
 svg.appendChild(svgEl('circle',{cx:x0,cy:cy,r:9,fill:'#3ee089'}));
 const t=svgEl('text',{x:244,y:16,'text-anchor':'middle',fill:'#ffc93c','font-family':"'Titan One',sans-serif",'font-size':14});
 t.textContent=`${n1} × ${n2} = ${n1*n2}`; svg.appendChild(t);
 nodo.appendChild(svg);
};
```

- [ ] **Paso 4: Verificar en el navegador**

`preview_start {name:"kimun"}`, navega a `http://localhost:8765/` (pestaña limpia). En consola:

```js
var n=document.createElement('div');document.body.appendChild(n);
montarDiagrama('cajon',{min:2,q1:5,mediana:7,q3:10,max:14},n); n.querySelector('rect')!==null;  // true (caja)
montarDiagrama('barras',{datos:[{etiqueta:'A',valor:92},{etiqueta:'B',valor:95},{etiqueta:'C',valor:98}],desde:0},n); n.querySelectorAll('rect').length===3;
montarDiagrama('barras',{datos:[{etiqueta:'A',valor:92},{etiqueta:'B',valor:95},{etiqueta:'C',valor:98}],desde:90},n); // barras muy distintas
montarDiagrama('arbol',{n1:2,n2:3},n); n.querySelectorAll('circle').length===9;  // 1 raíz + 2 nivel1 + 6 hojas
```

Confirma: `cajon` dibuja la caja (Q1–Q3), la línea de la mediana y los bigotes con etiquetas; `barras` con desde:0 muestra barras casi iguales y con desde:90 muy distintas (mismos valores 92/95/98); `arbol` con n1:2,n2:3 muestra 9 círculos y la etiqueta "2 × 3 = 6". Sin errores nuevos.

---

## Tarea 2: Contenido (3 lecciones OA15–17) y activación del capítulo

**Archivos:** Modificar `contenido/matematicas-8basico/lecciones.json` y `index.html` (entrada `'mate'`)

- [ ] **Paso 1: Agregar 3 lecciones a `lecciones.json`** (después de `ma-oa14`). Ids
  `ma-oa15`..`ma-oa17`, oa `"MA08 OA 15"`..`"MA08 OA 17"` (formato EXACTO). Contenido:

- **`ma-oa15` — "Cuartiles y diagrama de cajón":**
  - `texto`: para describir un conjunto de datos usamos medidas de posición. La mediana parte los datos ordenados en dos mitades iguales.
  - `diagrama` `cajon` `{"min":2,"q1":5,"mediana":7,"q3":10,"max":14}`, `intro`: "La caja va de Q1 a Q3 y contiene la mitad central de los datos; la línea dorada es la mediana."
  - `texto`: los cuartiles dividen los datos en cuatro partes: Q1 deja abajo un cuarto, la mediana la mitad y Q3 tres cuartos.
  - `ejemplo` `["Datos ordenados: 3, 5, 7, 9, 11","El valor del medio es la mediana","Mediana = 7"]`
  - `practica` `{"oa":"MA08 OA 15","n":3}`
- **`ma-oa16` — "¿El gráfico dice la verdad?":**
  - `texto`: un mismo conjunto de datos puede verse muy distinto según cómo se dibuje. Lo primero que hay que mirar es dónde empieza el eje.
  - `diagrama` `barras` `{"datos":[{"etiqueta":"A","valor":92},{"etiqueta":"B","valor":95},{"etiqueta":"C","valor":98}],"desde":0}`, `intro`: "Con el eje desde 0, las tres barras se parecen bastante."
  - `diagrama` `barras` `{"datos":[{"etiqueta":"A","valor":92},{"etiqueta":"B","valor":95},{"etiqueta":"C","valor":98}],"desde":90}`, `intro`: "Con el eje desde 90, ¡parecen muy distintas! Pero son los mismos datos."
  - `texto`: cuando el eje no empieza en 0, las diferencias se ven exageradas. Revisa siempre la escala antes de sacar conclusiones.
  - `practica` `{"oa":"MA08 OA 16","n":3}`
- **`ma-oa17` — "El principio multiplicativo":**
  - `texto`: si una elección tiene varias opciones y luego otra elección tiene otras opciones, el total de combinaciones se obtiene multiplicando.
  - `diagrama` `arbol` `{"n1":2,"n2":3}`, `intro`: "2 opciones y luego 3 opciones: el árbol muestra los 6 caminos posibles."
  - `texto`: el diagrama de árbol y la tabla de doble entrada ayudan a contar todas las posibilidades sin olvidar ninguna.
  - `ejemplo` `["Tienes 2 poleras y 3 pantalones","Combinaciones: 2 × 3","= 6 conjuntos distintos"]`
  - `practica` `{"oa":"MA08 OA 17","n":3}`

Revisa cada cuenta. Español neutro. Todo `fromBank.oa` exactamente `"MA08 OA 1N"`.

- [ ] **Paso 2: Activar el capítulo `mate-datos` en `index.html`** — en la entrada `'mate'`
  de `CAMPAÑAS`, capítulo `mate-datos`: quita `proximamente:true` y pon las lecciones:

```js
    {id:'mate-datos', titulo:'Probabilidad y estadística', lecciones:['ma-oa15','ma-oa16','ma-oa17']},
```

- [ ] **Paso 3: Verificar**

1. Valida JSON y OA:
```
python -c "import json;d=json.load(open('contenido/matematicas-8basico/lecciones.json',encoding='utf-8'));print(len(d['lecciones']),'lecciones');[print(l['id'],l['oa']) for l in d['lecciones']]"
python -c "import json;b=set(q['oa'] for q in json.load(open('contenido/matematicas-8basico/preguntas.json',encoding='utf-8'))['preguntas']);L=json.load(open('contenido/matematicas-8basico/lecciones.json',encoding='utf-8'))['lecciones'];[print(l['id'],'OK' if all(fb['fromBank']['oa'] in b for fb in l['bloques'] if fb['t']=='practica') else 'FALTA') for l in L]"
```
   Esperado: 17 lecciones (ma-oa01..ma-oa17), todas OK.
2. En el navegador: `localStorage.clear()`, recarga, simula las 3 primeras unidades completas:
```js
S.mateLecciones={}; for(var i=1;i<=14;i++)S.mateLecciones['ma-oa'+String(i).padStart(2,'0')]=1; guardar();
```
   JUGADOR → Matemáticas: el capítulo **Probabilidad y estadística** debe estar ABIERTO (0/3), y ya NO debe quedar ningún capítulo "🔒 Pronto". Entra: 3 lecciones. Recorre `ma-oa15` (widget `cajon`), `ma-oa16` (2 widgets `barras`) y `ma-oa17` (widget `arbol`); confirma que la práctica carga 3 preguntas del OA correcto y marca ✓.
3. read_console_messages: sin errores nuevos (benignos: "Diagrama rota", `navigator.vibrate`, 404 portadas).

---

## Tarea 3: Revisión final (Cap 4 y cierre de las 4 unidades)

- [ ] **Paso 1: Recorrido end-to-end + regresión.** Con las 3 primeras unidades completas,
  juega una lección de Estadística completa (recomendado `ma-oa16`: texto → 2 barras → texto
  → práctica → ✓). Confirma que registra dominio (OA16) y desbloquea la siguiente. Verifica
  que las 3 unidades anteriores siguen jugables, que **los 4 capítulos de Matemáticas están
  disponibles** (ninguno "🔒 Pronto"), que Historia/Ciencias/Lenguaje y el Reto no cambiaron,
  que los 2 fixes del quiz del Cap 2 siguen en pie (`.btn[hidden]{display:none}` y el guard de
  `avanzar`), y que no hay errores nuevos. Revisa las cuentas de los ejemplos OA15–17
  (mediana=7; barras mismos datos con distinto eje; 2×3=6).

---

## Auto-revisión del plan
- **Cobertura:** OA15 (cajon), OA16 (barras), OA17 (arbol) → 3 widgets (T1) + 3 lecciones
  (T2) + activación (T2 P2) + verificación/regresión (T3). Cierra las 4 unidades.
- **Sin placeholders:** código de los 3 widgets completo y prototipado; contenido de las 3
  lecciones especificado bloque por bloque con sus cuentas.
- **Consistencia:** widgets registrados en `DIAGRAMAS` como el resto; lecciones con el mismo
  esquema; capítulo activado quitando `proximamente` y poblando `lecciones`.
