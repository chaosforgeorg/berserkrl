#version 120
attribute vec3 coord3d;
attribute vec2 texcoord;
attribute vec4 color;
varying vec2 f_texcoord;
varying vec4 f_color;
uniform mat4 m_transform;
 
void main(void) {
  gl_Position = m_transform * vec4(coord3d, 1.0);
  f_texcoord = texcoord;
  f_color    = vec4( color.rgb, 1.0 );
}
