#!/usr/bin/env python3
import argparse
import os
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Tuple


CONVERGED_RE = re.compile(r"Converged in\s+(\d+)\s+ms")
OOM_PATTERNS = (
    "malloc: Failed to allocate segment",
    "out of space",
    "Killed: 9",
    "beam.smp",
)


@dataclass
class RunResult:
    n: int
    converged_ms: Optional[int]
    success: bool
    stopped_due_to_oom: bool
    stopped_due_to_timeout: bool
    stderr_tail: str


def run_simulation(
    project_dir: Path,
    n: int,
    topology: str,
    algorithm: str,
    timeout_sec: int,
) -> RunResult:
    cmd = [
        "gleam",
        "run",
        "--",
        str(n),
        topology,
        algorithm,
    ]
    try:
        completed = subprocess.run(
            cmd,
            cwd=str(project_dir),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=timeout_sec,
            env={**os.environ},
        )
    except subprocess.TimeoutExpired as ex:
        stderr_tail = ""
        if ex.stderr:
            stderr_tail = ex.stderr[-400:]
        elif ex.output:
            stderr_tail = str(ex.output)[-400:]
        return RunResult(
            n=n,
            converged_ms=None,
            success=False,
            stopped_due_to_oom=False,
            stopped_due_to_timeout=True,
            stderr_tail=stderr_tail,
        )

    stdout = completed.stdout or ""
    stderr = completed.stderr or ""
    text = stdout + "\n" + stderr

    match = CONVERGED_RE.search(text)
    converged_ms: Optional[int] = int(match.group(1)) if match else None

    oom = any(pat in text for pat in OOM_PATTERNS)
    success = completed.returncode == 0 and converged_ms is not None and not oom

    return RunResult(
        n=n,
        converged_ms=converged_ms,
        success=success,
        stopped_due_to_oom=oom,
        stopped_due_to_timeout=False,
        stderr_tail=(stderr[-400:] if stderr else ""),
    )


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def choose_start_n(topology: str) -> int:
    # Conservative small starts; 3d rounds to nearest cube internally
    if topology == "line":
        return 10
    if topology == "3d":
        return 8  # small cube
    if topology == "full":
        return 10
    if topology == "imp3d":
        return 8
    return 10


def next_n(current: int) -> int:
    # Gradually increase; geometric growth ~x1.5 for smoother curves
    return max(current + 1, int(current * 1.5))


def plot_results(
    out_png: Path,
    ns: List[int],
    times_ms: List[int],
    title: str,
    xlabel: str = "n (number of nodes)",
    ylabel: str = "Convergence time (ms)",
) -> None:
    import matplotlib
    matplotlib.use("Agg")  # headless
    import matplotlib.pyplot as plt

    fig, ax = plt.subplots(figsize=(7, 4.5), dpi=150)
    ax.plot(ns, times_ms, marker="o", linewidth=1.5, markersize=3)
    ax.set_title(title)
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    ax.grid(True, linestyle=":", linewidth=0.7, alpha=0.6)
    fig.tight_layout()
    fig.savefig(out_png)
    plt.close(fig)


def write_csv(out_csv: Path, ns: List[int], times_ms: List[int]) -> None:
    ensure_dir(out_csv.parent)
    with out_csv.open("w", encoding="utf-8") as f:
        f.write("n,convergence_ms\n")
        for n, t in zip(ns, times_ms):
            f.write(f"{n},{t}\n")


def run_topology(
    project_dir: Path,
    topology: str,
    algorithm: str,
    timeout_sec: int,
    max_points: int,
    out_dir: Path,
) -> Tuple[List[int], List[int]]:
    ns: List[int] = []
    times_ms: List[int] = []

    n = choose_start_n(topology)
    points = 0

    print(f"\n=== Running {algorithm} on topology {topology} ===", flush=True)

    while points < max_points:
        print(f"Running: n={n}, topology={topology}, algorithm={algorithm} ...", flush=True)
        start = time.time()
        result = run_simulation(project_dir, n, topology, algorithm, timeout_sec)
        elapsed = time.time() - start

        if result.success and result.converged_ms is not None:
            ns.append(n)
            times_ms.append(result.converged_ms)
            points += 1
            print(
                f"  OK: converged in {result.converged_ms} ms (wall {elapsed:.2f}s)",
                flush=True,
            )
            n = next_n(n)
            continue

        if result.stopped_due_to_oom:
            print("  Stopping: OOM/malloc failure encountered.", flush=True)
            break

        if result.stopped_due_to_timeout:
            print("  Stopping: run hit timeout.", flush=True)
            break

        # Any other failure (non-zero exit or missing convergence line)
        print(
            "  Stopping: run failed or did not report convergence. stderr tail:\n" +
            (result.stderr_tail or "<empty>"),
            flush=True,
        )
        break

    # Save outputs
    ensure_dir(out_dir)
    png_path = out_dir / f"{topology}.png"
    csv_path = out_dir / f"{topology}.csv"
    if ns and times_ms:
        title = f"{algorithm} — {topology}"
        plot_results(png_path, ns, times_ms, title)
        write_csv(csv_path, ns, times_ms)
        print(f"Saved: {png_path}", flush=True)
        print(f"Saved: {csv_path}", flush=True)
    else:
        print("No successful points collected; nothing to plot.", flush=True)

    return ns, times_ms


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Run project2 simulator across topologies, increasing n until OOM/timeout, "
            "and plot convergence time vs n for each topology."
        )
    )
    parser.add_argument(
        "--project_dir",
        default=str(Path(__file__).resolve().parents[1]),
        help="Absolute path to project2 directory containing gleam.toml",
    )
    parser.add_argument(
        "--algorithm",
        choices=["gossip", "push-sum"],
        required=True,
        help="Algorithm to run",
    )
    parser.add_argument(
        "--topologies",
        nargs="*",
        default=["line", "3d", "full", "imp3d"],
        help="Topologies to run in order",
    )
    parser.add_argument(
        "--timeout_sec",
        type=int,
        default=180,
        help="Per-run timeout in seconds",
    )
    parser.add_argument(
        "--max_points",
        type=int,
        default=20,
        help="Maximum successful points to collect per topology",
    )
    parser.add_argument(
        "--out_dir",
        default=str(Path(__file__).resolve().parents[1] / "plots"),
        help="Output directory for plots and CSVs",
    )

    args = parser.parse_args()

    project_dir = Path(args.project_dir).resolve()
    out_root = Path(args.out_dir).resolve() / args.algorithm
    ensure_dir(out_root)

    print(f"Project dir: {project_dir}")
    print(f"Output dir:  {out_root}")
    print(f"Algorithm:   {args.algorithm}")
    print(f"Topologies:  {', '.join(args.topologies)}")

    for topology in args.topologies:
        run_topology(
            project_dir=project_dir,
            topology=topology,
            algorithm=args.algorithm,
            timeout_sec=args.timeout_sec,
            max_points=args.max_points,
            out_dir=out_root,
        )

    print("\nAll done.")
    return 0


if __name__ == "__main__":
    sys.exit(main())


