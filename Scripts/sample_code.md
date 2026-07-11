Use a vertex shader for the throw arc
Here, add this to a flat quadmesh that is sudivided, and if it were me i would leave it as a permanent child of the player and just show/hide it.

<image>

shader_type spatial;
render_mode cull_disabled, unshaded;

uniform float height : hint_range(0.0, 5.0, 0.1) = 2.0;
uniform float curve : hint_range(1.0, 20, 0.5) = 13.0;
uniform float lengt = 10.0;

varying float dist;

void vertex() {
  // Add height and curve to flat quad mesh
  VERTEX.y += height - (VERTEX.z * VERTEX.z) / curve;

  // Make thinner at end
  VERTEX.x += VERTEX.x * 1.8 * VERTEX.z / lengt ;

  // Set varying for fade effect
  dist = VERTEX.z;
}

void fragment() {
  ALPHA = max(-dist / lengt + 0.3, 0.0);
  ALBEDO = vec3(1.0);
}
That 'curve' uniform value should be calculable based on the quadratic equation and the length of the mesh (lengt uniform), but I couldn't figure it out. So if someone wants to have a stab at it feel free.
