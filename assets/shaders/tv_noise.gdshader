shader_type canvas_item;

uniform float noise_amount : hint_range(0.0, 1.0) = 0.5;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    // Add time to the seed to animate the noise
    float r = rand(uv + vec2(TIME * 0.1, TIME * -0.3));
    float g = rand(uv + vec2(TIME * -0.2, TIME * 0.1));
    float b = rand(uv + vec2(TIME * 0.3, TIME * -0.2));
    
    // Grayscale noise for TV static
    float noise = (r + g + b) / 3.0;
    
    vec4 tex_color = texture(TEXTURE, uv);
    // Mix the noise fully opaque
    COLOR = vec4(vec3(noise * 0.3), 1.0);
}
