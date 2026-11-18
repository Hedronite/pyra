"""Compatibility alias for :mod:`pyra`.

python-gate was renamed to Pyra. Prefer ``import pyra``.
This module stays so existing ``import python_gate`` keeps working.
"""

from pyra import greet, main, square

__all__ = ["greet", "main", "square"]
