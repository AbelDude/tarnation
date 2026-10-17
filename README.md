# Tarnation: third-person 3D

Open project.godot in Godot 4 and press F5. Stop any running game first to load the changes.

- WASD: move relative to the direction you face (W forward, A left, S backward, D right).
- Arrow keys: swing the pole. Up swings downward; down swings upward; right swings right to left; left swings left to right. The matching cross arm turns red during the swing. Press again after the pole returns to rest for another swing.
- Mouse: turn the yellow character and rotate the perspective camera; look up and down. Camera rotation pauses while holding left-click to choose an attack.
- Space: jump.
- Quick left-click: thrust on release; the center circle turns red during the thrust.
- Hold left-click and drag: the pole swings in the swipe direction (right uses the left-arrow swing, left uses right, up uses down, and down uses up). The cross highlights the swing's starting side. Each press triggers one attack. Attacks finish before another can start.
- Escape: release the mouse. Click in the game to capture it again.

Uses Godot CharacterBody3D, gravity, BoxShape3D collisions, invisible solid boundaries, and a SpringArm3D camera that retracts near obstacles. The green arena is a rolling valley enclosed by invisible boundaries. The player starts at its low center, with gentle slopes and rounded humps rising toward the edges.




The player is a simple all-yellow humanoid with a round head, walking limbs, and a jointed right arm that follows the held pole during swings and thrusts.
The terrain spans 500 x 500 horizontal units, bounded at X/Z = +/-250. The terrain has no grid overlay.

Ancient oak trees generate randomly each run at 5 per 25,000 square units (50 across the 500 x 500 world). Trees follow terrain elevation, vary slightly in scale and rotation, keep 12 units between trunks and clear of the starting point, and have solid trunk collisions. The source GLB is copied into assets/ancient-oak-swaying.glb.

Trees retain the Gentle_Oak_Breeze animation, looping with randomized playback speed and phase for natural sway.
Procedural pines form 25 random clusters (one per 10,000 square units), with a random 3-12 trees per cluster and nearest neighbors approximately 4.5-5.4 units apart. Each pine is 50% taller than the nominal scaled oak in the world (about 41.15 units), with trunks and crowns enlarged proportionally. Eight generated crown variants use layered irregular evergreen branches and tapered trunks. Pines follow the terrain, have trunk collisions, avoid oak trunks, and keep the starting area clear.

Oaks are scaled to a nominal 27.43 units tall, about 13 times the visible 2.11-unit person, retaining +/-15% random size variation. Trunk collisions scale with the tree. Pine height follows the nominal oak world height at a 1.5 ratio.


The terrain material blends irregular moss-green patches, brown soil, leaf-litter colors, and fine earthy grain; the ground has no grid lines.
assets/log-cabin.glb is a Blender-built cabin asset with a 7 x 8 unit main footprint, open interior, porch, entry ramp, and a 1.68 wide x 2.81 high doorway. Exported at 1:1 Godot scale. The current character was tested walking in and out using generated mesh collisions. The cabin is placed at the world center on a flat clearing that blends into the valley. The character spawns facing the entrance, 5 units in front of the doorway. Trees are kept outside a 28-unit clearing; the cabin uses mesh collisions with an open doorway.
