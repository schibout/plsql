"""Rend les modules d'odat_watch importables depuis tests/ quel que soit le cwd."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
