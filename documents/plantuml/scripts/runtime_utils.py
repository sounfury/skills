#!/usr/bin/env python3
"""
Shared runtime discovery helpers for the PlantUML skill.

This module centralizes lookup for:
- skill-bundled ``plantuml.jar``
- skill-bundled Graphviz ``dot``
- fallback user-level and system-level installations
"""

from __future__ import annotations

import os
import shutil
from pathlib import Path


def get_scripts_dir() -> Path:
    """Return the directory that contains the PlantUML helper scripts."""
    return Path(__file__).resolve().parent


def get_skill_root() -> Path:
    """Return the installed PlantUML skill root directory."""
    return get_scripts_dir().parent


def get_runtime_root() -> Path:
    """Return the preferred directory for bundled cross-session runtimes."""
    return get_skill_root() / 'runtime'


def iter_plantuml_jar_candidates() -> list[Path]:
    """
    Return candidate ``plantuml.jar`` paths in priority order.

    The bundled runtime is checked first so the skill can work across sessions
    without depending on the current workspace.
    """
    skill_root = get_skill_root()
    runtime_root = get_runtime_root()

    return [
        runtime_root / 'plantuml.jar',
        skill_root / 'plantuml.jar',
        Path.cwd() / 'plantuml.jar',
        Path.home() / 'plantuml.jar',
        Path.home() / 'bin' / 'plantuml.jar',
        Path('/usr/local/bin/plantuml.jar'),
        Path('/usr/share/plantuml/plantuml.jar'),
    ]


def find_plantuml_jar() -> str:
    """
    Locate ``plantuml.jar`` from environment, bundled runtime, or common paths.

    Returns:
        Absolute path string when found, otherwise an empty string.
    """
    env_path = os.environ.get('PLANTUML_JAR')
    if env_path and Path(env_path).is_file():
        return str(Path(env_path).resolve())

    for candidate in iter_plantuml_jar_candidates():
        if candidate.is_file():
            return str(candidate.resolve())

    # Keep Homebrew glob support for compatibility with the original script.
    cellar_root = Path('/opt/homebrew/Cellar/plantuml')
    if cellar_root.exists():
        matches = sorted(cellar_root.glob('*/libexec/plantuml.jar'))
        if matches:
            return str(matches[0].resolve())

    return ''


def iter_graphviz_bin_candidates() -> list[Path]:
    """
    Return candidate Graphviz ``bin`` directories in priority order.

    The lookup prefers the skill-bundled runtime so ``dot`` is available across
    sessions even when the system PATH does not include Graphviz.
    """
    runtime_root = get_runtime_root()
    skill_root = get_skill_root()
    candidates: list[Path] = []

    for graphviz_root in [runtime_root / 'graphviz', skill_root / 'graphviz']:
        if not graphviz_root.exists():
            continue

        # Graphviz ZIP packages usually contain a versioned top-level directory.
        for bin_dir in graphviz_root.glob('**/bin'):
            if bin_dir.is_dir():
                candidates.append(bin_dir)

    if os.name == 'nt':
        candidates.extend([
            Path(r'C:\Program Files\Graphviz\bin'),
            Path(r'C:\Program Files (x86)\Graphviz\bin'),
        ])

    return candidates


def find_graphviz_dot() -> str:
    """
    Locate the Graphviz ``dot`` executable from environment, PATH, or runtime.

    Returns:
        Absolute path string when found, otherwise an empty string.
    """
    env_path = os.environ.get('GRAPHVIZ_DOT')
    if env_path and Path(env_path).is_file():
        return str(Path(env_path).resolve())

    dot_from_path = shutil.which('dot')
    if dot_from_path:
        return str(Path(dot_from_path).resolve())

    executable_names = ['dot.exe', 'dot'] if os.name == 'nt' else ['dot']
    for bin_dir in iter_graphviz_bin_candidates():
        for executable_name in executable_names:
            candidate = bin_dir / executable_name
            if candidate.is_file():
                return str(candidate.resolve())

    return ''


def build_subprocess_env() -> dict[str, str]:
    """
    Build a subprocess environment with bundled runtime paths applied.

    Returns:
        A copy of the current environment with optional ``PLANTUML_JAR``,
        ``GRAPHVIZ_DOT``, and ``PATH`` adjustments.
    """
    env = os.environ.copy()

    dot_path = find_graphviz_dot()
    if dot_path:
        dot_bin_dir = str(Path(dot_path).parent)
        current_path = env.get('PATH', '')
        path_parts = [part for part in current_path.split(os.pathsep) if part]

        # Prepend the bundled Graphviz bin only once so PlantUML can resolve it.
        if dot_bin_dir not in path_parts:
            env['PATH'] = os.pathsep.join([dot_bin_dir, *path_parts])
        env.setdefault('GRAPHVIZ_DOT', dot_path)

    jar_path = find_plantuml_jar()
    if jar_path:
        env.setdefault('PLANTUML_JAR', jar_path)

    return env
