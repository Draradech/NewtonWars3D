shader_type spatial;
render_mode unshaded;

uniform vec3 color : source_color;
uniform float full_length;
uniform float fade_length;
varying float vz;

void vertex() {
	vz = VERTEX.z;
}

void fragment() {
	ALBEDO = color;
	ALPHA = clamp((vz - (full_length / 2.0 - fade_length)) / fade_length, 0.0, 1.0);
}
