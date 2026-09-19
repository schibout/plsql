"""Import sûr et traçable des calendriers de clôture Excel (.xlsx).

Le format retenu est volontairement simple : trois feuilles mensuelles par
classeur, chacune avec les colonnes ARRETE / TRAITEMENT / RESTITUTION,
Date de Référence J, date calculée, moment et J±N. Les feuilles annexes
(jours fériés, synthèse) ne créent pas d'opérations.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime, timedelta
import hashlib
import io
import re
import sqlite3
from typing import Iterable
import xml.etree.ElementTree as ET
import zipfile


MONTHS = {
    "JANVIER": 1, "FEVRIER": 2, "FÉVRIER": 2, "MARS": 3, "AVRIL": 4,
    "MAI": 5, "JUIN": 6, "JUILLET": 7, "AOUT": 8, "AOÛT": 8,
    "SEPTEMBRE": 9, "OCTOBRE": 10, "NOVEMBRE": 11, "DECEMBRE": 12, "DÉCEMBRE": 12,
}
NS = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
      "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
      "p": "http://schemas.openxmlformats.org/package/2006/relationships"}


@dataclass(frozen=True)
class CalendarEvent:
    period: str
    reference_date: str | None
    event_date: str
    offset: str | None
    moment: str | None
    arrete: str | None
    traitement: str | None
    restitution: str | None
    source_sheet: str
    source_row: int

    @property
    def label(self) -> str:
        return " · ".join(x for x in (self.arrete, self.traitement, self.restitution) if x) or "Opération sans libellé"


@dataclass
class WorkbookPreview:
    months: dict[str, list[CalendarEvent]]
    ignored_sheets: list[str]
    warnings: list[str]

    @property
    def events(self) -> list[CalendarEvent]:
        return [event for items in self.months.values() for event in items]


def _local(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def _excel_date(value: str | None) -> str | None:
    if not value:
        return None
    try:
        serial = float(value)
    except (TypeError, ValueError):
        return None
    if not 1 <= serial <= 100_000:
        return None
    return (datetime(1899, 12, 30) + timedelta(days=serial)).date().isoformat()


def _text(node: ET.Element | None) -> str:
    if node is None:
        return ""
    return "".join(n.text or "" for n in node.iter() if _local(n.tag) == "t")


def _column(ref: str) -> str:
    return re.match(r"[A-Z]+", ref).group(0) if re.match(r"[A-Z]+", ref) else ""


def _month_from_sheet(name: str) -> tuple[int, int] | None:
    upper = re.sub(r"\s+", " ", name.strip().upper())
    year_match = re.search(r"\b(20\d{2})\b", upper)
    if not year_match:
        return None
    for month, number in MONTHS.items():
        if re.search(rf"\b{re.escape(month)}\b", upper):
            return int(year_match.group(1)), number
    return None


def _shared_strings(zf: zipfile.ZipFile) -> list[str]:
    try:
        root = ET.fromstring(zf.read("xl/sharedStrings.xml"))
    except KeyError:
        return []
    return [_text(node) for node in root.findall("m:si", NS)]


def _sheets(zf: zipfile.ZipFile) -> Iterable[tuple[str, ET.Element]]:
    workbook = ET.fromstring(zf.read("xl/workbook.xml"))
    rels = ET.fromstring(zf.read("xl/_rels/workbook.xml.rels"))
    rel_targets = {r.attrib["Id"]: r.attrib["Target"] for r in rels.findall("p:Relationship", NS)}
    for sheet in workbook.findall("m:sheets/m:sheet", NS):
        rel_id = sheet.attrib.get("{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id")
        target = rel_targets.get(rel_id, "")
        if target.startswith("/"):
            path = target.lstrip("/")
        else:
            path = "xl/" + target.replace("\\", "/")
        yield sheet.attrib["name"], ET.fromstring(zf.read(path))


def _rows(root: ET.Element, shared: list[str]) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for row in root.findall(".//m:sheetData/m:row", NS):
        current: dict[str, str] = {"__row__": row.attrib.get("r", "0")}
        for cell in row.findall("m:c", NS):
            ref = cell.attrib.get("r", "")
            col = _column(ref)
            typ = cell.attrib.get("t")
            val = cell.findtext("m:v", default="", namespaces=NS)
            if typ == "s" and val.isdigit() and int(val) < len(shared):
                val = shared[int(val)]
            elif typ == "inlineStr":
                val = _text(cell.find("m:is", NS))
            current[col] = (val or "").strip()
        rows.append(current)
    return rows


def _header_row(rows: list[dict[str, str]]) -> int | None:
    for index, row in enumerate(rows):
        values = " ".join(row.values()).upper()
        if "ARRETE" in values and "TRAITEMENT" in values and "RESTITUTION" in values:
            return index
    return None


def _date_in(value: str) -> str | None:
    if not value:
        return None
    as_excel = _excel_date(value)
    if as_excel:
        return as_excel
    for fmt in ("%Y-%m-%d", "%d/%m/%Y", "%d-%m-%Y"):
        try:
            return datetime.strptime(value, fmt).date().isoformat()
        except ValueError:
            pass
    return None


def preview_workbook(content: bytes) -> WorkbookPreview:
    """Lit un .xlsx sans l'exécuter, sans macros et sans lien externe."""
    if not content:
        raise ValueError("Fichier vide.")
    try:
        zf = zipfile.ZipFile(io.BytesIO(content))
    except zipfile.BadZipFile as exc:
        raise ValueError("Le fichier n'est pas un classeur Excel .xlsx lisible.") from exc
    with zf:
        if "xl/workbook.xml" not in zf.namelist():
            raise ValueError("Le fichier n'est pas un classeur .xlsx valide.")
        shared = _shared_strings(zf)
        months: dict[str, list[CalendarEvent]] = {}
        ignored: list[str] = []
        warnings: list[str] = []
        for name, root in _sheets(zf):
            month = _month_from_sheet(name)
            rows = _rows(root, shared)
            header = _header_row(rows)
            if not month or header is None:
                ignored.append(name)
                continue
            year, month_num = month
            period = f"{year:04d}-{month_num:02d}"
            entries: list[CalendarEvent] = []
            for row in rows[header + 1:]:
                event_date = _date_in(row.get("E", ""))
                if not event_date:
                    continue
                labels = [row.get(c, "").strip() or None for c in ("A", "B", "C")]
                if not any(labels):
                    continue
                entries.append(CalendarEvent(
                    period=period, reference_date=_date_in(row.get("D", "")), event_date=event_date,
                    offset=row.get("G", "").strip() or None, moment=row.get("F", "").strip() or None,
                    arrete=labels[0], traitement=labels[1], restitution=labels[2],
                    source_sheet=name, source_row=int(row.get("__row__", "0") or 0)))
            if not entries:
                warnings.append(f"{name} : aucune opération datée reconnue.")
            months[period] = entries
        if not months:
            raise ValueError("Aucune feuille mensuelle reconnue. Les en-têtes ARRETE / TRAITEMENT / RESTITUTION sont requis.")
        if len(months) != 3:
            warnings.append(f"{len(months)} feuille(s) mensuelle(s) reconnue(s) ; un fichier trimestriel doit en contenir 3.")
        return WorkbookPreview(months=months, ignored_sheets=ignored, warnings=warnings)


def import_workbook(con: sqlite3.Connection, name: str, content: bytes, preview: WorkbookPreview | None = None) -> tuple[int | None, str]:
    """Enregistre un classeur validé. Un fichier identique ne peut pas créer de doublon."""
    preview = preview or preview_workbook(content)
    if len(preview.months) != 3:
        raise ValueError("L'import requiert exactement trois feuilles mensuelles reconnues.")
    digest = hashlib.sha256(content).hexdigest()
    existing = con.execute("SELECT id FROM calendar_imports WHERE file_hash=?", (digest,)).fetchone()
    if existing:
        return None, f"Déjà chargé (import n°{existing['id']})."
    periods = sorted(preview.months)
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with con:
        # Un nouveau trimestre devient actif pour ses mois, les anciennes versions restent en historique.
        placeholders = ",".join("?" for _ in periods)
        con.execute(f"""UPDATE calendar_imports SET statut='inactive'
                         WHERE statut='active' AND id IN (
                           SELECT DISTINCT import_id FROM calendar_events WHERE periode_comptable IN ({placeholders})
                         )""", periods)
        cur = con.execute("""INSERT INTO calendar_imports(nom_fichier,file_hash,importe_le,statut,nb_mois,nb_operations,message)
                             VALUES (?,?,?,?,?,?,?)""",
                          (name, digest, now, "active", len(periods), len(preview.events), "; ".join(preview.warnings) or None))
        import_id = cur.lastrowid
        con.executemany("""INSERT INTO calendar_events(import_id,periode_comptable,reference_j,date_operation,decalage_j,moment,
                           arrete,traitement,restitution,source_sheet,source_row)
                           VALUES (?,?,?,?,?,?,?,?,?,?,?)""",
                        [(import_id, e.period, e.reference_date, e.event_date, e.offset, e.moment,
                          e.arrete, e.traitement, e.restitution, e.source_sheet, e.source_row)
                         for e in preview.events])
    return import_id, f"{len(preview.events)} opération(s) de {len(periods)} mois activées."


def imports(con: sqlite3.Connection):
    return con.execute("SELECT * FROM calendar_imports ORDER BY importe_le DESC, id DESC").fetchall()
