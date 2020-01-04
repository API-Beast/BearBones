shader_type canvas_item;
render_mode blend_mix;

uniform vec4 evenColor : hint_color;
uniform vec4 oddColor : hint_color;
uniform vec4 gridColor : hint_color;
uniform vec4 outlineColor : hint_color;
uniform vec2 rectSize = vec2(100, 100);
uniform vec2 virtualSize = vec2(100, 100);
uniform vec2 checkersSize = vec2(16, 16);
uniform vec2 anchor = vec2(0, 0);
uniform vec2 gridSize = vec2(16, 16);
uniform bool drawGrid = false;

void fragment()
{	
	vec4 col = texture(TEXTURE, UV);
	
	vec2 pos = ((UV.xy - (anchor / virtualSize)) / checkersSize * virtualSize);
	bool is_even = mod(floor(pos.x) + floor(pos.y), 2.0) == 0.0;
	vec3 bg_color = is_even ? evenColor.rgb : oddColor.rgb;

	if(drawGrid)
	{
		vec2 coord = (UV.xy - (anchor / virtualSize)) / gridSize * virtualSize;
		vec2 grid = fract(coord) / fwidth(coord);
		float line = 1.0 - min(grid.x, grid.y);
		bg_color = mix(bg_color, gridColor.rgb, float(line > 0.0) * gridColor.a * clamp(1.0 / length(virtualSize / (gridSize * 40.0)), 0.4, 1.0));
	}

	COLOR = vec4(mix(bg_color, col.rgb, col.a), 1.0);
}