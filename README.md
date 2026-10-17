# Tarnation: third-person 3D

Open project.godot in Godot 4 and press F5. Stop any running game first to load the changes.

- WASD: move relative to the direction you face (W forward, A left, S backward, D right).
- Arrow keys: swing the pole. Up swings downward; down swings upward; right swings right to left; left swings left to right. The matching cross arm turns red during the swing. Press again after the pole returns to rest for another swing.
- Mouse: turn the yellow character and rotate the perspective camera; look up and down. Camera rotation pauses while holding left-click to choose an attack.
- Space: jump.
- Quick left-click: thrust on release; the center circle turns red during the thrust.
- Hold left-click and drag: the pole swings in the swipe direction (right uses the left-arrow swing, left uses right, up uses down, and down uses up). The cross highlights the swing's starting side. Each press triggers one attack. Attacks finish before another can start.
- Escape: release the mouse. Click in the game to capture it again.

Uses Godot CharacterBody3D, gravity, BoxShape3D collisions, invisible solid boundaries, and a SpringArm3D camera that retracts near obstacles. The green arena has a flat floor enclosed by invisible boundaries.




The player is a simple all-yellow humanoid with a round head, walking limbs, and a jointed right arm that follows the held pole during swings and thrusts.
