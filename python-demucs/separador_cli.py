import argparse
import gc
import hashlib
import json
from pathlib import Path
import time
from datetime import datetime, timezone
from uuid import uuid4


import torch  # pyright: ignore[reportMissingImports]
import soundfile as sf  # pyright: ignore[reportMissingImports]

# Reduce buffers internos por paralelismo en CPU.
torch.set_num_threads(1)

try:
    from demucs.apply import apply_model  # pyright: ignore[reportMissingImports]
    from demucs.pretrained import get_model  # pyright: ignore[reportMissingImports]
    from demucs.separate import load_track, save_audio  # pyright: ignore[reportMissingImports]
except ModuleNotFoundError as exc:
    if exc.name in {"demucs", "demucs.apply", "demucs.pretrained", "demucs.separate"}:
        raise SystemExit(
            "No se pudo importar Demucs. Instala dependencias con pip install -r requirements.txt "
            "y usa Python 3.10/3.11 (Demucs 4 no soporta Python 3.12+)."
        )
    raise

TIER_LABELS = {
    1: "performance",
    2: "balanceado",
    3: "calidad",
    4: "balanced_ft",
    5: "6stems",
}

PRESETS = {
    1: {
        "label": "performance",
        "model": "hdemucs_mmi",
        "segment": 2.0,
        "overlap": 0.05,
        "shifts": 0,
    },
    2: {
        "label": "balanceado",
        "model": "htdemucs",
        "segment": None,
        "overlap": 0.1,
        "shifts": 1,
    },
    3: {
        "label": "calidad",
        "model": "mdx_extra",
        "segment": 8.0,
        "overlap": 0.25,
        "shifts": 1,
    },
    4: {
        "label": "balanced_ft",
        "model": "htdemucs_ft",
        "segment": None,
        "overlap": 0.1,
        "shifts": 1,
    },
    5: {
        "label": "6stems",
        "model": "htdemucs_6s",
        "segment": None,
        "overlap": 0.1,
        "shifts": 1,
    },
}


def sha256_file(path: Path, chunk_size: int = 1024 * 1024) -> str:
    hasher = hashlib.sha256()
    with path.open("rb") as f:
        while True:
            chunk = f.read(chunk_size)
            if not chunk:
                break
            hasher.update(chunk)
    return hasher.hexdigest()


def cargar_modelo(modelo_numero: int):
    nombre_modelo = PRESETS[modelo_numero]["model"]
    try:
        return get_model(nombre_modelo), nombre_modelo
    except Exception as exc:
        mensaje = str(exc)
        if "DiffQ" in mensaje or "diffq" in mensaje:
            mensaje += " | Instala diffq: pip install diffq"
        raise RuntimeError(f"No se pudo cargar el modelo '{nombre_modelo}': {mensaje}")


def separar_audio(
    ruta_entrada: str,
    directorio_salida: str,
    modelo_numero: int,
    debug: bool = False,
    segment_seconds: float | None = None,
    force_cpu: bool = False,
    output_format: str = "mp3",
    mp3_bitrate: int = 320,
) -> None:
    
    tiempo_inicio_total = time.perf_counter()

    archivo_entrada = Path(ruta_entrada)
    if not archivo_entrada.exists():
        print(f"Error: no se encontro el archivo '{ruta_entrada}'")
        return

    if not archivo_entrada.is_file():
        print(f"Error: la ruta de entrada no es un archivo: '{ruta_entrada}'")
        return

    nombre_modelo = PRESETS[modelo_numero]["model"]
    print(f"Cargando tier {modelo_numero} ({TIER_LABELS[modelo_numero]}) (modelo: {nombre_modelo})...")

    try:
        model, nombre_modelo = cargar_modelo(modelo_numero)
    except Exception as exc:
        print(f"Error al cargar el modelo para la opcion {modelo_numero}: {exc}")
        print("Tip: verifica tu version de demucs y los pesos del modelo.")
        return

    print(f"Modelo cargado: {nombre_modelo} | tier: {TIER_LABELS[modelo_numero]}")

    if torch.backends.mps.is_available() and nombre_modelo == "mdx_extra_q":
        print(
            "Aviso: en MPS (Apple Silicon), mdx_extra_q no siempre reduce RAM/tiempo frente a htdemucs."
        )

    if force_cpu:
        device = "cpu"
    elif torch.backends.mps.is_available():
        device = "mps"
    elif torch.cuda.is_available():
        device = "cuda"
    else:
        device = "cpu"

    model.to(device)
    model.eval()

    print(f"Separando stems de: {archivo_entrada.name}...")
    mezcla = load_track(str(archivo_entrada), model.audio_channels, model.samplerate)
    mezcla = mezcla.to(device)

    duracion_audio_s = mezcla.shape[-1] / float(model.samplerate)
    tiempo_inicio_sep = time.perf_counter()

    preset = PRESETS[modelo_numero]
    effective_segment_seconds = preset["segment"] if segment_seconds is None else segment_seconds
    effective_overlap = float(preset["overlap"])
    effective_shifts = int(preset["shifts"])

    with torch.no_grad():
        estimados = apply_model(
            model,
            mezcla.unsqueeze(0),
            device=device,
            progress=True,
            num_workers=0,
            segment=effective_segment_seconds,
            overlap=effective_overlap,
            shifts=effective_shifts,
        )[0]

    tiempo_sep_s = time.perf_counter() - tiempo_inicio_sep

    ruta_base_salida = Path(directorio_salida)
    ruta_base_salida.mkdir(parents=True, exist_ok=True)

    separation_id = uuid4().hex
    timestamp_utc = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    run_folder_name = f"{archivo_entrada.stem}_{timestamp_utc}_{separation_id[:8]}"
    ruta_salida = ruta_base_salida / run_folder_name
    ruta_salida.mkdir(parents=True, exist_ok=False)

    sample_rate = model.samplerate

    stems_manifest = {}

    for idx, nombre_stem in enumerate(model.sources):
        tensor_stem = estimados[idx]
        extension = "wav" if output_format == "wav" else "mp3"
        archivo_salida = ruta_salida / f"{separation_id}_{nombre_stem}.{extension}"
        print(f"Guardando {nombre_stem} -> {archivo_salida}")

        tensor_cpu = tensor_stem.detach().cpu()
        if output_format == "wav":
            audio = tensor_cpu.transpose(0, 1).numpy()
            sf.write(str(archivo_salida), audio, sample_rate)
        else:
            save_audio(
                tensor_cpu,
                str(archivo_salida),
                int(sample_rate),
                bitrate=int(mp3_bitrate),
            )
            audio = tensor_cpu.transpose(0, 1).numpy()

        channels = int(audio.shape[1]) if audio.ndim == 2 else 1
        duration_sec = float(audio.shape[0]) / float(sample_rate)
        stems_manifest[nombre_stem] = {
            "path": archivo_salida.name,
            "sha256": sha256_file(archivo_salida),
            "size_bytes": archivo_salida.stat().st_size,
            "duration_sec": round(duration_sec, 6),
            "sample_rate": int(sample_rate),
            "channels": channels,
        }

        del audio
        del tensor_cpu
        del tensor_stem

    del estimados
    del mezcla
    gc.collect()

    input_sha256 = sha256_file(archivo_entrada)
    manifest_data = {
        "version": 1,
        "separation_id": separation_id,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "tier": TIER_LABELS[modelo_numero],
        "model": nombre_modelo,
        "device": device,
        "stem_count": len(stems_manifest),
        "sources": list(model.sources),
        "settings": {
            "segment": effective_segment_seconds,
            "overlap": effective_overlap,
            "shifts": effective_shifts,
            "force_cpu": force_cpu,
            "output_format": output_format,
            "mp3_bitrate": int(mp3_bitrate),
        },
        "input": {
            "filename": archivo_entrada.name,
            "sha256": input_sha256,
            "size_bytes": archivo_entrada.stat().st_size,
            "duration_sec": round(duracion_audio_s, 6),
            "sample_rate": int(sample_rate),
            "audio_channels": int(model.audio_channels),
        },
        "stems": stems_manifest,
    }

    manifest_path = ruta_salida / "manifest.json"
    manifest_tmp_path = ruta_salida / "manifest.tmp"
    with manifest_tmp_path.open("w", encoding="utf-8") as f:
        json.dump(manifest_data, f, ensure_ascii=True, indent=2)
    manifest_tmp_path.replace(manifest_path)

    print("Separacion completada con exito.")
    print(f"Manifest generado: {manifest_path}")

    if debug:
        tiempo_total_s = time.perf_counter() - tiempo_inicio_total
        rtf = tiempo_sep_s / duracion_audio_s if duracion_audio_s > 0 else float("inf")

        print("\n=== Debug de Separacion ===")
        print(f"Tier: {TIER_LABELS[modelo_numero]}")
        print(f"Modelo: {nombre_modelo}")
        print(f"Cantidad de stems: {len(model.sources)}")
        if hasattr(model, "models"):
            print(f"Submodelos (bag): {len(list(model.models))}")
        else:
            print("Submodelos (bag): 1")
        print(f"Dispositivo: {device}")
        print(f"Duracion del audio: {duracion_audio_s:.2f} s")
        print(f"Tiempo de separacion (solo inferencia): {tiempo_sep_s:.2f} s")
        print(f"Tiempo total (carga + inferencia + guardado): {tiempo_total_s:.2f} s")
        print(f"Factor tiempo real (RTF): {rtf:.3f}x")
        print(f"Segment usado en inferencia: {effective_segment_seconds if effective_segment_seconds is not None else 'auto/modelo'}")
        print(f"Overlap usado en inferencia: {effective_overlap}")
        print(f"Shifts usados en inferencia: {effective_shifts}")
        print(f"Formato de salida: {output_format}")
        if output_format == "mp3":
            print(f"MP3 bitrate: {mp3_bitrate} kbps")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="CLI para separar stems con Demucs eligiendo modelo por numero."
    )
    parser.add_argument("input", type=str, help="Ruta del audio de entrada (ej. cancion.mp3)")
    parser.add_argument(
        "-m",
        "--model",
        type=int,
        choices=[1, 2, 3, 4, 5],
        default=2,
        help=(
            "Tier Demucs: 1=performance (hdemucs_mmi), "
            "2=balanceado (htdemucs), "
            "3=calidad (mdx_extra_q), "
            "4=balanced_ft (htdemucs_ft), "
            "5=6stems (htdemucs_6s)."
        ),
    )
    parser.add_argument(
        "-o",
        "--output",
        type=str,
        default="./stems",
        help="Directorio de salida (por defecto: ./stems)",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Muestra metricas de rendimiento al final (tiempos de separacion).",
    )
    parser.add_argument(
        "--segment",
        type=float,
        default=None,
        help="Override del segment (segundos) del preset. Menor = menos RAM, mas lento.",
    )
    parser.add_argument(
        "--cpu",
        action="store_true",
        help="Fuerza ejecucion en CPU (en Mac puede reducir peak memory footprint).",
    )

    format_group = parser.add_mutually_exclusive_group()
    format_group.add_argument(
        "--mp3",
        dest="output_format",
        action="store_const",
        const="mp3",
        help="Guarda stems en formato MP3 (default).",
    )
    format_group.add_argument(
        "--wav",
        dest="output_format",
        action="store_const",
        const="wav",
        help="Guarda stems en formato WAV.",
    )
    parser.set_defaults(output_format="mp3")
    parser.add_argument(
        "--mp3-bitrate",
        type=int,
        default=320,
        help="Bitrate MP3 en kbps cuando el formato es mp3 (por defecto: 320).",
    )

    args = parser.parse_args()
    separar_audio(
        args.input,
        args.output,
        args.model,
        debug=args.debug,
        segment_seconds=args.segment,
        force_cpu=args.cpu,
        output_format=args.output_format,
        mp3_bitrate=args.mp3_bitrate,
    )
