# Voxel Tools 1.7 feasibility check (plan Task 2) — 2026-09-23

**Verdict: GO.** Voxel Tools GDExtension 1.7 (release `v1.7x`, zip sha256 `600737572a5e25541ba6f503e842a3717ba19afafa5474510a6ceff995a1d2d8`) works on Godot 4.7.2, desktop and the Android emulator.

| Check | Desktop (Linux, Mobile renderer) | Emulator (Android 15 x86_64, OpenGL fallback) |
|---|---|---|
| Terrain generates + renders around a moving viewer | yes | yes (screenshot taken, landscape 2400×1080) |
| `VoxelTool.set_voxel` → `get_voxel` | `get_voxel=2` | `get_voxel=2` |
| Edit persists across restart (VoxelStreamSQLite) | `persisted=2` on run 2 | `persisted=2` after `am force-stop` + relaunch |
| FPS flying at 8 m/s, view distance 128 | 60 (vsync), max frame 19.5 ms | 60, max frame 16.7 ms |
| `VoxelTerrainMultiplayerSynchronizer` class | present | present |

## Verified API (used by Tasks 4, 5, 11)
- `VoxelBlockyLibrary.models = [...]` (untyped Array) then `bake()`; model index == voxel id; `VoxelBlockyModelEmpty` for air.
- `VoxelBlockyModelCube.atlas_size_in_tiles`, `set_tile(side, Vector2i)`, `set_material_override(0, mat)`; material `vertex_color_use_as_albedo = true` for baked AO.
- `VoxelMesherBlocky.library`; `VoxelTerrain.mesher/generator/stream/max_view_distance`.
- `VoxelGeneratorScript._generate_block(out_buffer: VoxelBuffer, origin_in_voxels: Vector3i, lod: int)` and `_get_used_channels_mask()`.
- `VoxelBuffer.fill_area(value, min, max, channel)` — **max is exclusive**; `max == size` fills to the top safely.
- `VoxelTool.channel = VoxelBuffer.CHANNEL_TYPE`, `get_voxel(Vector3i)`, `set_voxel(Vector3i, int)`, `raycast(origin, dir, max_distance, collision_mask)` → `VoxelRaycastResult{position, previous_position, normal, distance}`.
- `VoxelStreamSQLite.database_path` must be a global path (`ProjectSettings.globalize_path`) and its directory must exist.
- `VoxelTerrain.save_modified_blocks()` (async), `is_area_meshed(AABB)`.

## Notes
- A GDScript generator is fast enough at view distance 128 on both targets.
- The emulator has Vulkan disabled (`~/.android/advancedFeatures.ini`), so it renders with Compatibility (OpenGL ES 3).
