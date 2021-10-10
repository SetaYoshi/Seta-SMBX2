#version 120

uniform sampler2D iChannel0;
uniform float x;
uniform float y;
uniform float w;
uniform float h;

//Do your per-pixel shader logic here.

void main()
{
  vec2 xy = gl_TexCoord[0].xy;
  gl_FragColor = texture2D(iChannel0, xy)*gl_Color;

  gl_FragColor.rgb = vec3(1 - gl_FragColor.r, 1 - gl_FragColor.g, 1 - gl_FragColor.b);
}
