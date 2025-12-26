shader_type canvas_item;

// Controls the strength of the blur
uniform float blur_amount : hint_range(0.0, 5.0) = 2.0;
// Controls the tint color (e.g., white for frosted glass)
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 0.2);

// Uses Godot's built-in screen texture (what is behind this node)
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    // Read the screen texture with LOD (Level of Detail) to create blur
    vec4 color = textureLod(screen_texture, SCREEN_UV, blur_amount);
    // Mix the blurred background with our tint color
    COLOR = mix(color, tint_color, tint_color.a);
}