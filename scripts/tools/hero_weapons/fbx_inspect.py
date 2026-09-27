#!/usr/bin/env python3
"""Minimal binary FBX (7.x) reader for the owner's hero weapon files: lists the models (meshes, bones, nulls), the
geometry sizes and bounds, the materials and the animation stacks, and can export each mesh's triangles (world-baked
with the node transforms) for previews and for turning a mesh into Roblox parts.

    python3 scripts/tools/hero_weapons/fbx_inspect.py <file.fbx> [...]

No Blender needed (numpy only). Supports what Blender's FBX exporter writes: Lcl Translation / Rotation (XYZ Euler,
degrees) / Scaling, PreRotation, GeometricTranslation, and parent links from Connections.
"""
import math
import struct
import sys
import zlib

import numpy as np


class Node:
    __slots__ = ("name", "props", "children")

    def __init__(self, name, props, children):
        self.name, self.props, self.children = name, props, children

    def find(self, name):
        for c in self.children:
            if c.name == name:
                return c
        return None

    def findall(self, name):
        return [c for c in self.children if c.name == name]


def _read_prop(data, pos):
    t = chr(data[pos])
    pos += 1
    if t == "Y":
        return struct.unpack_from("<h", data, pos)[0], pos + 2
    if t == "C":
        return bool(data[pos]), pos + 1
    if t == "I":
        return struct.unpack_from("<i", data, pos)[0], pos + 4
    if t == "F":
        return struct.unpack_from("<f", data, pos)[0], pos + 4
    if t == "D":
        return struct.unpack_from("<d", data, pos)[0], pos + 8
    if t == "L":
        return struct.unpack_from("<q", data, pos)[0], pos + 8
    if t in "fdlib":
        length, encoding, clen = struct.unpack_from("<III", data, pos)
        pos += 12
        raw = data[pos:pos + clen]
        pos += clen
        if encoding == 1:
            raw = zlib.decompress(raw)
        dtype = {"f": "<f4", "d": "<f8", "l": "<i8", "i": "<i4", "b": "u1"}[t]
        return np.frombuffer(raw, dtype=dtype, count=length), pos
    if t in "SR":
        length = struct.unpack_from("<I", data, pos)[0]
        pos += 4
        raw = data[pos:pos + length]
        pos += length
        return (raw.decode("utf-8", "replace") if t == "S" else raw), pos
    raise ValueError("unknown FBX property type %r at %d" % (t, pos - 1))


def _read_node(data, pos, wide):
    if wide:
        end, nprops, _plen = struct.unpack_from("<QQQ", data, pos)
        pos += 24
    else:
        end, nprops, _plen = struct.unpack_from("<III", data, pos)
        pos += 12
    namelen = data[pos]
    pos += 1
    if end == 0:
        return None, pos
    name = data[pos:pos + namelen].decode("ascii", "replace")
    pos += namelen
    props = []
    for _ in range(nprops):
        value, pos = _read_prop(data, pos)
        props.append(value)
    children = []
    null = 25 if wide else 13
    while pos < end:
        if end - pos == null:
            pos = end
            break
        child, pos = _read_node(data, pos, wide)
        if child is None:
            break
        children.append(child)
    return Node(name, props, children), end


def load(path):
    with open(path, "rb") as f:
        data = f.read()
    assert data[:20] == b"Kaydara FBX Binary  ", path + ": not a binary FBX"
    version = struct.unpack_from("<I", data, 23)[0]
    wide = version >= 7500
    pos = 27
    top = []
    while pos < len(data):
        node, pos = _read_node(data, pos, wide)
        if node is None:
            break
        top.append(node)
    return version, Node("root", [], top)


def props70(node):
    out = {}
    p = node.find("Properties70") if node else None
    for entry in (p.children if p else []):
        out[entry.props[0]] = entry.props[4:]
    return out


def euler_xyz(deg):
    rx, ry, rz = (math.radians(v) for v in deg)
    cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
    X = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]])
    Y = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    Z = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]])
    return Z @ Y @ X  # FBX eEulerXYZ: X first


def local_matrix(p):
    t = np.array(p.get("Lcl Translation", (0, 0, 0)), dtype=float)
    r = p.get("Lcl Rotation", (0, 0, 0))
    s = np.array(p.get("Lcl Scaling", (1, 1, 1)), dtype=float)
    pre = p.get("PreRotation", (0, 0, 0))
    m = np.eye(4)
    m[:3, :3] = euler_xyz(pre) @ euler_xyz(r) @ np.diag(s)
    m[:3, 3] = t
    return m


class Scene:
    def __init__(self, path):
        self.path = path
        self.version, root = load(path)
        objects = root.find("Objects")
        self.objects = {}
        for o in objects.children:
            if o.props and isinstance(o.props[0], int):
                self.objects[o.props[0]] = o
        self.parent = {}
        self.links = []
        conns = root.find("Connections")
        for c in (conns.children if conns else []):
            kind, child, parent = c.props[0], c.props[1], c.props[2]
            self.links.append((kind, child, parent, c.props[3] if len(c.props) > 3 else None))
            if kind == "OO" and child in self.objects and self.objects[child].name == "Model":
                self.parent[child] = parent
        settings = props70(root.find("GlobalSettings"))
        self.unit = settings.get("UnitScaleFactor", (1.0,))[0]
        self.up_axis = settings.get("UpAxis", (1,))[0]

    def name_of(self, oid):
        o = self.objects.get(oid)
        return o.props[1].split("\x00")[0] if o else "?"

    def world(self, oid):
        m = np.eye(4)
        chain = []
        while oid in self.objects and self.objects[oid].name == "Model":
            chain.append(oid)
            oid = self.parent.get(oid, 0)
        for mid in reversed(chain):
            m = m @ local_matrix(props70(self.objects[mid]))
        return m

    def models(self):
        return [(oid, o) for oid, o in self.objects.items() if o.name == "Model"]

    def children_of(self, oid, kind=None):
        return [c for k, c, p, _ in self.links if p == oid and (kind is None or self.objects.get(c) is not None
                                                               and self.objects[c].name == kind)]

    def geometry_of(self, model_id):
        for k, c, p, _ in self.links:
            if p == model_id and c in self.objects and self.objects[c].name == "Geometry":
                return self.objects[c]
        return None

    def materials_of(self, model_id):
        return [self.objects[c] for k, c, p, _ in self.links
                if p == model_id and c in self.objects and self.objects[c].name == "Material"]

    def mesh_triangles(self, model_id):
        """World-space triangles (N, 3, 3) of a mesh model, plus per-triangle material index."""
        geo = self.geometry_of(model_id)
        if geo is None or geo.find("Vertices") is None:
            return None, None
        verts = np.array(geo.find("Vertices").props[0], dtype=float).reshape(-1, 3)
        idx = np.array(geo.find("PolygonVertexIndex").props[0], dtype=np.int64)
        gp = props70(self.objects[model_id])
        geo_t = np.array(gp.get("GeometricTranslation", (0, 0, 0)), dtype=float)
        m = self.world(model_id)
        world = (m[:3, :3] @ (verts + geo_t).T).T + m[:3, 3]
        mats = None
        layer = geo.find("LayerElementMaterial")
        if layer is not None and layer.find("Materials") is not None:
            mats = np.array(layer.find("Materials").props[0], dtype=np.int64)
        tris, tri_mat = [], []
        poly, pi = [], 0
        for v in idx:
            if v < 0:
                poly.append(-v - 1)
                for k in range(1, len(poly) - 1):
                    tris.append((world[poly[0]], world[poly[k]], world[poly[k + 1]]))
                    tri_mat.append(int(mats[pi]) if mats is not None and len(mats) > pi else (int(mats[0]) if mats is not None and len(mats) else 0))
                poly = []
                pi += 1
            else:
                poly.append(v)
        return np.array(tris), np.array(tri_mat)


def material_color(material):
    p = props70(material)
    c = p.get("DiffuseColor") or p.get("Diffuse") or (0.8, 0.8, 0.8)
    return tuple(float(x) for x in c[:3])


def describe(path):
    sc = Scene(path)
    print("==", path.split("/")[-1], "FBX", sc.version, "unit", sc.unit, "up", sc.up_axis)
    counts = {}
    for oid, o in sc.models():
        kind = o.props[2] if len(o.props) > 2 else "?"
        counts[kind] = counts.get(kind, 0) + 1
    print("   models:", counts)
    for oid, o in sc.models():
        kind = o.props[2] if len(o.props) > 2 else "?"
        if kind == "Mesh":
            tris, _ = sc.mesh_triangles(oid)
            mats = [m.props[1].split("\x00")[0] + str(tuple(round(v, 2) for v in material_color(m))) for m in sc.materials_of(oid)]
            if tris is not None and len(tris):
                pts = tris.reshape(-1, 3)
                lo, hi = pts.min(0), pts.max(0)
                print(f"   mesh {sc.name_of(oid)!r} parent={sc.name_of(sc.parent.get(oid, 0))!r} tris={len(tris)} "
                      f"size={np.round(hi - lo, 3)} centre={np.round((hi + lo) / 2, 3)} mats={mats}")
    bones = [sc.name_of(oid) for oid, o in sc.models() if len(o.props) > 2 and o.props[2] == "LimbNode"]
    if bones:
        print("   bones:", len(bones), bones[:24])
    nulls = [sc.name_of(oid) for oid, o in sc.models() if len(o.props) > 2 and o.props[2] == "Null"]
    if nulls:
        print("   nulls:", nulls[:12])
    stacks = [o.props[1].split("\x00")[0] for o in sc.objects.values() if o.name == "AnimationStack"]
    curves = sum(1 for o in sc.objects.values() if o.name == "AnimationCurve")
    if stacks:
        print("   animation stacks:", stacks, "curves:", curves)
    videos = [o.props[1].split("\x00")[0] for o in sc.objects.values() if o.name == "Video"]
    if videos:
        print("   embedded/linked images:", videos)
    return sc


if __name__ == "__main__":
    for p in sys.argv[1:]:
        describe(p)
