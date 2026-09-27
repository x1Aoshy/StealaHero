# Hero Eggs Kit - revision 3

38 heroes y 6 jefes, organizados por las seis etapas del catalogo del juego.

La direccion artistica revisada elimina los rostros: no hay ojos, bocas, narices ni placas de cara humana. Los personajes se identifican mediante sus colores, emblemas, cabello, sombreros, armas y trajes. Las cascaras ahora usan escalones mas anchos, siguiendo la ultima referencia del usuario.

El acabado STUD es una textura real: cuadrados con un borde biselado y centro hundido, generados como mapas de color, normales tangentes y rugosidad. Los pequenos botones geometricos de la revision anterior se eliminaron. La textura se aplica mediante UV a cascaras, accesorios, sombreros y piezas de vestuario, y se incluye dentro de los FBX y del archivo Blender.

## Archivos

- `HeroEggsKit.blend`: biblioteca editable con seis Collections por etapa. Cada huevo es una malla con materiales texturizados y un modificador de bisel editable. Las imagenes estan empaquetadas dentro del archivo.
- `fbx/<HeroId>_Egg.fbx`: 44 archivos independientes; sus IDs coinciden con `HeroCatalog.luau`. Cada archivo contiene solo la malla del huevo y sus accesorios, con el bisel aplicado.
- `previews/`: 44 renders transparentes, seis laminas por etapa, una vista general y una lamina de detalle de los piratas.
- `manifest.json`: inventario, etapa, rareza, escala, cantidad de triangulos, studs y materiales luminosos por modelo.
- `validation.json`: resultados de reimportar los 44 FBX en Blender.
- `texture_validation.json`: auditoria independiente de UV, conexiones de color/normal y medios incrustados en los 44 FBX.
- `textures/`: PNGs de color por material, `Stud_Normal.png`, `Stud_Height.png`, `Stud_Roughness.png` y una muestra visual del acabado.
- `RobloxMaterialGuide.json`: colores y equivalentes SmoothPlastic / Neon.
- `../../audit/generate_voxel_eggs_bpy.py`: generador completo y reproducible.
- `../../audit/generate_stud_textures.py`: generador de las texturas repetibles.
- `../../audit/verify_egg_textures_bpy.py`: prueba independiente de la exportacion texturizada.

## Escala y orientacion

Un Blender unit representa un stud. La altura total, incluyendo sombreros, cabello y armas, es 3.2 studs para heroes. Los jefes usan la escala especificada: Thanos 1.6, Darkseid 1.5, Carnage 1.2, Shigaraki 1.1, Frieza 1.0 y Kaido 1.9. El ancho varia por accesorios.

El origen de cada exportacion esta centrado horizontalmente en el eje del huevo y al nivel del suelo. En Blender el frente es -Y y arriba es +Z. El FBX se exporta con -Z forward / Y up. En la biblioteca los modelos estan separados en filas para facilitar la edicion; esa separacion no existe en los FBX individuales.

Todos los FBX se escriben primero en `C:/Users/Public/HeroEggs/fbx/` y luego se copian a esta carpeta. Existe otra copia de la biblioteca, los previews, el generador y los informes en `C:/Users/Public/HeroEggs/`.

## Validacion

Los conteos de triangulos exactos de cada modelo estan en `manifest.json`. Los 44 FBX se reimportaron correctamente: una malla por archivo, coordenadas finitas, metadatos ASCII y altura dentro de 0.015 studs del objetivo. La auditoria adicional verifica que todos los materiales recuperan sus mapas de color y normales, que las UV son finitas y que los FBX contienen las imagenes incrustadas. El render de control de Luffy se genero a partir del FBX reimportado.

La validacion se realizo en Blender 4.5.3; la importacion dentro de Roblox Studio queda pendiente. La guia identifica los mapas de color, normales y rugosidad por material, ademas de las piezas luminosas `HE_glow*` / `HE_gem*`. La emision de Blender no se convierte automaticamente en la propiedad Neon de Roblox.

## Regenerar

Desde PowerShell, en la carpeta del proyecto:

```powershell
python 'audit/generate_stud_textures.py'
& 'C:/Program Files/Blender Foundation/Blender 4.5/blender.exe' -b --factory-startup --python 'audit/generate_voxel_eggs_bpy.py'
python 'audit/compose_egg_previews.py'
& 'C:/Program Files/Blender Foundation/Blender 4.5/blender.exe' -b --factory-startup --python 'audit/verify_egg_textures_bpy.py'
```

La generacion completa reemplaza los archivos generados de esta biblioteca. El script exige ejecutarse en un proceso de Blender en segundo plano para proteger cualquier escena de trabajo abierta. Para una prueba parcial se puede agregar `-- --only Luffy,Zoro`; se regeneran esos FBX, una biblioteca de prueba e informes con prefijo `preview_`.

Inosuke, Zenitsu y Nezuko se usaron solo como referencias visuales del brief; no forman parte del catalogo solicitado de 44 modelos.
