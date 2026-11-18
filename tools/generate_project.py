#!/usr/bin/env python3
"""Generate default.project.json for Brainrot Bay from the layout in
src/shared/Config.luau (mirrored here). Re-run after any layout change:

    python3 tools/generate_project.py

The project is a Rojo 7 project: src/server -> ServerScriptService.Server,
src/client -> StarterPlayerScripts.Client, src/shared -> ReplicatedStorage.
The 3D world (baseplate, belt, tunnels, eight bases, trees, lamps, the wave
wall) is declared here as plain parts so the place file carries it.
"""
import json

BASE_POSITIONS = [
    (-42, -120), (-42, -40), (-42, 40), (-42, 120),
    (42, -120), (42, -40), (42, 40), (42, 120),
]
BASE_COLORS = [
    (1.0, 0.35, 0.35), (0.35, 0.63, 1.0), (0.35, 0.86, 0.47), (1.0, 0.78, 0.23),
    (0.75, 0.43, 1.0), (1.0, 0.55, 0.78), (0.23, 0.86, 0.86), (1.0, 0.59, 0.23),
]


def part(name, size, pos, color, shape="Block", material="SmoothPlastic",
         anchored=True, transparency=0, can_collide=True, neon=False):
    props = {
        "Anchored": anchored,
        "CanCollide": can_collide,
        "Color": list(color),
        "Material": "Neon" if neon else material,
        "Position": list(pos),
        "Size": list(size),
        "Transparency": transparency,
    }
    if shape != "Block":
        props["Shape"] = shape
    return {"$className": "Part", "$properties": props}


def base_model(index, bx, bz, color):
    """One base plot: floor, back wall, two side walls, ten slot pads,
    a flag pole and a flag. The far side (away from the belt) gets the wall."""
    children = {}
    children["Pad"] = part("Pad", (28, 1, 28), (bx, 0.5, bz), color)
    back_x = bx - 13.5 if bx < 0 else bx + 13.5
    children["BackWall"] = part("BackWall", (1, 8, 28), (back_x, 4, bz), (0.85, 0.85, 0.9))
    for side, z in (("SideWallA", bz - 13.5), ("SideWallB", bz + 13.5)):
        children[side] = part(side, (28, 4, 1), (bx, 2, z), (0.85, 0.85, 0.9))
    # Ten slot pads: two rows of five, matching Config/BaseService math.
    for slot in range(1, 11):
        row = (slot - 1) // 5
        col = (slot - 1) % 5
        x = bx - 8 + col * 4
        z = bz - 4 + row * 8
        children[f"SlotPad{slot}"] = part(
            f"SlotPad{slot}", (4, 0.5, 4), (x, 1.25, z), (1, 1, 1),
            transparency=0.4)
    flag_x = bx + 12 if bx < 0 else bx - 12
    children["FlagPole"] = part("FlagPole", (0.6, 10, 0.6), (flag_x, 5, bz - 12), (0.3, 0.3, 0.35))
    children["Flag"] = part("Flag", (4, 2.5, 0.2), (flag_x + (2 if bx < 0 else -2), 9, bz - 12), color)
    return {"$className": "Model", **children}


def build():
    tree = {"$className": "DataModel"}

    # --- Services -------------------------------------------------------
    tree["ServerScriptService"] = {
        "Server": {"$path": "src/server"}
    }
    tree["StarterPlayer"] = {
        "StarterPlayerScripts": {
            "Client": {"$path": "src/client"}
        }
    }
    tree["ReplicatedStorage"] = {
        "Shared": {"$path": "src/shared"},
        "Remotes": {
            "$className": "Folder",
            **{
                name: {"$className": "RemoteEvent"}
                for name in ("BuyBrainrot", "StealBrainrot", "LockBase",
                             "SlapPlayer", "Rebirth", "StateSync",
                             "Notify", "WaveEvent")
            },
        },
    }
    tree["Lighting"] = {"$properties": {
        "Ambient": [0.25, 0.25, 0.3],
        "Brightness": 2,
        "ClockTime": 14,
        "GlobalShadows": True,
        "Technology": "Future",
        "Outlines": False,
    }}
    tree["SoundService"] = {"$properties": {"RespectFilteringEnabled": True}}

    # --- Workspace ------------------------------------------------------
    ws = {"$properties": {"FilteringEnabled": True}}
    ws["Baseplate"] = part("Baseplate", (512, 20, 512), (0, -10, 0), (0.35, 0.75, 0.35))
    # The belt: a raised walkway down the middle, yellow edges.
    ws["Belt"] = part("Belt", (16, 1, 350), (0, 0.5, 0), (0.75, 0.75, 0.8))
    ws["BeltEdgeL"] = part("BeltEdgeL", (1, 1.2, 350), (-8.5, 0.6, 0), (1.0, 0.8, 0.1))
    ws["BeltEdgeR"] = part("BeltEdgeR", (1, 1.2, 350), (8.5, 0.6, 0), (1.0, 0.8, 0.1))

    # Spawn tunnel (north) and exit portal (south).
    for name, z, color in (("SpawnTunnel", -185, (0.6, 0.4, 1.0)),
                           ("ExitPortal", 185, (1.0, 0.45, 0.2))):
        ws[name + "PillarL"] = part(name + "PillarL", (4, 16, 4), (-10, 8, z), color)
        ws[name + "PillarR"] = part(name + "PillarR", (4, 16, 4), (10, 8, z), color)
        ws[name + "Beam"] = part(name + "Beam", (24, 4, 4), (0, 17, z), color)

    # The eight bases.
    bases = {}
    for i, ((bx, bz), color) in enumerate(zip(BASE_POSITIONS, BASE_COLORS), start=1):
        bases[f"Base{i}"] = base_model(i, bx, bz, color)
    ws["Bases"] = {"$className": "Folder", **bases}

    # Trees around the edges.
    tree_positions = [(x, z) for x in (-75, 75) for z in (-160, -80, 0, 80, 160)]
    tree_positions += [(-30, 195), (30, 195)]
    for i, (x, z) in enumerate(tree_positions, start=1):
        ws[f"Tree{i}Trunk"] = part(f"Tree{i}Trunk", (2, 6, 2), (x, 3, z), (0.5, 0.35, 0.2))
        ws[f"Tree{i}Top"] = part(f"Tree{i}Top", (7, 7, 7), (x, 8.5, z), (0.25, 0.65, 0.3), shape="Ball")

    # Lamps along the belt.
    for i, (x, z) in enumerate(
            [(x, z) for x in (-14, 14) for z in (-150, -50, 50, 150)], start=1):
        ws[f"Lamp{i}Pole"] = part(f"Lamp{i}Pole", (0.8, 7, 0.8), (x, 3.5, z), (0.3, 0.3, 0.35))
        ws[f"Lamp{i}Head"] = part(f"Lamp{i}Head", (2, 1, 2), (x, 7.2, z), (1.0, 0.95, 0.6), neon=True)

    # Spawn point, near the south end by the exit portal.
    ws["SpawnLocation"] = {
        "$className": "SpawnLocation",
        "$properties": {
            "Anchored": True,
            "Color": [0.4, 0.8, 0.4],
            "Position": [0, 1, 205],
            "Size": [20, 1, 20],
            "Neutral": True,
            "Duration": 0,
        },
    }
    # The wave wall: parked off-map, transparent, until WaveService sweeps it.
    ws["WaveWall"] = part("WaveWall", (500, 40, 4), (0, 20, -260), (0.2, 0.5, 1.0),
                          transparency=1, can_collide=False, material="Glass")

    tree["Workspace"] = ws
    return {"name": "brainrot-bay", "tree": tree}


if __name__ == "__main__":
    project = build()
    with open("default.project.json", "w", encoding="utf-8") as f:
        json.dump(project, f, indent=2)
        f.write("\n")
    print("wrote default.project.json")
