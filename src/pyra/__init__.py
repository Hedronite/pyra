"""Tiny closed-world example. The product is `nix run`; this module is the payload.

Pyra was formerly python-gate. ``import python_gate`` remains as an alias.
"""

from importlib.metadata import version

from rich.console import Console
from rich.table import Table


def square(n: int) -> int:
    """A pure function. `nix run` must not need the network."""
    return n * n


def greet() -> str:
    return f"{version('pyra')} · rich {version('rich')} · square(12)={square(12)}"


def main() -> None:
    table = Table(title="Pyra · closed world")
    table.add_column("proof")
    table.add_column("value")
    table.add_row("pyra", version("pyra"))
    table.add_row("rich", version("rich"))
    table.add_row("square(12)", str(square(12)))
    Console().print(table)
