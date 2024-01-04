#version 120
in vec2 otexcoord;
in vec4 ocolor;

uniform sampler2D utexture;
uniform vec4      uoverlay;
 
void main(void)
{
	vec4 t = texture2D( utexture, otexcoord);
	if ( t.w < 0.01 )
		discard;
	if ( uoverlay.w > 0.01 )
		gl_FragColor = mix( t * vec4(ocolor.xyz, 1.0), uoverlay, uoverlay.w );
	else
		gl_FragColor = t * vec4(ocolor.xyz, 1.0);
}