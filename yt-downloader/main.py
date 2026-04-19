#!/usr/bin/env python3
"""Reproduce el audio de un video de YouTube desde la terminal (macOS)."""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

from yt_dlp import YoutubeDL

CACHE_DIR = Path.home() / ".cache" / "ytmusic-cli"


def find_cached_audio(video_id: str) -> Path | None:
    matches = sorted(CACHE_DIR.glob(f"{video_id}.*"))
    if not matches:
        return None
    return matches[0]

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Descarga y reproduce el audio de un link de YouTube.",
    )
    parser.add_argument("url", help="URL del video de YouTube")
    return parser.parse_args()


def ensure_supported_player() -> None:
    if shutil.which("afplay"):
        return
    print("No se encontro 'afplay'. Este script requiere macOS.", file=sys.stderr)
    sys.exit(1)


def download_audio(url: str) -> Path:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    ydl_opts = {
        "format": "bestaudio[ext=m4a]/bestaudio[acodec^=mp4a]/bestaudio",
        "noplaylist": True,
        "outtmpl": str(CACHE_DIR / "%(id)s.%(ext)s"),
        "quiet": True,
        "no_warnings": True,
    }

    with YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(url, download=False)
        video_id = info.get("id")

        if video_id:
            cached_audio = find_cached_audio(video_id)
            if cached_audio:
                print(f"Usando cache: {cached_audio.name}")
                return cached_audio

        info = ydl.extract_info(url, download=True)
        output_path = Path(ydl.prepare_filename(info))

    if not output_path.exists():
        raise FileNotFoundError(f"No se encontro el archivo descargado: {output_path}")

    return output_path


def play_audio(file_path: Path) -> int:
    print(f"Reproduciendo: {file_path.name}")
    return subprocess.run(["afplay", str(file_path)]).returncode


def main() -> int:
    args = parse_args()
    ensure_supported_player()

    try:
        audio_path = download_audio(args.url)
    except Exception as exc:
        print(f"Error al descargar audio: {exc}", file=sys.stderr)
        return 1

    return play_audio(audio_path)


if __name__ == "__main__":
    raise SystemExit(main())
