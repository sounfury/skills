#!/usr/bin/env python3
"""
Check PlantUML setup: Java, Graphviz, and plantuml.jar availability.

Usage:
    python check_setup.py
"""

import subprocess
import os
import sys
from pathlib import Path

from runtime_utils import build_subprocess_env, find_graphviz_dot, find_plantuml_jar

def check_java() -> bool:
    """Check if Java is installed and accessible."""
    try:
        result = subprocess.run(
            ['java', '-version'],
            capture_output=True,
            text=True,
            env=build_subprocess_env()
        )
        version_output = result.stderr  # Java outputs version to stderr
        print(f"[OK] Java found: {version_output.splitlines()[0]}")
        return True
    except FileNotFoundError:
        print("[ERROR] Java not found. Install from https://www.oracle.com/java/technologies/downloads/")
        return False

def check_graphviz() -> bool:
    """Check if Graphviz is installed and accessible."""
    dot_path = find_graphviz_dot()
    if not dot_path:
        print("[ERROR] Graphviz not found. Install from https://graphviz.org/download/")
        return False

    try:
        result = subprocess.run(
            [dot_path, '-V'],
            capture_output=True,
            text=True,
            env=build_subprocess_env()
        )
        version_output = result.stderr  # dot outputs version to stderr
        print(f"[OK] Graphviz found: {version_output.strip()}")
        return True
    except FileNotFoundError:
        print("[ERROR] Graphviz not found. Install from https://graphviz.org/download/")
        return False

def check_plantuml_jar() -> tuple[bool, str]:
    """Check if plantuml.jar is accessible."""
    plantuml_path = find_plantuml_jar()
    if plantuml_path:
        print(f"[OK] plantuml.jar found: {plantuml_path}")
        return True, plantuml_path

    print("[ERROR] plantuml.jar not found. Download from https://plantuml.com/download")
    print("   Common locations to place it:")
    print("   - skill runtime/plantuml.jar")
    print("   - ./plantuml.jar (current directory)")
    print("   - ~/plantuml.jar (home directory)")
    print("   - /usr/local/bin/plantuml.jar")
    print("   Or set PLANTUML_JAR environment variable")
    return False, ''

def test_plantuml(jar_path: str) -> bool:
    """Test PlantUML with a simple diagram."""
    test_diagram = """@startuml
Alice -> Bob: Test
@enduml"""

    try:
        # Use SVG pipe mode so the subprocess output stays text-based on Windows.
        cmd = ['java', '-jar', jar_path, '-pipe', '-tsvg']
        result = subprocess.run(
            cmd,
            input=test_diagram,
            capture_output=True,
            text=True,
            env=build_subprocess_env()
        )

        if result.returncode == 0:
            print("[OK] PlantUML test successful")
            return True
        else:
            print(f"[ERROR] PlantUML test failed: {result.stderr}")
            return False
    except Exception as e:
        print(f"[ERROR] PlantUML test error: {e}")
        return False

def main():
    """Main entry point."""
    print("Checking PlantUML setup...\n")

    java_ok = check_java()
    graphviz_ok = check_graphviz()
    jar_ok, jar_path = check_plantuml_jar()

    print()

    if not java_ok or not jar_ok:
        print("[ERROR] Setup incomplete. Please install missing components.")
        sys.exit(1)

    if not graphviz_ok:
        print("[WARN] Graphviz missing. Some diagrams may not render correctly.")
        print("   Install from https://graphviz.org/download/")

    # Test PlantUML if everything is available
    if java_ok and jar_ok:
        print("\nTesting PlantUML...")
        test_plantuml(jar_path)

    print("\n[OK] PlantUML setup complete!")

if __name__ == '__main__':
    main()
