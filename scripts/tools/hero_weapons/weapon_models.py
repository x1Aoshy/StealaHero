#!/usr/bin/env python3
"""Authors the 7 hero weapon models (low-poly Roblox toy style, parts only: no mesh upload) and writes
assets/hero_weapons/weapon_models.json, which scripts/steps/post_hero_weapons.luau turns into the melee Tools.

Every model is authored in GRIP SPACE, the frame of the character's RightGripAttachment (what Tool.Grip is relative
to): origin at the grip point (the fingertip face of the fist), +Y out of the top of the fist (a bat's barrel),
-Z forward past the knuckles (the forearm lies along +Z), +X to the character's right. In the Animator's tool-hold
pose +Y is up and -Z is forward. The two-handed clips (Pole_Strike, Mjolnir_Slam) put the left hand at about
(0, -0.65, 0.15): the pole's and the hammer's handles run down there.

Each part: name, shape (Block / Cylinder / Ball / Wedge), size, cframe (12 CFrame components in grip space), palette
(-> colour + material, like HeroWeaponTools.materialByPalette), section (HeroWeaponTools sections: Handle, Rubber /
Extend stretch along the Handle's +Y, Fist / Tip ride the stretch by StretchLength). Exactly one part per model has
handle = true; the Tool.Grip is derived from it.

Run:  python3 scripts/tools/hero_weapons/weapon_models.py [--render]
"""
import json
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from rig import ROOT, angles, cf, rot_x, rot_y, rot_z  # noqa: E402

OUT = os.path.join(ROOT, "assets", "hero_weapons", "weapon_models.json")

# palette -> (RGB, material). Materials follow HeroWeaponTools.materialByPalette (metals Metal, energy Neon).
PALETTES = {
    "shield_red": ((196, 28, 36), "SmoothPlastic"),
    "shield_white": ((238, 240, 246), "SmoothPlastic"),
    "shield_blue": ((22, 52, 148), "SmoothPlastic"),
    "silver": ((196, 202, 212), "Metal"),
    "leather": ((104, 64, 38), "SmoothPlastic"),
    "leather_dark": ((70, 42, 26), "SmoothPlastic"),
    "hero_red": ((204, 30, 34), "SmoothPlastic"),
    "gold": ((255, 190, 40), "Metal"),
    "web_red_cloth": ((206, 30, 40), "SmoothPlastic"),
    "web_blue_cloth": ((28, 68, 172), "SmoothPlastic"),
    "web_neon": ((236, 248, 255), "Neon"),
    "steel_dark": ((38, 40, 46), "Metal"),
    "bat_black": ((24, 24, 28), "SmoothPlastic"),
    "bat_yellow": ((255, 212, 40), "SmoothPlastic"),
    "bakugo_green": ((66, 82, 58), "SmoothPlastic"),
    "bakugo_orange": ((255, 124, 20), "SmoothPlastic"),
    "gold_energy": ((255, 150, 40), "Neon"),
    "cartridge_brass": ((214, 160, 60), "Metal"),
    "hammer_forged": ((128, 134, 146), "Metal"),
    "hammer_edge": ((176, 182, 194), "Metal"),
    "hammer_inlay": ((88, 94, 106), "Metal"),
    "lightning": ((150, 220, 255), "Neon"),
    "rubber_skin": ((250, 200, 158), "SmoothPlastic"),
    "rubber_shade": ((226, 168, 128), "SmoothPlastic"),
}


def unit(v):
    v = np.asarray(v, dtype=float)
    return v / np.linalg.norm(v)


class Model:
    def __init__(self, weapon_id, display_name, description):
        self.weapon_id = weapon_id
        self.display_name = display_name
        self.description = description
        self.parts = []

    def add(self, name, shape, size, frame, palette, section="Handle", handle=False, **extra):
        assert palette in PALETTES, palette
        part = {
            "name": name,
            "shape": shape,
            "size": [round(float(s), 4) for s in size],
            "cframe": [round(float(c), 5) for c in list(frame[:3, 3]) + list(frame[:3, :3].reshape(9))],
            "palette": palette,
            "section": section,
        }
        if handle:
            part["handle"] = True
        part.update(extra)
        self.parts.append(part)
        return part

    def block(self, name, size, pos, palette, rot=None, **kw):
        return self.add(name, "Block", size, cf(*pos, rot=rot), palette, **kw)

    def ball(self, name, diameter, pos, palette, **kw):
        return self.add(name, "Ball", (diameter, diameter, diameter), cf(*pos), palette, **kw)

    def cylinder(self, name, diameter, length, pos, axis, palette, spin=0.0, **kw):
        """A Cylinder part (Roblox cylinders run along their local X) whose axis points along `axis`."""
        x = unit(axis)
        helper = np.array([0.0, 1.0, 0.0]) if abs(x[1]) < 0.9 else np.array([0.0, 0.0, 1.0])
        z = unit(np.cross(x, helper))
        y = np.cross(z, x)
        rot = np.column_stack([x, y, z]) @ rot_x(spin)
        return self.add(name, "Cylinder", (length, diameter, diameter), cf(*pos, rot=rot), palette, **kw)

    def right_triangle(self, name, right, a, b, thickness, palette, **kw):
        """A WedgePart filling the right triangle (right, a, b); the right angle is at `right`."""
        right, a, b = (np.asarray(p, dtype=float) for p in (right, a, b))
        ey = unit(a - right)  # WedgePart: right angle at (0, -sy/2, +sz/2), +Y leg up the back, -Z leg along the bottom
        ez = -unit(b - right)
        ex = np.cross(ey, ez)
        sy, sz = np.linalg.norm(a - right), np.linalg.norm(b - right)
        centre = right + ey * sy / 2 - ez * sz / 2
        return self.add(name, "Wedge", (thickness, sy, sz), cf(*centre, rot=np.column_stack([ex, ey, ez])), palette, **kw)

    def triangle(self, name, p1, p2, p3, thickness, palette, **kw):
        """Any flat triangle as two WedgeParts (split at the foot of the altitude onto the longest edge)."""
        pts = [np.asarray(p, dtype=float) for p in (p1, p2, p3)]
        edges = [(0, 1, 2), (1, 2, 0), (2, 0, 1)]
        i, j, k = max(edges, key=lambda e: np.linalg.norm(pts[e[1]] - pts[e[0]]))
        a, b, apex = pts[i], pts[j], pts[k]
        d = unit(b - a)
        foot = a + d * np.dot(apex - a, d)
        self.right_triangle(name + "A", foot, apex, a, thickness, palette, **kw)
        self.right_triangle(name + "B", foot, apex, b, thickness, palette, **kw)

    def to_json(self):
        handles = [p for p in self.parts if p.get("handle")]
        assert len(handles) == 1, self.weapon_id + " needs exactly one handle"
        return {
            "WeaponId": self.weapon_id,
            "DisplayName": self.display_name,
            "Description": self.description,
            "Parts": self.parts,
        }


def ring_points(radius, count, phase_deg, centre, plane="xy"):
    pts = []
    for n in range(count):
        a = math.radians(phase_deg + 360.0 * n / count)
        if plane == "xy":
            pts.append((centre[0] + radius * math.cos(a), centre[1] + radius * math.sin(a), centre[2]))
    return pts


def star(model, name, centre, outer, inner, thickness, palette, **kw):
    """A flat five-point star facing +-Z: five point triangles + a round centre."""
    tips = ring_points(outer, 5, 90, centre)
    valleys = ring_points(inner, 5, 90 + 36, centre)
    for n in range(5):
        model.triangle(f"{name}Point{n + 1}", tips[n], valleys[n - 1], valleys[n], thickness, palette, **kw)
    model.cylinder(name + "Core", inner * 2.02, thickness, centre, (0, 0, 1), palette, **kw)


# ------------------------------------------------------------------------------------------------------------------
# 1. Captain America's shield (the starter "Bat"): frontal bash / mid-range throw -> Dazed
# ------------------------------------------------------------------------------------------------------------------
def cap_shield():
    m = Model("CapShield", "Cap's Shield", "Bash rivals and leave them seeing stars!")
    m.block("Strap", (0.24, 0.92, 0.2), (0, 0, -0.1), "leather", handle=True)
    m.block("StrapTop", (0.9, 0.16, 0.12), (0, 0.46, -0.2), "leather_dark")
    m.block("StrapBottom", (0.9, 0.16, 0.12), (0, -0.46, -0.2), "leather_dark")
    d = 3.0
    m.cylinder("Back", d * 0.97, 0.1, (0, 0, -0.3), (0, 0, 1), "silver")
    rings = [("RimRed", d, "shield_red"), ("RingWhite", d * 0.8, "shield_white"), ("RingRed", d * 0.6, "shield_red"),
             ("CentreBlue", d * 0.4, "shield_blue")]
    for n, (name, diameter, palette) in enumerate(rings):
        m.cylinder(name, diameter, 0.14, (0, 0, -0.4 - 0.045 * n), (0, 0, 1), palette)
    front = -0.4 - 0.045 * (len(rings) - 1) - 0.07
    star(m, "Star", (0, 0, front - 0.03), d * 0.19, d * 0.075, 0.06, "shield_white")
    return m


# ------------------------------------------------------------------------------------------------------------------
# 2. Goku's Power Pole (Forest Bat): long-range thrust, extends -> SpinTornado
# ------------------------------------------------------------------------------------------------------------------
POLE_EXTEND = 4.6


def power_pole():
    m = Model("PowerPole", "Power Pole", "Extend! A long-range thrust that spins rivals like a top!")
    m.cylinder("Grip", 0.36, 1.5, (0, 0, 0), (0, 1, 0), "hero_red", handle=True)
    m.cylinder("ButtCap", 0.46, 0.38, (0, -0.94, 0), (0, 1, 0), "gold")
    m.cylinder("ButtRing", 0.52, 0.08, (0, -0.72, 0), (0, 1, 0), "gold")
    m.cylinder("Shaft", 0.36, POLE_EXTEND, (0, POLE_EXTEND / 2, 0), (0, 1, 0), "hero_red", section="Extend")
    tip = POLE_EXTEND + 0.14
    m.cylinder("TipCap", 0.46, 0.38, (0, tip, 0), (0, 1, 0), "gold", section="Tip", StretchLength=POLE_EXTEND)
    m.cylinder("TipRing", 0.52, 0.08, (0, tip - 0.22, 0), (0, 1, 0), "gold", section="Tip", StretchLength=POLE_EXTEND)
    return m


# ------------------------------------------------------------------------------------------------------------------
# 3. Spider-Man's web shooter (Desert Bat): ranged web -> Webbed
# ------------------------------------------------------------------------------------------------------------------
def web_shooter():
    m = Model("WebShooter", "Web Shooter", "Thwip! Webs rivals to the floor where they stand!")
    z = 0.62  # around the wrist (the forearm starts at z = 0.3)
    m.block("Cuff", (1.14, 1.14, 0.52), (0, 0, z), "web_red_cloth", handle=True)
    for n, dz in enumerate((-0.2, 0.2)):
        m.block(f"Stripe{n + 1}", (1.17, 1.17, 0.07), (0, 0, z + dz), "web_blue_cloth")
    m.block("Housing", (0.52, 0.2, 0.44), (0, 0.66, z - 0.02), "silver")
    m.cylinder("Nozzle", 0.18, 0.42, (0, 0.72, z - 0.36), (0, 0, 1), "silver")
    m.ball("NozzleTip", 0.14, (0, 0.72, z - 0.58), "web_neon")
    m.block("Trigger", (0.16, 0.1, 0.16), (0, 0.8, z + 0.08), "web_red_cloth")
    for n, sx in enumerate((-1, 1)):
        m.cylinder(f"Cartridge{n + 1}", 0.22, 0.34, (sx * 0.64, 0.24, z), (0, 0, 1), "silver")
    # a small black spider on the back of the wrist (the cuff's -Y face shows in the tool-hold pose)
    m.block("SpiderBody", (0.16, 0.05, 0.3), (0, -0.595, z), "steel_dark")
    for n, (sx, dz) in enumerate(((-1, -0.08), (1, -0.08), (-1, 0.08), (1, 0.08))):
        m.block(f"SpiderLeg{n + 1}", (0.3, 0.04, 0.04), (sx * 0.14, -0.595, z + dz), "steel_dark",
                rot=rot_y(sx * (25 if dz < 0 else -25)))
    return m


# ------------------------------------------------------------------------------------------------------------------
# 4. Batman's batarang (Lake Bat): ranged throw -> SmokeStun
# ------------------------------------------------------------------------------------------------------------------
def batarang():
    m = Model("Batarang", "Batarang", "A ranged throw that bursts into a smoke cloud!")
    zc, t = 0.15, 0.1
    m.block("Tail", (0.2, 0.62, t), (0, 0.08, zc), "bat_black", handle=True)
    m.block("Body", (0.28, 0.62, t), (0, 0.66, zc), "bat_black", section="Blade")
    for sx in (-1, 1):
        s = "R" if sx > 0 else "L"
        m.triangle(f"Ear{s}", (sx * 0.02, 0.96, zc), (sx * 0.14, 0.96, zc), (sx * 0.1, 1.13, zc), t, "bat_black",
                   section="Blade")
        top = (sx * 0.13, 0.97, zc)
        outline = [(sx * 1.22, 1.1, zc), (sx * 0.96, 0.66, zc), (sx * 0.78, 0.8, zc), (sx * 0.56, 0.5, zc),
                   (sx * 0.38, 0.64, zc), (sx * 0.13, 0.36, zc)]
        for n in range(len(outline) - 1):
            m.triangle(f"Wing{s}{n + 1}", top, outline[n], outline[n + 1], t, "bat_black", section="Blade")
    m.cylinder("Emblem", 0.34, t + 0.03, (0, 0.72, zc), (0, 0, 1), "bat_yellow", section="Blade")
    return m


# ------------------------------------------------------------------------------------------------------------------
# 5. Bakugo's grenade gauntlet (Jungle Bat): frontal blast -> ExplosionBlast
# ------------------------------------------------------------------------------------------------------------------
def bakugo_gauntlet():
    m = Model("BakugoGauntlet", "Grenade Gauntlet", "BOOM! A frontal blast that throws rivals back!")
    m.cylinder("Body", 1.5, 1.5, (0, 0, 0.5), (0, 0, 1), "bakugo_green", handle=True)
    for n, z in enumerate((-0.12, 0.5, 1.12)):
        m.cylinder(f"Rib{n + 1}", 1.62, 0.12, (0, 0, z), (0, 0, 1), "steel_dark")
    m.cylinder("FrontCap", 1.24, 0.32, (0, 0, -0.38), (0, 0, 1), "steel_dark")
    m.cylinder("NozzleRing", 0.86, 0.2, (0, 0, -0.6), (0, 0, 1), "bakugo_orange")
    m.cylinder("NozzleCore", 0.52, 0.12, (0, 0, -0.7), (0, 0, 1), "gold_energy")
    # the pin on top and the orange grip bands of the grenade
    m.block("Lever", (0.26, 0.14, 1.1), (0, 0.8, 0.46), "silver")
    m.cylinder("PinRing", 0.42, 0.07, (0, 0.95, -0.02), (1, 0, 0), "silver")
    m.cylinder("PinHole", 0.24, 0.09, (0, 0.95, -0.02), (1, 0, 0), "bakugo_green")
    for sx in (-1, 1):
        s = "R" if sx > 0 else "L"
        m.block(f"Band{s}", (0.08, 0.6, 0.9), (sx * 0.76, 0, 0.5), "bakugo_orange")
        m.block(f"Cross{s}1", (0.07, 0.14, 0.62), (sx * 0.8, 0, 0.5), "steel_dark", rot=rot_x(38))
        m.block(f"Cross{s}2", (0.07, 0.14, 0.62), (sx * 0.8, 0, 0.5), "steel_dark", rot=rot_x(-38))
    return m


# ------------------------------------------------------------------------------------------------------------------
# 6. Thor's Mjolnir (Snow Bat and Cosmic Bat): overhead slam -> Electrocuted
# ------------------------------------------------------------------------------------------------------------------
def mjolnir():
    m = Model("Mjolnir", "Mjolnir", "Slam it down and electrocute every rival!")
    m.cylinder("Grip", 0.32, 2.3, (0, 0.05, 0), (0, 1, 0), "leather", handle=True)
    for n, y in enumerate((-0.7, -0.25, 0.2, 0.65)):
        m.cylinder(f"Wrap{n + 1}", 0.36, 0.07, (0, y, 0), (0, 1, 0), "leather_dark")
    m.cylinder("Pommel", 0.44, 0.22, (0, -1.18, 0), (0, 1, 0), "hammer_edge")
    m.cylinder("Lanyard", 0.34, 0.08, (0, -1.44, 0), (1, 0, 0), "leather_dark")
    m.cylinder("Neck", 0.44, 0.24, (0, 1.28, 0), (0, 1, 0), "hammer_edge")
    head_y = 1.94
    m.block("Head", (1.02, 1.02, 1.62), (0, head_y, 0), "hammer_forged")
    for sz in (-1, 1):
        s = "F" if sz < 0 else "B"
        m.block(f"Face{s}", (1.14, 1.14, 0.22), (0, head_y, sz * 0.84), "hammer_edge")
        m.block(f"FaceInset{s}", (0.8, 0.8, 0.06), (0, head_y, sz * 0.97), "hammer_forged")
    for sx in (-1, 1):
        s = "R" if sx > 0 else "L"
        m.cylinder(f"Rune{s}", 0.62, 0.04, (sx * 0.52, head_y, 0), (1, 0, 0), "hammer_inlay")
        m.cylinder(f"RuneCore{s}", 0.3, 0.06, (sx * 0.53, head_y, 0), (1, 0, 0), "hammer_edge")
    m.block("Cap", (0.9, 0.06, 1.4), (0, head_y + 0.52, 0), "hammer_edge")
    return m


# ------------------------------------------------------------------------------------------------------------------
# 7. Luffy's Gum-Gum fist (Volcano Bat): Gomu Gomu no Pistol -> CleanKnockback
# ------------------------------------------------------------------------------------------------------------------
GOMU_RUBBER = 1.35  # HeroWeaponTools.SetGomuTime moves the Fist by (stretch - 1) * 1.35


def gomu_fist():
    m = Model("GomuFist", "Gum-Gum Fist", "Gomu Gomu no... PISTOL! Sends rivals flying back!")
    # HeroWeaponTools.gripRotations.GomuFist: the stretch runs along the Handle's +Y = grip -Z (past the knuckles)
    stretch_rot = rot_x(-90)

    def along(y, x=0.0, z=0.0):
        return tuple(stretch_rot @ np.array([x, y, z]))

    m.add("Cuff", "Block", (1.1, 0.42, 1.1), cf(*along(0.0), rot=stretch_rot), "hero_red", handle=True)
    m.add("Rubber", "Cylinder", (GOMU_RUBBER, 0.56, 0.56), cf(*along(GOMU_RUBBER / 2), rot=stretch_rot @ rot_z(90)),
          "rubber_skin", section="Rubber")
    fist_y = GOMU_RUBBER + 0.55
    m.add("Fist", "Block", (1.24, 1.02, 1.12), cf(*along(fist_y), rot=stretch_rot), "rubber_skin", section="Fist")
    for n in range(4):
        x = -0.45 + 0.3 * n
        # palm down: knuckles along the top-front edge, the curled fingers on the front face below them
        m.add(f"Knuckle{n + 1}", "Block", (0.26, 0.2, 0.24), cf(*along(fist_y + 0.54, x, 0.3), rot=stretch_rot),
              "rubber_skin", section="Fist")
        m.add(f"Finger{n + 1}", "Block", (0.25, 0.08, 0.5), cf(*along(fist_y + 0.53, x, -0.16), rot=stretch_rot),
              "rubber_shade", section="Fist")
    m.add("Thumb", "Block", (0.62, 0.26, 0.26), cf(*along(fist_y + 0.58, -0.3, -0.4), rot=stretch_rot),
          "rubber_skin", section="Fist")
    m.add("Wristband", "Block", (1.3, 0.2, 1.18), cf(*along(fist_y - 0.52), rot=stretch_rot), "hero_red",
          section="Fist")
    return m


MODELS = [cap_shield, power_pole, web_shooter, batarang, bakugo_gauntlet, mjolnir, gomu_fist]


def main():
    data = {
        "Format": 1,
        "Space": "RightGripAttachment (grip) space: +Y out of the top of the fist, -Z past the knuckles, +X right",
        "Palettes": {k: {"Color": list(v[0]), "Material": v[1]} for k, v in PALETTES.items()},
        "Weapons": [build().to_json() for build in MODELS],
    }
    with open(OUT, "w", newline="\n") as f:
        json.dump(data, f, indent=1)
        f.write("\n")
    for w in data["Weapons"]:
        print(f"{w['WeaponId']:15s} {len(w['Parts']):3d} parts")
    if "--render" in sys.argv:
        import render_weapons
        render_weapons.main(data)


if __name__ == "__main__":
    main()
