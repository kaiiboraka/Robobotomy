shader_type spatial;
render_mode cull_disabled, unshaded;

uniform float line_length = 10.0;

varying float dist;

void vertex() {
    dist = UV.x; // UV.x stores normalized distance along line
}

void fragment() {
    float base_fade_in_start = 0.2;
    float base_fade_in_end = 0.5;

    float min_fade_in_start = 0.2; // Minimum start (20% down the line)
    float min_fade_in_end = 0.25; // Minimum end (25% down the line)

    float base_fade_out_start = 4.0;
    float base_fade_out_end = 0.0;

    float fade_in_start = base_fade_in_start;
    float fade_in_end = base_fade_in_end;
    float fade_in_power = 1.0;

    float fade_out_start = line_length - base_fade_out_start;
    float fade_out_end = line_length - base_fade_out_end;
    float fade_out_power = 1.0;

    if (line_length < 3.0) {
        float t = clamp(line_length / 3.0, 0.0, 1.0);

        // Adjusts the fade-in as the line gets shorter
        fade_in_start = mix(min_fade_in_start, base_fade_in_start, t);
        fade_in_end = mix(min_fade_in_end, base_fade_in_end, t);
        fade_in_power = mix(2.0, 1.0, t);

        // Adjusts the fade-out as the line gets shorter
        fade_out_start = mix(line_length * 0.3, line_length - base_fade_out_start, t);
        fade_out_end = line_length;
        fade_out_power = mix(0.5, 1.0, t);
    }

    float alpha_in = smoothstep(fade_in_start, fade_in_end, dist);
    alpha_in = pow(alpha_in, fade_in_power);

    float alpha_out = 1.0 - smoothstep(fade_out_start, fade_out_end, dist);
    alpha_out = pow(alpha_out, fade_out_power);

    ALPHA = alpha_in * alpha_out;
    ALBEDO = vec3(1.0);
}