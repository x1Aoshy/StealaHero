# Stark Lab — arquitectura sobria, 25 septiembre 2026

Rediseño según las dos imágenes del usuario. Se eliminaron las cabezas de Iron Man, gemas, remates dorados, circuitos en el suelo y símbolos repetidos. La paleta utiliza grafito, azul oscuro y plata; la Torre Avengers ocupa un lateral del acceso, con su espina vertical, soporte curvo, terraza y volumen superior en voladizo. El emblema es geometría 3D. A petición del usuario el acceso queda abierto (sin marquesina).

El vidrio son paneles de `Glass` (transparencia 0.28) colocados sobre un respaldo opaco: las juntas entre paneles forman los marcos. Los bordes importantes tienen biseles y normales ponderadas; los pequeños perfiles no añaden subdivisión innecesaria.

## Pasada de pulido (25 septiembre 2026, después de Astra)

Se mantuvo el diseño aprobado y se corrigió todo lo que no estaba en su sitio, revisando render por render (vistas generales, entrada, cámara a la altura del jugador fuera y dentro del corral, primeros planos):

- **Soporte curvo de la torre**: antes eran vigas sueltas con quiebres, empezaba a media altura y la de atrás flotaba 0.0075. Ahora es una sola banda de acero continua y suavizada que envuelve el borde curvo desde el zócalo hasta la terraza; el cristal y el volumen siguen la misma curva.
- **Corona**: la espina sube recta hasta la esquina superior (antes quedaba una rendija junto al borde inclinado).
- **Emblema A**: flotaba 0.09 delante del cristal. Ahora es un relieve escalonado (anillo 0.10, A 0.17, biselados) apoyado en la cara del volumen. Las dos barras bajo el logo están asentadas en la fachada.
- **Volumen superior**: su cara hacia el corral quedaba a 0.01 de la torre (z-fighting). Ahora sobresale con claridad.
- **Poste izquierdo del acceso**: sin marquesina quedaba como un pilar suelto. Ahora tiene el mismo zócalo y el mismo módulo de vidrio que la torre.
- **Terminal de mejoras**: la barandilla atravesaba la parte trasera del quiosco y los montantes de acero flotaban 0.26 y no llegaban al bisel. Ahora la barandilla termina oculta dentro del muro trasero, los montantes apoyan en el suelo y enmarcan el bisel neón al ras, y el techo cubre todo el quiosco. La pantalla funcional del letrero sigue totalmente visible. La cara hacia el corral lleva el mismo módulo de vidrio que la torre.
- **Esquinas**: las ranuras de luz quedaban ocultas tras el cristal de la barandilla. Ahora hay una en cada cara interior, por encima de la albardilla.
- **Suelo**: la A central flotaba 0.01 sobre el sello y la flecha compartía el plano superior con la A. Ahora la A está apoyada y la flecha queda un escalón por debajo. El tapete de entrada baja hasta el suelo fuera del corral (antes flotaba 0.1).
- La cuadrícula del suelo (10.5) coincide con los postes en las dos variantes.

| Variante | Triángulos | MeshParts | Luces |
|---|---:|---:|---:|
| Std | 7,322 | 8 | 1 |
| Deep | 7,456 | 8 | 1 |

`StarkLab.blend` contiene las dos variantes editables. `StarkLab.fbx` contiene ambas listas para Import 3D. El acceso, la pantalla de mejoras y el suelo jugable conservan sus espacios. Las imágenes en `preview/` son renders del modelo real: `hero`, `gate`, `detail` y `top` (run.py), y además `gate_joint` (el acceso a la altura del jugador), `player_out`, `player_in`, `emblem` y `terminal`. Respaldos: `backup-before-polish-20260925/` (estado final de Astra antes de esta pasada) y los anteriores `backup-*`.

Para integrarlo: importa el FBX en Studio conservando nombres y piezas, selecciona el modelo y ejecuta `assets/models/bases/BaseThemesImport.lua` en la barra de comandos. Guarda el modelo resultante de `ServerStorage.BaseThemeImports.Forest` como `assets/models/bases/Forest/StarkLab.rbxm`, luego ejecuta `lune run scripts/build_stealahero.luau` y prueba Play con la base Forest equipada. No combines las piezas ni elimines los prefijos Std/Deep antes del helper.

Validación: contrato del corral, obstáculos de las seis parcelas sin margen (`plot_obstacles.json`, el escenario actual y un build nuevo), presupuesto de triángulos, retorno FBX, normales, triángulos degenerados y dos comprobaciones de montaje: ninguna pieza flota y ninguna pareja de piezas comparte una cara coplanar (z-fighting). La prueba de importación sintética coloca el corral en las seis parcelas (Std en 1, 4, 5; Deep en 2, 3, 6) con error 0.0001 y 0 problemas. No se ha ejecutado Studio Play ni publicado meshes: todavía se requiere la importación real. El archivo principal del juego no se reemplazó.

Regenerar: `blender --background --factory-startup --python scripts/tools/blender/base_themes/run.py -- --themes Forest`. Validar geometría: `blender --background --factory-startup --python-exit-code 1 --python scripts/tools/blender/base_themes/verify_forest.py [-- --obstacles <otro plot_obstacles.json>]`. Validar importación: `lune run scripts/tools/test_base_imports.luau all <carpeta temporal> Forest`.

## Sin neón (25 septiembre 2026, petición del dueño)

"Elimina todo el neón de las bases, es muy disruptivo para las personas que juegan": los papeles `Neon_Emissive_*` conservan su nombre (tu importación de Studio los lleva así) pero ahora son SmoothPlastic sin brillo, con el mismo tono un poco más profundo y algo de reflectancia. Las luces (PointLight) también se eliminaron. **La geometría no cambió**: huella de geometría `g1:ca6a3f785e7fdcafc7ba0fd0` idéntica a la de tu importación de las 06:35, así que **no hay que volver a importar** el FBX: el build aplica la nueva paleta a tu `.rbxm`. Comprobado: mismas posiciones, polígonos y normales personalizadas en el FBX; mismas piezas, límites y triángulos en el JSON.

| Papel | Antes (Neon) | Ahora |
|---|---|---|
| `Neon_Emissive_Architectural` | (153, 191, 211) | SmoothPlastic (132, 184, 214), reflectancia 0.06 |
| `Neon_Emissive_Screen` | (116, 180, 208) | SmoothPlastic (96, 166, 204), reflectancia 0.06 |

Luces: 0 (antes 1 por variante).
