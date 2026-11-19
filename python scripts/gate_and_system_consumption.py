import re
import numpy as np
import matplotlib.pyplot as plt
from read_aimspice import read_runs

# ---------------- Settings ----------------
OUT_FILES = ["everyGateTestStacking.out", "WholeCircuitTestStacked.out"]      # one or more AIM-Spice .out files
CORNER = "ss"                           # must match the end of the netlist title
GATE_TITLE = f"Gate minimum VDD - {CORNER}"
SYSTEM_TITLE = f"System minimum VDD - {CORNER}"

plt.rcParams.update({"font.size": 11})
FIGSIZE = (8, 4.5)


def latest_run(title):
    """Return the most recent DC sweep whose title contains `title`."""
    runs = [r for f in OUT_FILES for r in read_runs(f)
            if title in r["title"] and r["analysis"] == "DC Transfer Curves"]
    if not runs:
        raise ValueError(f"No DC sweep with title '{title}' found")
    return runs[-1]


def margin(v, vdd, expected):
    """Distance to the logic limit: positive = valid, negative = fails."""
    if expected == 1:
        return v - 0.75 * vdd
    if expected == 0:
        return 0.25 * vdd - v
    # expected is None: any valid logic level (internal nodes)
    return np.maximum(0.25 * vdd - v, v - 0.75 * vdd)


def minimum_vdd(vdd, worst):
    """Lowest VDD from which the worst-case margin stays positive."""
    fails = np.where(worst < 0)[0]
    if len(fails) == 0:
        return vdd[0]
    if fails[-1] == len(vdd) - 1:
        return float("nan")
    return vdd[fails[-1] + 1]


def finish_plot(ax, fig, filename):
    ax.axhline(0, color="black", linewidth=0.8)
    ax.set_xlabel(r"$V_{DD}$ [V]")
    ax.set_ylabel("Worst-case margin to logic limit [mV]")
    ax.set_xlim(0.05, 0.8)
    ax.grid(alpha=0.3)
    ax.legend()
    fig.tight_layout()
    fig.savefig(filename, dpi=300)


# ---------------- Individual gates ----------------
def plot_gates():
    run = latest_run(GATE_TITLE)
    col = {n: i for i, n in enumerate(run["names"])}
    data = run["data"]
    vdd = data[:, col["sweep"]]

    inv = {"0": 1, "1": 0}
    nand = {"00": 1, "01": 1, "10": 1, "11": 0}
    nor = {"00": 1, "01": 0, "10": 0, "11": 0}

    # (label, node prefix, truth table, colour, line style)
    gates = [
        ("Inverter", "inv", inv, "C0", "-"),
        ("Inverter, NMOS-stacked", "invs", inv, "C0", "--"),
        ("Inverter, double-stacked", "invd", inv, "C0", ":"),
        ("NAND2", "nand", nand, "C1", "-"),
        ("NAND2, PMOS-stacked", "nandp", nand, "C1", "--"),
        ("NOR2", "nor", nor, "C2", "-"),
        ("NOR2, NMOS-stacked", "nors", nor, "C2", "--"),
    ]

    fig, ax = plt.subplots(figsize=FIGSIZE)
    print(f"Gates ({CORNER} corner):")
    for label, prefix, table, colour, style in gates:
        worst = np.min([margin(data[:, col[f"v({prefix}{inp})"]], vdd, out)
                        for inp, out in table.items()], axis=0)
        vmin = minimum_vdd(vdd, worst)
        print(f"  {label:26s} minimum VDD = {vmin:.2f} V")
        ax.plot(vdd, worst * 1000, color=colour, linestyle=style,
                label=f"{label} ({vmin:.2f} V)")
    finish_plot(ax, fig, f"gates_min_vdd_{CORNER}.png")


# ---------------- Full next-state logic ----------------
def plot_system():
    run = latest_run(SYSTEM_TITLE)
    col = {n: i for i, n in enumerate(run["names"])}
    data = run["data"]
    vdd = data[:, col["sweep"]]

    # (label, node prefix, colour)
    variants = [("Original", "", "C0"), ("Optimised", "o", "C3")]

    fig, ax = plt.subplots(figsize=FIGSIZE)
    print(f"System ({CORNER} corner):")
    for label, prefix, colour in variants:
        margins = []
        for k in range(16):
            a, b, t, h = (k >> 3) & 1, (k >> 2) & 1, (k >> 1) & 1, k & 1
            tag = f"{a}{b}{t}{h}"
            a_next = int(b and t and not h)
            b_next = int((not a) and (not h) and not (b and t))
            margins.append(margin(data[:, col[f"v({prefix}ap{tag})"]], vdd, a_next))
            margins.append(margin(data[:, col[f"v({prefix}bp{tag})"]], vdd, b_next))

        # Internal gate outputs (e.g. v(0110:nbt)) must also be valid logic levels
        internal = re.compile(rf"v\({prefix}\d{{4}}:[a-z0-9]+\)")
        for name in run["names"]:
            if internal.fullmatch(name):
                margins.append(margin(data[:, col[name]], vdd, None))

        worst = np.min(margins, axis=0)
        vmin = minimum_vdd(vdd, worst)
        print(f"  {label:10s} minimum VDD = {vmin:.2f} V")
        ax.plot(vdd, worst * 1000, color=colour, label=f"{label} ({vmin:.2f} V)")
    finish_plot(ax, fig, f"system_min_vdd_{CORNER}.png")


if __name__ == "__main__":
    plot_gates()
    plot_system()
    plt.show()