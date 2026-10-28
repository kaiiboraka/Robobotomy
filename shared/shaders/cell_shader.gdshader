shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D main_texture : source_color, hint_default_white;
uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float steps : hint_range(1.0, 8.0) = 3.0;

void fragment() {
	vec4 tex_color = texture(main_texture, UV);
	ALBEDO = tex_color.rgb * albedo_color.rgb;
}

void light() {
	float ndotl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION;
	float toon = floor(ndotl * steps) / steps;

	DIFFUSE_LIGHT += LIGHT_COLOR * toon;
}