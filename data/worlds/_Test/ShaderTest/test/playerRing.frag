#version 120

uniform sampler2D iChannel0;
uniform float outline[360];
uniform vec2 center;
uniform float radius;

#include "shaders/logic.glsl"

float isbetween(float n, float min, float max)
{
  return and(ge(n,min),le(n,max));
}

//Do your per-pixel shader logic here.
void main()
{
	vec4 c = texture2D(iChannel0, gl_TexCoord[0].xy);
	gl_FragColor = c * gl_Color;

  highp int a = int(180 + degrees(atan(gl_FragCoord.y - center.y, gl_FragCoord.x - center.x)));
  float r = distance(gl_FragCoord.xy, center) - (radius + outline[a]);

  gl_FragColor.rgb = mix(gl_FragColor.rgb, vec3(1, 1, 0), isbetween(r, -4, 4));
}
