shader_type spatial;
//this is the most current cell shader that we have
group_uniforms Shader.Albedo;
uniform vec4 albedo_color : source_color  = vec4(1.0);
uniform sampler2D albedo_texture;

group_uniforms Shader.Light;
uniform bool use_stepped = true;
uniform float steps = 1.0;
uniform float step_smoothness : hint_range(0.0, 1.0, 0.05) = 0;
uniform vec4 shadow_tint : source_color;
uniform float shadow_tint_amount : hint_range(0.0, 1.0, 0.1) = 0.4;

group_uniforms Shader.Specular;
uniform float specular : hint_range(0.0, 1.0, 0.05) = 0.0;

group_uniforms Shader.Normal;
uniform float normal_strength : hint_range(0.0, 1.0, 0.05) = 0.0;
uniform sampler2D normal_texture;

uniform vec4 diffuse_color : source_color = vec4(1.0);

varying vec4 node_position;

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}



float shape_value(float value, vec2 uv, vec2 screen_size){
	float aspect = screen_size.y / screen_size.x;
	return aspect;
}

void vertex() {
	 node_position = (PROJECTION_MATRIX * vec4(NODE_POSITION_VIEW, 1.0));
}

void fragment() {
	vec4 albedo = texture(albedo_texture, UV) * albedo_color;
	vec4 normal_map = texture(normal_texture, UV);

	ALBEDO = albedo.rgb;

	NORMAL_MAP = mix(vec3(0.5,0.5,1.0), normal_map.rgb, normal_strength);

	SPECULAR = specular;
}

void light () {
	float ndotl = clamp(dot(NORMAL,LIGHT),0.0,1.0) * ATTENUATION;

	float light = ndotl;

	if(use_stepped){
		float light_mult = light * steps;
		float step_base = floor(light_mult);
		float light_factor = light_mult - step_base;

		light_factor = smoothstep(0.5 - step_smoothness, 0.5 + step_smoothness, light_factor);
		light = (step_base + light_factor) / steps;
	}


	vec3 diffuse = vec3(light) * (LIGHT_COLOR / PI);
	diffuse = (shadow_tint.rgb * (1.0 - (light)) * shadow_tint_amount) + diffuse * light;
	if(false){
		diffuse +=diffuse_color.rgb ;
	}

	DIFFUSE_LIGHT += diffuse;
	SPECULAR_LIGHT += vec3(pow(light, 50.0)) * specular;
}