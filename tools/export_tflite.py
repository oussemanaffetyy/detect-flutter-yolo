#!/usr/bin/env python3
"""Export a YOLO .pt model to TFLite and copy it into Flutter Android assets."""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path

from ultralytics import YOLO


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Export a YOLO .pt model to a .tflite file for Flutter."
    )
    parser.add_argument("--weights", required=True, help="Path to .pt weights file.")
    parser.add_argument(
        "--output-dir",
        default="android/app/src/main/assets",
        help="Directory where the exported .tflite will be copied.",
    )
    parser.add_argument(
        "--output-name",
        default="best.tflite",
        help="Output .tflite filename in output-dir.",
    )
    parser.add_argument(
        "--imgsz", type=int, default=640, help="Image size used during export."
    )
    parser.add_argument(
        "--int8",
        action="store_true",
        help="Export an INT8 quantized model (optional).",
    )
    return parser.parse_args()


def ensure_path(value: str | Path) -> Path:
    return Path(value).expanduser().resolve()


def main() -> None:
    args = parse_args()
    weights_path = ensure_path(args.weights)
    if not weights_path.exists():
        raise FileNotFoundError(f"Weights not found: {weights_path}")

    model = YOLO(str(weights_path))
    exported = model.export(format="tflite", imgsz=args.imgsz, int8=args.int8)

    if isinstance(exported, (list, tuple)):
        if not exported:
            raise RuntimeError("No export artifact returned by ultralytics.")
        exported = exported[0]

    exported_path = ensure_path(exported)
    if not exported_path.exists():
        raise FileNotFoundError(f"Exported artifact not found: {exported_path}")

    output_dir = ensure_path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / args.output_name
    shutil.copy2(exported_path, output_path)

    print(f"Exported: {exported_path}")
    print(f"Copied to: {output_path}")


if __name__ == "__main__":
    main()
