#!/usr/bin/env python3
"""
scan_project.py — Varre estrutura do projeto e monta contexto compacto.
Zero tokens: processamento local puro.

Uso:
  python3 scripts/lib/scan_project.py --root /caminho/do/projeto
  python3 scripts/lib/scan_project.py --root . --task "implementar login"
"""

import os
import sys
import argparse
import subprocess
from pathlib import Path

IGNORE_DIRS = {
    'node_modules', '.git', 'dist', 'build', '__pycache__',
    '.next', '.nuxt', 'coverage', '.pytest_cache', 'venv',
    'env', '.env', '.venv', 'vendor', 'target', 'out'
}

CODE_EXTENSIONS = {
    '.py', '.js', '.ts', '.tsx', '.jsx', '.go', '.rs',
    '.java', '.php', '.rb', '.sh', '.sql', '.html', '.css'
}

MAX_FILE_LINES = 120
MAX_TOTAL_FILES = 30


def get_tree(root: Path, prefix: str = "", max_depth: int = 3, current_depth: int = 0) -> list:
    """Gera árvore de diretórios em texto."""
    if current_depth >= max_depth:
        return []

    lines = []
    try:
        entries = sorted(root.iterdir(), key=lambda e: (e.is_file(), e.name))
    except PermissionError:
        return []

    entries = [e for e in entries if e.name not in IGNORE_DIRS and not e.name.startswith('.')]

    for i, entry in enumerate(entries):
        is_last = i == len(entries) - 1
        connector = "└── " if is_last else "├── "
        lines.append(f"{prefix}{connector}{entry.name}")
        if entry.is_dir():
            extension = "    " if is_last else "│   "
            lines.extend(get_tree(entry, prefix + extension, max_depth, current_depth + 1))

    return lines


def get_relevant_files(root: Path, task: str = "") -> list:
    """Encontra arquivos relevantes para a tarefa atual."""
    keywords = set(task.lower().split()) if task else set()
    scored_files = []

    for filepath in root.rglob("*"):
        if not filepath.is_file():
            continue
        if any(part in IGNORE_DIRS for part in filepath.parts):
            continue
        if filepath.suffix not in CODE_EXTENSIONS:
            continue

        score = 0

        # Score por keywords no nome do arquivo
        name_lower = filepath.stem.lower()
        for kw in keywords:
            if kw in name_lower:
                score += 3

        # Score por keywords no conteúdo (primeiras 30 linhas)
        if keywords:
            try:
                content = filepath.read_text(encoding='utf-8', errors='ignore')
                first_lines = '\n'.join(content.split('\n')[:30]).lower()
                for kw in keywords:
                    if kw in first_lines:
                        score += 1
            except Exception:
                pass

        # Arquivos de configuração importantes têm score base
        important_names = {'main', 'index', 'app', 'server', 'config', 'settings', 'api', 'auth', 'models'}
        if filepath.stem.lower() in important_names:
            score += 2

        scored_files.append((score, filepath))

    scored_files.sort(key=lambda x: x[0], reverse=True)
    return [f for _, f in scored_files[:MAX_TOTAL_FILES]]


def get_git_context(root: Path) -> str:
    """Extrai contexto git (branch + últimos commits)."""
    try:
        branch = subprocess.check_output(
            ['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
            cwd=root, stderr=subprocess.DEVNULL, text=True
        ).strip()

        commits = subprocess.check_output(
            ['git', 'log', '--oneline', '-5'],
            cwd=root, stderr=subprocess.DEVNULL, text=True
        ).strip()

        return f"Branch: {branch}\nÚltimos commits:\n{commits}"
    except Exception:
        return ""


def get_dependencies(root: Path) -> str:
    """Lê dependências do projeto."""
    dep_files = [
        ('package.json', lambda c: extract_json_deps(c)),
        ('requirements.txt', lambda c: c[:500]),
        ('pyproject.toml', lambda c: c[:500]),
        ('go.mod', lambda c: c[:300]),
        ('Cargo.toml', lambda c: c[:300]),
    ]

    for filename, extractor in dep_files:
        filepath = root / filename
        if filepath.exists():
            try:
                content = filepath.read_text(encoding='utf-8', errors='ignore')
                return f"{filename}:\n{extractor(content)}"
            except Exception:
                pass

    return ""


def extract_json_deps(content: str) -> str:
    """Extrai dependencies do package.json."""
    try:
        import json
        data = json.loads(content)
        deps = {}
        deps.update(data.get('dependencies', {}))
        deps.update(data.get('devDependencies', {}))
        return '\n'.join(f"  {k}: {v}" for k, v in list(deps.items())[:20])
    except Exception:
        return content[:300]


def scan(root_path: str, task: str = "") -> str:
    """Executa o scan completo e retorna contexto formatado."""
    root = Path(root_path).resolve()

    sections = []

    # Estrutura de diretórios
    tree_lines = get_tree(root)
    if tree_lines:
        sections.append(f"## Estrutura do Projeto\n```\n{root.name}/\n" + "\n".join(tree_lines[:40]) + "\n```")

    # Dependências
    deps = get_dependencies(root)
    if deps:
        sections.append(f"## Dependências\n{deps}")

    # Contexto git
    git_ctx = get_git_context(root)
    if git_ctx:
        sections.append(f"## Git\n{git_ctx}")

    # Arquivos relevantes
    relevant = get_relevant_files(root, task)
    if relevant:
        file_summaries = []
        for filepath in relevant[:10]:
            try:
                content = filepath.read_text(encoding='utf-8', errors='ignore')
                lines = content.split('\n')
                preview = '\n'.join(lines[:MAX_FILE_LINES])
                rel_path = filepath.relative_to(root)
                file_summaries.append(f"### {rel_path}\n```\n{preview}\n```")
            except Exception:
                pass

        if file_summaries:
            sections.append("## Arquivos Relevantes\n" + "\n\n".join(file_summaries))

    return "\n\n".join(sections)


def main():
    parser = argparse.ArgumentParser(description='Scan de projeto — zero tokens')
    parser.add_argument('--root', default='.', help='Diretório raiz do projeto')
    parser.add_argument('--task', default='', help='Tarefa atual para filtrar arquivos relevantes')
    args = parser.parse_args()

    result = scan(args.root, args.task)
    print(result)


if __name__ == '__main__':
    main()
