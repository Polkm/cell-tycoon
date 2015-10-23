extern vec2 screen;
extern vec2 center;
extern float radius;
extern float zoom;
extern float rt;

float rand(vec2 co){
  return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 rgb2hsv(vec3 c) {
  vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
  vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

  float d = q.x - min(q.w, q.y);
  float e = 1.0e-10;
  return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float inGrid(float comp, float upscale) {
  if (mod(floor(comp * upscale), pow(floor(sqrt(zoom * 10)), 2) * 25) == 0) {
    return 0.1;
  } else if (mod(floor(comp * upscale), pow(floor(sqrt(zoom * 10)), 2) * 5) == 0) {
    return 0.05;
  } else if (mod(floor(comp * upscale), pow(floor(sqrt(zoom * 10)), 2)) == 0) {
    return 0.02;
  }
  return 0.0;
}

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
  float border = 400 * zoom;
  vec3 colorA = hsv2rgb(vec3(rt * 0.05, 0.3, 0.35));
  vec3 colorB = hsv2rgb(vec3(rt * 0.05 + 0.33, 0.3, 0.35));

  float a = length((center - (tc * screen))) / (radius * zoom);
  float griding = max(inGrid(tc.x - center.x / screen.x, screen.x), inGrid(tc.y - center.y / screen.y, screen.y));

  // Outer color
  vec2 stc = tc;
  float m = min(max(length(center - (stc * screen)) / screen.y, 0), 1);
  vec4 outer = vec4(mix(colorA, colorB, m), 1) * (rand(stc) * 0.02 + 0.9);
  outer = mix(outer, vec4(1, 1, 1, 1), (1 - tc.y) * 0.1);
  outer = mix(outer, vec4(1, 1, 1, 1), min(griding, 0.01));

  // Inner color
  stc.x = abs(tc.x - 0.5);
  if (griding > 0) {
    stc.y += 0.5 * griding;
  }
  m = min(max(length(center - (stc * screen)) / screen.y, 0), 1);
  vec4 inner = vec4(mix(colorA, colorB, m), 1) * (rand(stc) * 0.02 + 0.9);
  inner = mix(inner, vec4(0, 0, 0, 0), tc.y * 0.3);
  inner = mix(inner, vec4(1, 1, 1, 1), griding);

  float t = 0.0;
  if (a < 1)
    t = 1.0;
  else if (a >= 1)
    t = max(1 - (a - 1) * border, 0);

  return mix(outer, inner, t);
}
