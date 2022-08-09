#version 120
varying vec2 f_texcoord;
varying vec4 f_color;
uniform sampler2D s_texture;
uniform vec4 overlay;
 
void main(void) {
	vec4 t = texture2D(s_texture, f_texcoord);
	if ( t.w < 0.01 )
		discard;
	if ( overlay.w > 0.01 )
		gl_FragColor = mix( t * vec4(f_color.xyz, 1.0), overlay, overlay.w );
	else
		gl_FragColor = t * vec4(f_color.xyz, 1.0);
}