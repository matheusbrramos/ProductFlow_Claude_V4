#!/usr/bin/env python3
"""
todo_manager.py — Gerencia estado do todo.md sem LLM.
Zero tokens: leitura, escrita e atualização local.

Uso:
  python3 scripts/lib/todo_manager.py next --root .
  python3 scripts/lib/todo_manager.py list --root .
  python3 scripts/lib/todo_manager.py progress --root .
  python3 scripts/lib/todo_manager.py complete --root . --index 3
  python3 scripts/lib/todo_manager.py get --root . --index 2
"""

import os
import re
import sys
import argparse
from pathlib import Path


def read_todo(root: str) -> list:
    """Lê o todo.md e retorna lista de itens estruturados."""
    todo_path = Path(root) / 'todo.md'
    if not todo_path.exists():
        return []

    items = []
    current_phase = ""
    index = 0

    with open(todo_path, encoding='utf-8') as f:
        for line in f:
            line_stripped = line.rstrip()

            # Detecta fase (## Fase X: ...)
            phase_match = re.match(r'^## (.+)', line_stripped)
            if phase_match:
                current_phase = phase_match.group(1)
                continue

            # Detecta item pendente
            pending_match = re.match(r'^- \[ \] (.+)', line_stripped)
            if pending_match:
                items.append({
                    'index': index,
                    'phase': current_phase,
                    'task': pending_match.group(1),
                    'done': False,
                    'line': line_stripped,
                })
                index += 1
                continue

            # Detecta item concluído
            done_match = re.match(r'^- \[x\] (.+)', line_stripped, re.IGNORECASE)
            if done_match:
                items.append({
                    'index': index,
                    'phase': current_phase,
                    'task': done_match.group(1),
                    'done': True,
                    'line': line_stripped,
                })
                index += 1

    return items


def cmd_next(root: str) -> str:
    """Retorna o próximo item pendente."""
    items = read_todo(root)
    for item in items:
        if not item['done']:
            return f"TASK: {item['task']}\nPHASE: {item['phase']}\nINDEX: {item['index']}"
    return "ALL_DONE"


def cmd_get(root: str, index: int) -> str:
    """Retorna item por índice."""
    items = read_todo(root)
    for item in items:
        if item['index'] == index:
            return f"TASK: {item['task']}\nPHASE: {item['phase']}\nINDEX: {item['index']}"
    return "NOT_FOUND"


def cmd_list(root: str) -> str:
    """Lista todos os itens com status."""
    items = read_todo(root)
    if not items:
        return "Nenhum item encontrado em todo.md"

    lines = []
    current_phase = ""

    for item in items:
        if item['phase'] != current_phase:
            current_phase = item['phase']
            lines.append(f"\n{current_phase}")

        status = "[x]" if item['done'] else "[ ]"
        lines.append(f"  {status} {item['task']}")

    return "\n".join(lines)


def cmd_progress(root: str) -> str:
    """Retorna progresso no formato 'X/Y'."""
    items = read_todo(root)
    if not items:
        return "0/0"
    done = sum(1 for i in items if i['done'])
    total = len(items)
    return f"{done}/{total}"


def cmd_complete(root: str, index: int):
    """Marca um item como concluído no arquivo."""
    todo_path = Path(root) / 'todo.md'
    if not todo_path.exists():
        print("Erro: todo.md não encontrado", file=sys.stderr)
        sys.exit(1)

    items = read_todo(root)
    target = None
    for item in items:
        if item['index'] == index:
            target = item
            break

    if target is None:
        print(f"Erro: item {index} não encontrado", file=sys.stderr)
        sys.exit(1)

    if target['done']:
        return  # Já concluído

    # Substitui a primeira ocorrência de "- [ ] <task>" por "- [x] <task>"
    content = todo_path.read_text(encoding='utf-8')
    pattern = re.escape(f"- [ ] {target['task']}")
    replacement = f"- [x] {target['task']}"
    new_content = re.sub(pattern, replacement, content, count=1)

    if new_content != content:
        todo_path.write_text(new_content, encoding='utf-8')
    else:
        print(f"Aviso: não foi possível marcar '{target['task']}' como concluído", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(description='Gerenciador de todo.md — zero tokens')
    parser.add_argument('command', choices=['next', 'list', 'progress', 'complete', 'get'])
    parser.add_argument('--root', default='.', help='Diretório raiz do projeto')
    parser.add_argument('--index', type=int, help='Índice do item (para complete e get)')
    args = parser.parse_args()

    if args.command == 'next':
        print(cmd_next(args.root))
    elif args.command == 'list':
        print(cmd_list(args.root))
    elif args.command == 'progress':
        print(cmd_progress(args.root))
    elif args.command == 'complete':
        if args.index is None:
            print("Erro: --index obrigatório para 'complete'", file=sys.stderr)
            sys.exit(1)
        cmd_complete(args.root, args.index)
    elif args.command == 'get':
        if args.index is None:
            print("Erro: --index obrigatório para 'get'", file=sys.stderr)
            sys.exit(1)
        print(cmd_get(args.root, args.index))


if __name__ == '__main__':
    main()
