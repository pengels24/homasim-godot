shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(0.95, 0.75, 0.05, 0.5);
uniform vec4 bg_color : source_color = vec4(0.1, 0.1, 0.1, 0.45);
uniform float line_width = 4.0;
uniform float line_gap = 8.0;
uniform float speed = 8.0;

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	// Diagonale Linien (45 Grad)
	float coord = local_pos.x + local_pos.y;
	
	// Bewegung
	coord -= TIME * speed;
	
	// Modulo for repeating pattern
	float period = line_width + line_gap;
	float m = mod(coord, period);
	
	if (m < line_width) {
		COLOR = line_color;
	} else {
		COLOR = bg_color;
	}
}
