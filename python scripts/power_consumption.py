import numpy as np
import matplotlib.pyplot as plt
from read_aimspice import read_runs

# ---------------- Settings ----------------
OUT_FILES = ["total_power_consumtion_stacked.out"]      # one or more AIM-Spice .out files
CORNER = "ff"                           # must match the end of the netlist title
INPUTS = "ideal"                        # "ideal" or "worst", as in the netlist title
TITLE = f"System static power stacked {INPUTS} - {CORNER}"
# Supplies to summarise: the chosen supply and the minimum from the VDD test
VDD_POINTS = {"Chosen": 0.55, "Minimum": 0.19}
PASSIVE = "0100"                        # A=0, B=1 (Passive), T=0, H=0

plt.rcParams.update({"font.size": 11})
FIGSIZE = (8, 4.5)


def latest_run(title):
    runs = [r for f in OUT_FILES for r in read_runs(f)
            if title in r["title"] and r["analysis"] == "DC Transfer Curves"]
    if not runs:
        raise ValueError(f"No DC sweep with title '{title}' found")
    return runs[-1]


run = latest_run(TITLE)
col = {name: i for i, name in enumerate(run["names"])}
data = run["data"]
vdd = data[:, col["sweep"]]
states = [format(k, "04b") for k in range(16)]          # ABTH

# (label, ammeter prefix, colour)
variants = [("Fully stacked", "vs", "C2")]

# Static power of each input state: P = VDD * I
power = {}
for label, prefix, _ in variants:
    current = np.array([data[:, col[f"i({prefix}{s})"]] for s in states])
    power[label] = current * vdd                          # shape (16, points)

# ---------------- Summary at each supply ----------------
summary = {}
for name, v_target in VDD_POINTS.items():
    i = int(np.argmin(np.abs(vdd - v_target)))
    print(f"Static power of the next-state logic at VDD = {vdd[i]:.2f} V "
          f"({name.lower()}, {CORNER} corner, {INPUTS} inputs)")
    print(f"{'ABTH':>6} " + " ".join(f"{label:>14}" for label, _, _ in variants))
    for k, s in enumerate(states):
        mark = "  <- passive" if s == PASSIVE else ""
        print(f"{s:>6} " + " ".join(f"{power[label][k, i] * 1e12:11.2f} pW"
                                    for label, _, _ in variants) + mark)
    for label, _, _ in variants:
        p = power[label][:, i]
        summary[(name, label)] = p[int(PASSIVE, 2)]
        print(f"{label:10s} passive: {p[int(PASSIVE, 2)] * 1e12:7.2f} pW   "
              f"average: {p.mean() * 1e12:7.2f} pW   "
              f"worst ({states[int(np.argmax(p))]}): {p.max() * 1e12:7.2f} pW")
    print()

# Passive-state power at the chosen supply versus the minimum supply
names = list(VDD_POINTS)
if len(names) == 2:
    high, low = names
    print(f"Passive-state power, {high.lower()} vs {low.lower()} supply:")
    for label, _, _ in variants:
        p_high, p_low = summary[(high, label)], summary[(low, label)]
        print(f"{label:10s} {p_high * 1e12:7.2f} pW at {VDD_POINTS[high]:.2f} V -> "
              f"{p_low * 1e12:7.2f} pW at {VDD_POINTS[low]:.2f} V "
              f"({p_high / p_low:.1f}x lower)")
    print()

# ---------------- Plot ----------------
fig, ax = plt.subplots(figsize=FIGSIZE)
for label, _, colour in variants:
    p = power[label] * 1e12
    ax.plot(vdd, p[int(PASSIVE, 2)], color=colour, linestyle="-",
            label=f"{label}, passive state")
    ax.plot(vdd, p.mean(axis=0), color=colour, linestyle="--",
            label=f"{label}, average of all states")
    ax.plot(vdd, p.max(axis=0), color=colour, linestyle=":",
            label=f"{label}, worst state")
for name, v_target in VDD_POINTS.items():
    ax.axvline(v_target, color="gray", linestyle=":", linewidth=0.8)
    ax.text(v_target + 0.005, 0.97, f"{name}: {v_target:.2f} V",
            transform=ax.get_xaxis_transform(), va="top", fontsize=9, color="gray")
ax.set_xlabel(r"$V_{DD}$ [V]")
ax.set_ylabel("Static power [pW]")
ax.set_yscale("log")
ax.set_xlim(0.1, vdd[-1])
ax.grid(alpha=0.3, which="both")
ax.legend(fontsize=9)
fig.tight_layout()
fig.savefig(f"system_power_stacked_{INPUTS}_{CORNER}.png", dpi=300)
plt.show()