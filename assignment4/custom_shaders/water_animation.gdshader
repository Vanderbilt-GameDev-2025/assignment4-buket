shader_type spatial;
render_mode specular_toon;

uniform sampler2D noise;
uniform sampler2D normalmap;

uniform float height_scale = 0.2;
uniform float wave_speed = 0.3;
uniform vec2 wave_direction = vec2(1.0, 0.0);

// Water shading
uniform vec3  water_base_color = vec3(0.1, 0.3, 0.5);
uniform float water_metallic   : hint_range(0.0, 0.5) = 0.0;
uniform float water_specular   : hint_range(0.0, 1.0) = 1.0;
uniform float water_roughness  : hint_range(0.0, 1.0) = 0.01;

// Directional light
uniform vec3 directional_light_color = vec3(1.0, 1.0, 1.0);
uniform vec3 directional_light_direction = vec3(0.0, -1.0, 0.0);

// Screen-space reflection
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float refraction_strength : hint_range(0.0, 1.0) = 0.05;
uniform float water_color_strength : hint_range(0.0, 20.0) = 10.0;

varying vec2 tex_position;

// A simple wave function that mixes sine with noise-based offset
float wave_func(vec2 pos, float t) {
    // Sample noise (~0..1)
    float n = texture(noise, pos / 10.0).r;
    // Offset the position by noise
    pos += (n - 0.5) * 2.0;

    // Basic sine wave: sin(x + y + time)
    float w = sin(pos.x + pos.y + t) * 0.5 + 0.5;
    return w;
}

void vertex() {
    vec2 p = VERTEX.xz;

    float t = TIME * wave_speed;
    float wave_val = wave_func(p + wave_direction * t, t) * height_scale;

    VERTEX.y += wave_val;

    // Finite difference for normals
    float eps = 0.1;
    float wave_dx = wave_val
        - (wave_func((p + vec2(eps, 0.0)) + wave_direction * t, t) * height_scale);
    float wave_dz = wave_val
        - (wave_func((p + vec2(0.0, eps)) + wave_direction * t, t) * height_scale);

    NORMAL = normalize(vec3(wave_dx, eps, wave_dz));

    tex_position = VERTEX.xz * 0.5 + 0.5;
}

void fragment() {
    // Blend normal map with dynamic NORMAL
    NORMAL_MAP = texture(normalmap, tex_position).xyz;
    NORMAL = normalize(mix(NORMAL, NORMAL_MAP, 0.01));
    vec3 norm = normalize(NORMAL);

    // Fresnel factor for viewing angles
    vec3 view_dir = normalize(VIEW);
    float fresnel = sqrt(1.0 - dot(norm, view_dir));

    // Directional light in view space
    vec3 light_view = normalize(VIEW_MATRIX * vec4(directional_light_direction, 0.0)).xyz;
    float diffuse = max(dot(norm, light_view), 0.0);

    // Base lit color: diffuse + slight fresnel tint
    vec3 water_lit = (water_base_color * directional_light_color * diffuse)
                     + (water_base_color * 0.1 * fresnel);

    // Screen-space reflection/refraction
    vec3 refract_color = texture(screen_texture, SCREEN_UV + (norm.xy * refraction_strength * 5.0)).rgb;
    vec3 final_color   = water_lit * refract_color * water_color_strength;

    // Set final color and properties
    ALBEDO    = final_color;
    METALLIC  = water_metallic;
    SPECULAR  = water_specular;
    ROUGHNESS = water_roughness * (1.0 - fresnel);
    RIM = 0.2;
}