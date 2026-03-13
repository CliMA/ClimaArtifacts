#!/usr/bin/env python3
"""
Batch wrapper for get_initial_conditions.py that accepts an explicit list of dates.

Clones git@github.com:CliMA/WeatherQuest.git into a temporary directory and
runs processing/get_initial_conditions.py from there for each requested date.

Usage:
    python run_dates.py --dates 2024-01-01 2024-03-15 2024-06-01 [options]
    python run_dates.py --dates-file dates.txt [options]

Dates may optionally include a time: "YYYY-MM-DD HH:MM" (default time: 00:00).
Any extra arguments are passed directly to get_initial_conditions.py.

Examples:
    python run_dates.py --dates "2024-01-01 06:00" "2024-07-01 12:00"
    python run_dates.py --dates-file my_dates.txt --groups atmos,surface,land --output-dir /data/era5
    python run_dates.py --dates 2024-01-01 2024-06-01 --no-keep-separate --overwrite
"""

import argparse
import subprocess
import sys
import tempfile
from pathlib import Path

WEATHERQUEST_REPO = "git@github.com:CliMA/WeatherQuest.git"
SCRIPT_REL_PATH = "processing/get_initial_conditions.py"


def parse_args():
    parser = argparse.ArgumentParser(
        description="Run get_initial_conditions.py (from WeatherQuest repo) for each date in a list",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )

    date_group = parser.add_mutually_exclusive_group(required=True)
    date_group.add_argument(
        "--dates",
        nargs="+",
        metavar="YYYY-MM-DD",
        help="One or more dates to process",
    )
    date_group.add_argument(
        "--dates-file",
        metavar="FILE",
        help="Path to a text file with one date per line (YYYY-MM-DD). "
             "Lines starting with '#' and blank lines are ignored.",
    )

    parser.add_argument(
        "--branch",
        default="main",
        help="Branch to check out from WeatherQuest repo (default: main)",
    )

    parser.add_argument(
        "--repo-dir",
        metavar="DIR",
        help="Path to an existing WeatherQuest clone. If provided, skips cloning.",
    )

    args, extra_args = parser.parse_known_args()
    args.extra_args = extra_args
    return args


def parse_date_time(entry):
    """Split a 'YYYY-MM-DD[ HH:MM]' entry into (date, time), defaulting time to 00:00."""
    parts = entry.split()
    date = parts[0]
    time = parts[1] if len(parts) > 1 else "00:00"
    return date, time


def load_dates_from_file(path):
    lines = Path(path).read_text().splitlines()
    entries = []
    for line in lines:
        line = line.strip()
        if line and not line.startswith("#"):
            entries.append(line)
    return entries


def clone_repo(dest, branch):
    print(f"Cloning {WEATHERQUEST_REPO} (branch: {branch}) into {dest} ...")
    result = subprocess.run(
        ["git", "clone", "--depth", "1", "--branch", branch, WEATHERQUEST_REPO, str(dest)],
        check=False,
    )
    if result.returncode != 0:
        print(f"Error: git clone failed (exit code {result.returncode})", file=sys.stderr)
        sys.exit(1)
    print("Clone complete.\n")


def main():
    args = parse_args()

    entries = args.dates if args.dates else load_dates_from_file(args.dates_file)

    if not entries:
        print("Error: no dates provided.", file=sys.stderr)
        sys.exit(1)

    datetimes = [parse_date_time(e) for e in entries]

    def run_with_repo(repo_dir):
        script = Path(repo_dir) / SCRIPT_REL_PATH
        if not script.exists():
            print(f"Error: {SCRIPT_REL_PATH} not found in repo.", file=sys.stderr)
            sys.exit(1)

        print(f"Processing {len(datetimes)} date(s): {', '.join(f'{d} {t}' for d, t in datetimes)}")
        print("-" * 60)

        failed = []
        for i, (date, time) in enumerate(datetimes, 1):
            print(f"\n[{i}/{len(datetimes)}] Date: {date} {time}")
            cmd = ["python", str(script), "--date", date, "--time", time] + args.extra_args
            result = subprocess.run(cmd)
            if result.returncode != 0:
                print(
                    f"  ERROR: get_initial_conditions.py failed for {date} {time} "
                    f"(exit code {result.returncode})"
                )
                failed.append(f"{date} {time}")

        print("\n" + "=" * 60)
        if failed:
            print(f"Completed with errors. Failed dates ({len(failed)}/{len(datetimes)}):")
            for dt in failed:
                print(f"  {dt}")
            sys.exit(1)
        else:
            print(f"All {len(datetimes)} date(s) completed successfully.")

    if args.repo_dir:
        run_with_repo(args.repo_dir)
    else:
        with tempfile.TemporaryDirectory(prefix="weatherquest_") as tmpdir:
            clone_repo(tmpdir, args.branch)
            run_with_repo(tmpdir)


if __name__ == "__main__":
    main()
