# Sunny Pirate Wharf — actualizado 25 septiembre 2026 (barco rehecho)

El Thousand Sunny de la puerta se rehízo siguiendo la imagen de referencia del owner (`reference/ThousandSunny-concept.png`, la misma que `images/11.webp`). Comparación lado a lado: `preview/SunnyPirateWharf_vs_reference.png`; primer plano: `preview/SunnyPirateWharf_sunny.png`; viento: `preview/SunnyPirateWharf_wind.mp4`.

- **Barco** (`scripts/tools/blender/base_themes/themes/sunny_ship.py`): casco redondo de tablas solapadas (clinker, líneas de tabla reales), baluarte rojo, marco crema en U alrededor de la cubierta de césped con volutas enrolladas en ambos extremos, ojos de buey negros con aro dorado, escudo rojo de proa con aro crema y remaches dorados, león-sol esculpido (melena de 12 pétalos naranjas, cara amarilla redonda, hocico crema, nariz, ojos y sonrisa) con dos huesos cruzados detrás, girado 40° hacia la calle para que se lea desde fuera de la parcela. Vela mayor crema que se hincha, con la Jolly Roger del Sombrero de Paja en relieve 3D por las dos caras (calavera, huesos, sombrero con cinta roja, contornos negros); vela de popa a rayas rojo/blanco, cofa a rayas, dos banderas negras, cabina de popa con cúpula de gajos rojos/amarillos y ventanas, barandillas blancas, árbol redondo, farol, escalas de cuerda (lado de la parcela) y estays.
- **Muelle** (`themes/volcano.py`, `gate_lintel`): viga y tres tablones sobre los dos pilotes, dos cunas que siguen la forma del casco, postes con amarres de cáñamo y cuerdas colgantes en los extremos. El barco es más grande que antes (≈13.5 studs de largo, hasta h 15.9) y sigue dentro del contrato de la parcela (franja frontal u D-0.62..D+2.4, paso de la puerta libre por debajo de h 7.5).
- **Triángulos**: Std 8,809; Deep 8,965 (límite 9,000). Cada variante exporta 35 MeshParts; 21 son el barco animado (grupos `Hull`, `Main`, `Aft`, `Flag` en el nombre `_Sunny<Grupo>_`). Para pagar el barco se aligeró el resto de la base: sin remaches en la barandilla, bolardos y pilotes con menos lados (sombreado suave), 17 columnas de tablones con menos juntas, menos clavos, brújula a 20 lados sin marcas, rueda de timón con 8 radios, soporte de farol inclinado.
- **Viento**: `SunnyWind.Pivots` se movió a los nuevos ejes (vela mayor en su verga `(-0.35, 6.5, 0)`, vela de popa `(3.95, 6.05, 0.05)`, bandera en el palo mayor `(-0.35, 7.35, 0)`); el origen `SunnyOrigin` sigue en (0, D+0.88, 8.30), como lo fija `post_zz_base_themes.luau`. Mismo controlador, mismos límites de 30/15 Hz y distancia.

## Importar en el juego

1. En Roblox Studio importa `SunnyPirateWharf.fbx` con Import 3D. Conserva las piezas independientes y sus nombres `Std_*` / `Deep_*`.
2. Selecciona el modelo importado y ejecuta `assets/models/bases/BaseThemesImport.lua` en la barra de comandos; guarda el resultado como `assets/models/bases/Volcano/SunnyPirateWharf.rbxm`.
3. `lune run scripts/build_stealahero.luau`: el importador coloca cada variante, crea `SunnyOrigin`, las etiquetas y atributos de viento.
4. Prueba Play en Studio (móvil y PC). No se ha importado ni probado en Studio: no había conexión disponible.

## Verificación (offline)

`run.py` sin problemas de contrato ni de obstáculos en las 6 parcelas; retorno FBX a Blender con normales personalizadas y cero triángulos degenerados (`reference/fbx-validation.json`); `verify_sunny.luau` (95,918 comprobaciones de límites animados contra el stage actual y los 6 rigs de la importación sintética); `test_sunny_controller.luau`; `test_base_imports.luau all <dir> Volcano` (6/6 parcelas, error 0.0001).

Regenerar: `blender --background --factory-startup --python scripts/tools/blender/base_themes/run.py -- --themes Volcano`, luego `lune run scripts/tools/verify_sunny.luau` y `blender --background --factory-startup --python scripts/tools/blender/base_themes/finish_volcano.py -- --video`.

Respaldo de antes de Astra: `backup-before-sunny-20260925/`.

## Sin neón (25 septiembre 2026, petición del dueño)

"Elimina todo el neón de las bases, es muy disruptivo para las personas que juegan": los papeles `Neon_Emissive_*` conservan su nombre (tu importación de Studio los lleva así) pero ahora son SmoothPlastic sin brillo, con el mismo tono un poco más profundo y algo de reflectancia. Las luces (PointLight) también se eliminaron. **La geometría no cambió**: huella de geometría `g1:37754577e17381b3a4036532` idéntica a la de tu importación de las 06:35, así que **no hay que volver a importar** el FBX: el build aplica la nueva paleta a tu `.rbxm`. Comprobado: mismas posiciones, polígonos y normales personalizadas en el FBX; mismas piezas, límites y triángulos en el JSON.

| Papel | Antes (Neon) | Ahora |
|---|---|---|
| `Neon_Emissive_Lantern` | (255, 170, 60) | SmoothPlastic (250, 164, 52), reflectancia 0.08 |
| `Neon_Emissive_Screen` | (255, 170, 60) | SmoothPlastic (250, 164, 52), reflectancia 0.08 |

Luces: 0 (antes 5 por variante). Las acciones de viento del `.blend` y `preview/SunnyPirateWharf_sunny.png` / `_wind.mp4` se regeneraron con `finish_volcano.py`; el viento del Sunny en el juego no cambia (`verify_sunny.luau` OK).
