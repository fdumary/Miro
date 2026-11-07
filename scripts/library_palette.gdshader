shader_type canvas_item;
// Applies only to new Kenney scenery, never to Julia's characters or tiles.
void fragment() {
	vec4 sample_color = texture(TEXTURE, UV);
	float value = dot(sample_color.rgb, vec3(0.299, 0.587, 0.114));
	vec3 color = vec3(0.153, 0.153, 0.267);
	if (value > 0.16) color = vec3(0.286, 0.302, 0.494);
	if (value > 0.36) color = vec3(0.545, 0.427, 0.612);
	if (value > 0.56) color = vec3(0.776, 0.624, 0.647);
	if (value > 0.76) color = vec3(0.949, 0.827, 0.671);
	if (value > 0.92) color = vec3(0.984, 0.961, 0.937);
	COLOR = vec4(color, sample_color.a);
}
