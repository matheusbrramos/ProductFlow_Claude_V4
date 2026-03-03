#!/usr/bin/env python3
"""
extract_context.py — Extração cirúrgica de contexto.
Zero tokens: extrai apenas o trecho relevante do blueprint/PRD.

Redução típica: blueprint de 4000 tokens → modelo recebe ~800 tokens da fase atual.

Uso:
  python3 scripts/lib/extract_context.py --blueprint blueprint.md --phase "Fase 1"
  python3 scripts/lib/extract_context.py --prd prd.md --keyword "autenticação"
  python3 scripts/lib/extract_context.py --blueprint blueprint.md --phase "Fase 1" --root .
"""

import re
import sys
import argparse
from pathlib import Path

# Limites de tamanho para cada fonte de contexto
LIMITS = {
    'claude_md': 800,
    'agents_md': 600,
    'blueprint_phase': 1200,
    'prd_section': 800,
}


def extract_blueprint_phase(blueprint_path: str, phase: str) -> str:
    """Extrai apenas a seção da fase especificada do blueprint."""
    path = Path(blueprint_path)
    if not path.exists():
        return ""

    content = path.read_text(encoding='utf-8', errors='ignore')

    # Tenta encontrar a seção da fase (### Fase X: ...)
    pattern = rf'(### {re.escape(phase)}.*?)(?=\n### |\Z)'
    match = re.search(pattern, content, re.DOTALL)

    if match:
        section = match.group(1).strip()
        return truncate(section, LIMITS['blueprint_phase'])

    # Fallback: busca por correspondência parcial
    lines = content.split('\n')
    phase_lower = phase.lower()
    start_idx = None

    for i, line in enumerate(lines):
        if line.startswith('### ') and phase_lower in line.lower():
            start_idx = i
            break

    if start_idx is None:
        return ""

    # Coleta até o próximo ###
    section_lines = []
    for line in lines[start_idx:]:
        if line.startswith('### ') and len(section_lines) > 0:
            break
        section_lines.append(line)

    return truncate('\n'.join(section_lines), LIMITS['blueprint_phase'])


def extract_prd_section(prd_path: str, keyword: str) -> str:
    """Extrai seções do PRD relacionadas ao keyword."""
    path = Path(prd_path)
    if not path.exists():
        return ""

    content = path.read_text(encoding='utf-8', errors='ignore')
    keyword_lower = keyword.lower()

    # Divide em seções (## ...)
    sections = re.split(r'\n(?=## )', content)
    relevant = []

    for section in sections:
        if keyword_lower in section.lower():
            relevant.append(section.strip())

    if not relevant:
        # Fallback: retorna começo do PRD
        return truncate(content, LIMITS['prd_section'])

    return truncate('\n\n'.join(relevant), LIMITS['prd_section'])


def truncate(text: str, max_chars: int) -> str:
    """Trunca texto ao limite especificado."""
    if len(text) <= max_chars:
        return text
    return text[:max_chars] + "\n[... truncado ...]"


def build_composite_context(root: str, phase: str = "", keyword: str = "",
                             blueprint: str = None, prd: str = None) -> str:
    """
    Monta contexto composto:
    CLAUDE.md (truncado) + agents.md (truncado) + seção do blueprint + seção do PRD.
    """
    root_path = Path(root)
    sections = []

    # CLAUDE.md
    claude_md = root_path / 'CLAUDE.md'
    if claude_md.exists():
        content = claude_md.read_text(encoding='utf-8', errors='ignore')
        sections.append(f"## CLAUDE.md\n{truncate(content, LIMITS['claude_md'])}")

    # agents.md
    agents_md = root_path / 'agents.md'
    if agents_md.exists():
        content = agents_md.read_text(encoding='utf-8', errors='ignore')
        sections.append(f"## Lições Aprendidas (agents.md)\n{truncate(content, LIMITS['agents_md'])}")

    # Seção do blueprint
    blueprint_path = blueprint or str(root_path / 'blueprint.md')
    if phase and Path(blueprint_path).exists():
        phase_content = extract_blueprint_phase(blueprint_path, phase)
        if phase_content:
            sections.append(f"## Plano — {phase}\n{phase_content}")

    # Seção do PRD
    prd_path = prd or str(root_path / 'prd.md')
    if keyword and Path(prd_path).exists():
        prd_content = extract_prd_section(prd_path, keyword)
        if prd_content:
            sections.append(f"## PRD — seção relevante\n{prd_content}")

    return '\n\n'.join(sections)


def main():
    parser = argparse.ArgumentParser(description='Extração cirúrgica de contexto — zero tokens')
    parser.add_argument('--blueprint', help='Caminho do blueprint.md')
    parser.add_argument('--prd', help='Caminho do prd.md')
    parser.add_argument('--phase', default='', help='Nome da fase para extrair do blueprint')
    parser.add_argument('--keyword', default='', help='Keyword para extrair do PRD')
    parser.add_argument('--root', default='.', help='Diretório raiz (para CLAUDE.md e agents.md)')
    parser.add_argument('--composite', action='store_true',
                        help='Monta contexto composto (CLAUDE.md + agents.md + blueprint + PRD)')
    args = parser.parse_args()

    if args.composite:
        result = build_composite_context(
            root=args.root,
            phase=args.phase,
            keyword=args.keyword,
            blueprint=args.blueprint,
            prd=args.prd
        )
        print(result)
        return

    if args.blueprint and args.phase:
        result = extract_blueprint_phase(args.blueprint, args.phase)
        print(result)
        return

    if args.prd and args.keyword:
        result = extract_prd_section(args.prd, args.keyword)
        print(result)
        return

    # Sem argumentos específicos: tenta contexto composto
    if args.root:
        result = build_composite_context(root=args.root, phase=args.phase, keyword=args.keyword)
        print(result)


if __name__ == '__main__':
    main()
