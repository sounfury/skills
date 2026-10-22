#!/usr/bin/env python3
"""
Simple converter for standalone PlantUML files to PNG or SVG.

Usage:
    python convert_puml.py <file.puml> [--format png|svg] [--output-dir out/]
"""

import sys
import subprocess
import os
import shutil
from pathlib import Path

from runtime_utils import (
    build_subprocess_env,
    find_plantuml_jar as find_runtime_plantuml_jar,
)


def find_plantuml_command() -> tuple:
    """
    Find PlantUML executable - checks for command first, then JAR.

    Returns:
        Tuple of (command_list, method) where method is 'command' or 'jar'
    """
    # First, check for plantuml command in PATH (works with any package manager)
    # Homebrew (macOS), Chocolatey (Windows), apt/yum (Linux), etc.
    plantuml_cmd = shutil.which('plantuml')
    if plantuml_cmd:
        return ([plantuml_cmd], 'command')

    # Common fallback locations if not in PATH
    common_paths = [
        '/opt/homebrew/bin/plantuml',  # macOS Apple Silicon
        '/usr/local/bin/plantuml',      # macOS Intel / Linux
        '/usr/bin/plantuml',            # Linux system install
    ]
    for path in common_paths:
        if os.path.exists(path) and os.access(path, os.X_OK):
            return ([path], 'command')

    # Fall back to JAR file
    jar_path = find_plantuml_jar()
    if jar_path:
        return (['java', '-jar', jar_path], 'jar')

    return (None, None)


def find_plantuml_jar() -> str:
    """Search for plantuml.jar in environment, bundled runtime, or common locations."""
    return find_runtime_plantuml_jar()


def convert_puml(puml_file: str, format: str = 'png', output_dir: str = None) -> bool:
    """
    Convert a .puml file to image format.

    Args:
        puml_file: Path to .puml file
        format: 'png' or 'svg'
        output_dir: Optional output directory

    Returns:
        True if successful, False otherwise
    """
    cmd_base, method = find_plantuml_command()
    if not cmd_base:
        print("ERROR: PlantUML not found.")
        print("Install via Homebrew: brew install plantuml")
        print("Or download JAR from: https://plantuml.com/download")
        print("Or set PLANTUML_JAR environment variable.")
        return False

    format_flag = '-tsvg' if format == 'svg' else '-tpng'
    cmd = cmd_base + [format_flag]

    if output_dir:
        # Use absolute path - PlantUML's -o flag is relative to input file location
        abs_output_dir = str(Path(output_dir).resolve())
        Path(abs_output_dir).mkdir(exist_ok=True, parents=True)
        cmd.extend(['-o', abs_output_dir])

    cmd.append(puml_file)

    print(f"Converting {puml_file} to {format.upper()}...")
    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        env=build_subprocess_env()
    )

    if result.returncode != 0:
        print(f"ERROR: {result.stderr}")
        return False

    output_name = Path(puml_file).stem + f".{format}"
    if output_dir:
        output_path = Path(output_dir).resolve() / output_name
    else:
        output_path = Path(puml_file).parent / output_name

    print(f"[OK] Created: {output_path}")
    return True

def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print("Usage: python convert_puml.py <file.puml> [--format png|svg] [--output-dir out/]")
        sys.exit(1)

    puml_file = sys.argv[1]
    format = 'png'
    output_dir = None

    # Parse optional arguments
    i = 2
    while i < len(sys.argv):
        if sys.argv[i] == '--format' and i + 1 < len(sys.argv):
            format = sys.argv[i + 1]
            i += 2
        elif sys.argv[i] == '--output-dir' and i + 1 < len(sys.argv):
            output_dir = sys.argv[i + 1]
            i += 2
        else:
            i += 1

    if not os.path.exists(puml_file):
        print(f"ERROR: File not found: {puml_file}")
        sys.exit(1)

    if format not in ['png', 'svg']:
        print(f"ERROR: Invalid format '{format}'. Use 'png' or 'svg'")
        sys.exit(1)

    success = convert_puml(puml_file, format, output_dir)
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
