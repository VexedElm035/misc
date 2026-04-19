# ytmusic-cli

CLI simple en Python para reproducir el audio de un video de YouTube en macOS.

## Requisitos

- macOS (usa `afplay`)
- conda instalado

## Crear entorno conda

```bash
conda env create -f environment.yml
conda activate ytmusic-cli
```

Si ya existe el entorno:

```bash
conda env update -f environment.yml --prune
conda activate ytmusic-cli
```

## Ejecutar

```bash
python main.py "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
```

Al ejecutar, el script descarga el mejor audio disponible y empieza a reproducirlo.

## Soporte para playlists (diseno recomendado)

Para agregar playlists, la opcion mas simple y robusta es una orquestacion secuencial, no recursividad.

Flujo sugerido:

1. Obtener los videos de la playlist.
2. Iterar uno por uno.
3. Pasar cada URL al flujo actual de reproduccion.

Puedes hacerlo en el mismo script con una bandera (por ejemplo `--playlist`) o con un script orquestador separado.

Buenas practicas:

- Manejar errores por item y continuar con el siguiente video.
- Evitar duplicados por ID.
- Agregar un pequeno delay entre requests si son muchas reproducciones seguidas.
- Reusar cache por ID para no redescargar audio existente.
- Guardar progreso (indice actual) para poder reanudar.
