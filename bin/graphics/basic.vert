#version 330
layout( location = 0 ) in vec3 position;
layout( location = 1 ) in vec2 texcoord;
layout( location = 2 ) in vec4 color;

out vec2 otexcoord;
out vec4 ocolor;

uniform mat4 utransform;
 
void main(void)
{
  gl_Position = utransform * vec4(position, 1.0);
  otexcoord = texcoord;
  ocolor    = vec4( color.rgb, 1.0 );
}
