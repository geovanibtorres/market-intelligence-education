import argparse
import re
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import pandas as pd


COURSES_PATTERN = re.compile(r"MICRODADOS_CADASTRO_CURSOS_(\d{4})\.CSV$", re.IGNORECASE)
IES_PATTERN_A = re.compile(r"MICRODADOS_CADASTRO_IES_(\d{4})(?:\s*\(\d+\))?\.CSV$", re.IGNORECASE)
IES_PATTERN_B = re.compile(r"MICRODADOS_ED_SUP_IES_(\d{4})\.CSV$", re.IGNORECASE)
IGC_PATTERN = re.compile(r"igc|historico_indices_consulta_publica_avancada_ies", re.IGNORECASE)
PRIVATE_PATTERN = re.compile(r"base\s*de\s*clientes|private|interno|internal|proprietary", re.IGNORECASE)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Consolidate public MEC IES/CURSOS/IGC files into local parquet datasets."
    )
    parser.add_argument(
        "--source-root",
        required=True,
        help="Root folder where MEC downloads are stored.",
    )
    parser.add_argument(
        "--output-root",
        default="data",
        help="Output folder for consolidated data (default: data).",
    )
    parser.add_argument(
        "--min-year",
        type=int,
        default=2013,
        help="Minimum year to include (default: 2013).",
    )
    parser.add_argument(
        "--max-year",
        type=int,
        default=2024,
        help="Maximum year to include (default: 2024).",
    )
    return parser.parse_args()


def _priority(path: Path) -> Tuple[int, int, int]:
    path_str = str(path).lower()
    in_dados = 1 if "\\dados\\" in path_str else 0
    no_copy_suffix = 1 if "(" not in path.name else 0
    shallow = -len(path.parts)
    return (in_dados, no_copy_suffix, shallow)


def discover_files(
    source_root: Path,
    min_year: int,
    max_year: int,
) -> Tuple[Dict[int, Path], Dict[int, Path], List[Path]]:
    courses_candidates: Dict[int, List[Path]] = {}
    ies_candidates: Dict[int, List[Path]] = {}
    igc_candidates: List[Path] = []

    def is_private_file(path: Path) -> bool:
        return bool(PRIVATE_PATTERN.search(path.name))

    for path in source_root.rglob("*.CSV"):
        if is_private_file(path):
            continue

        match = COURSES_PATTERN.search(path.name)
        if match:
            year = int(match.group(1))
            if min_year <= year <= max_year:
                courses_candidates.setdefault(year, []).append(path)
            continue

        match = IES_PATTERN_A.search(path.name)
        if not match:
            match = IES_PATTERN_B.search(path.name)
        if match:
            year = int(match.group(1))
            if min_year <= year <= max_year:
                ies_candidates.setdefault(year, []).append(path)

        if IGC_PATTERN.search(path.name):
            igc_candidates.append(path)

    for ext in ("*.xls", "*.xlsx"):
        for path in source_root.rglob(ext):
            if is_private_file(path):
                continue
            if IGC_PATTERN.search(path.name):
                igc_candidates.append(path)

    courses = {y: sorted(paths, key=_priority, reverse=True)[0] for y, paths in courses_candidates.items()}
    ies = {y: sorted(paths, key=_priority, reverse=True)[0] for y, paths in ies_candidates.items()}
    igc_candidates = sorted(set(igc_candidates), key=lambda p: str(p).lower())
    return courses, ies, igc_candidates


def detect_separator(file_path: Path) -> str:
    with file_path.open("r", encoding="latin-1", errors="ignore") as fh:
        sample = fh.read(4096)
    return ";" if sample.count(";") >= sample.count(",") else ","


def read_csv(file_path: Path, year: int) -> pd.DataFrame:
    sep = detect_separator(file_path)

    df = pd.read_csv(
        file_path,
        sep=sep,
        encoding="latin-1",
        low_memory=False,
    )

    df.columns = [str(c).strip().upper() for c in df.columns]

    if "NU_ANO_CENSO" not in df.columns:
        df["NU_ANO_CENSO"] = year

    return df


def read_tabular(file_path: Path) -> pd.DataFrame:
    suffix = file_path.suffix.lower()
    if suffix == ".csv":
        sep = detect_separator(file_path)
        df = pd.read_csv(file_path, sep=sep, encoding="latin-1", low_memory=False)
    elif suffix in (".xls", ".xlsx"):
        df = pd.read_excel(file_path)
    else:
        raise ValueError(f"Unsupported extension: {suffix}")

    df.columns = [str(c).strip().upper() for c in df.columns]
    return df


def write_partitioned(df: pd.DataFrame, base_dir: Path, domain: str, year: int) -> Path:
    out_dir = base_dir / "bronze" / domain / f"year={year}"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / "data.parquet"
    df.to_parquet(out_file, index=False)
    return out_file


def write_partitioned_snapshot(df: pd.DataFrame, base_dir: Path, domain: str, snapshot: str) -> Path:
    out_dir = base_dir / "bronze" / domain / f"snapshot={snapshot}"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / "data.parquet"
    df.to_parquet(out_file, index=False)
    return out_file


def consolidate_silver(base_dir: Path, domain: str) -> Optional[Path]:
    domain_dir = base_dir / "bronze" / domain
    if not domain_dir.exists():
        return None

    files = sorted(domain_dir.rglob("*.parquet"))
    if not files:
        return None

    frames = [pd.read_parquet(f) for f in files]
    merged = pd.concat(frames, ignore_index=True)

    out_dir = base_dir / "silver"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / f"{domain}_all_years.parquet"
    merged.to_parquet(out_file, index=False)
    return out_file


def build_manifest(
    courses: Dict[int, Path],
    ies: Dict[int, Path],
    igc: List[Path],
    output_root: Path,
) -> Path:
    rows = []
    years = sorted(set(courses.keys()) | set(ies.keys()))
    for year in years:
        rows.append(
            {
                "year": year,
                "courses_source": str(courses.get(year, "")),
                "ies_source": str(ies.get(year, "")),
                "courses_found": year in courses,
                "ies_found": year in ies,
            }
        )

    manifest = pd.DataFrame(rows)
    out_file = output_root / "manifest_mec_sources.csv"
    manifest.to_csv(out_file, index=False)

    igc_manifest = pd.DataFrame(
        [
            {
                "source": str(path),
                "extension": path.suffix.lower(),
                "is_igc_candidate": True,
            }
            for path in igc
        ]
    )
    igc_manifest_file = output_root / "manifest_igc_sources.csv"
    igc_manifest.to_csv(igc_manifest_file, index=False)

    return out_file


def main() -> None:
    args = parse_args()
    source_root = Path(args.source_root)
    output_root = Path(args.output_root)
    output_root.mkdir(parents=True, exist_ok=True)

    courses, ies, igc_files = discover_files(source_root, args.min_year, args.max_year)

    for year, path in sorted(courses.items()):
        df = read_csv(path, year)
        write_partitioned(df, output_root, "cursos", year)

    for year, path in sorted(ies.items()):
        df = read_csv(path, year)
        write_partitioned(df, output_root, "ies", year)

    for path in igc_files:
        df = read_tabular(path)
        snapshot = re.sub(r"[^a-zA-Z0-9_-]", "_", path.stem.lower())
        write_partitioned_snapshot(df, output_root, "igc", snapshot)

    cursos_silver = consolidate_silver(output_root, "cursos")
    ies_silver = consolidate_silver(output_root, "ies")
    igc_silver = consolidate_silver(output_root, "igc")
    manifest_file = build_manifest(courses, ies, igc_files, output_root)

    print("Consolidation finished.")
    print(f"Courses years found: {len(courses)}")
    print(f"IES years found: {len(ies)}")
    print(f"IGC files found: {len(igc_files)}")
    print(f"Manifest: {manifest_file}")
    print(f"Silver cursos: {cursos_silver}")
    print(f"Silver ies: {ies_silver}")
    print(f"Silver igc: {igc_silver}")


if __name__ == "__main__":
    main()
