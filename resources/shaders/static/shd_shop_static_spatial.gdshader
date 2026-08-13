// Smoke for the shop cubes
// Look in code for credits
// Shader by lunarcleint, your good to use this on anything without credit

shader_type spatial;

#define PI 3.1415926535897932384626433832795

uniform float bars_amount = 14;
uniform float stretch_x = 1.0;
uniform float squash_x = 1.0;

uniform vec3 base_color : source_color;
uniform float speed = 1.0;
uniform float contrast = 1.0;
uniform float emission = 1.0;

/*
	Noise code from: https://stegu.github.io/webgl-noise/webdemo/
	
	Author : Ian McEwan, Ashima Arts.
    License : Copyright (C) 2011 Ashima Arts. All rights reserved.
              Distributed under the MIT License. See LICENSE file.
              https://github.com/ashima/webgl-noise
              https://github.com/stegu/webgl-noise
*/
vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
    return mod289(((x * 34.0) + 10.0) * x);
}

vec4 taylorInvSqrt(vec4 r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(vec3 v) {
    const vec2 C = vec2(1.0 / 6.0, 1.0 / 3.0);
    const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);

    vec3 i = floor(v + dot(v, C.yyy));
    vec3 x0 = v - i + dot(i, C.xxx);

    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min(g.xyz, l.zxy);
    vec3 i2 = max(g.xyz, l.zxy);

    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy;
    vec3 x3 = x0 - D.yyy;

    i = mod289(i);
    vec4 p = permute(permute(permute(
                i.z + vec4(0.0, i1.z, i2.z, 1.0)) +
            i.y + vec4(0.0, i1.y, i2.y, 1.0)) +
        i.x + vec4(0.0, i1.x, i2.x, 1.0));

    float n_ = 0.142857142857;
    vec3 ns = n_ * D.wyz - D.xzx;

    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);

    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_);

    vec4 x = x_ * ns.x + ns.yyyy;
    vec4 y = y_ * ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);

    vec4 b0 = vec4(x.xy, y.xy);
    vec4 b1 = vec4(x.zw, y.zw);

    vec4 s0 = floor(b0) * 2.0 + 1.0;
    vec4 s1 = floor(b1) * 2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));

    vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

    vec3 p0 = vec3(a0.xy, h.x);
    vec3 p1 = vec3(a0.zw, h.y);
    vec3 p2 = vec3(a1.xy, h.z);
    vec3 p3 = vec3(a1.zw, h.w);

    vec4 norm = taylorInvSqrt(vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;

    vec4 m = max(0.5 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
    m = m * m;
    return 105.0 * dot(m * m, vec4(dot(p0, x0), dot(p1, x1),
        dot(p2, x2), dot(p3, x3)));
}

float color(vec2 xy) {
    return 0.7 * snoise(vec3(xy, 0.076 * TIME * speed));
}

vec3 fullnoise(vec2 fragCoord) {
    vec2 p = (fragCoord.xy) * 2.0 - 1.0;

    vec3 xyz = vec3(p, 0);

    vec2 step = vec2(1.3, 1.7);
    float n = color(xyz.xy);
    n += 0.5 * color(xyz.xy * 2.0 - step);
    n += 0.25 * color(xyz.xy * 4.0 - 2.0 * step);
    n += 0.125 * color(xyz.xy * 8.0 - 3.0 * step);
    n += 0.0625 * color(xyz.xy * 16.0 - 4.0 * step);
    n += 0.03125 * color(xyz.xy * 32.0 - 5.0 * step);

    return vec3(0.5 + 0.5 * vec3(n, n, n));
}

/*
	Rotation code from: https://gist.github.com/ayamflow/c06bc0c8a64f985dd431bd0ac5b557cd
	
	Author: @ayamflow (https://gist.github.com/ayamflow)
*/
vec2 rotateUV(vec2 uv, float rotation)
{
    float mid = 0.5;
    return vec2(
        cos(rotation) * (uv.x - mid) + sin(rotation) * (uv.y - mid) + mid,
        cos(rotation) * (uv.y - mid) - sin(rotation) * (uv.x - mid) + mid
    );
}

vec3 adjustContrast(vec3 color, float value) {
  return 0.5 + value * (color - 0.5);
}

void fragment() {
	vec4 regular_color = vec4(vec3(1.0), 1.0);
	
	vec2 reg_uv = UV * vec2(squash_x, 1.0);
	
	vec2 distort_uv = rotateUV(reg_uv, 0.65 - (sin(TIME / 6.0) * 0.3));
	vec3 noise = fullnoise(distort_uv);
	distort_uv = mix(distort_uv, noise.zy, 0.2);
	distort_uv = mix(distort_uv, rotateUV(noise.xy, 0.3) * 0.2, 0.3);
	
	vec3 noise_two = fullnoise(distort_uv / 3.0) * 1.5;
	distort_uv = mix(distort_uv, noise_two.xy, 0.4);
	
	distort_uv *= vec2(stretch_x, stretch_x);
	
	float pattern = abs(cos(distort_uv.x * bars_amount * PI));
	regular_color.rgb = mix(vec3(0.3), vec3(0.0), pattern);
	
	for (int i = 0; i < 1; i++) {
		float pattern = step(0.5, fract((distort_uv.x + (0.008 * float(i))) * bars_amount));
		regular_color.rgb = mix(regular_color.rgb, regular_color.rgb + mix(vec3(0.04), vec3(0.0), pattern), 0.6);
	}
	
	for (int i = 0; i < 2; i++) {
		float pattern = step(0.5, fract((distort_uv.x + 0.01 + (0.008 * float(i))) * bars_amount));
		regular_color.rgb = mix(regular_color.rgb, regular_color.rgb + mix(vec3(1.0), vec3(0.0), pattern), 0.2);
	}
	
	for (int i = 0; i < 2; i++) {
		float pattern = step(0.5, fract((distort_uv.x + 0.02 + (0.008 * float(i))) * bars_amount));
		regular_color.rgb = mix(regular_color.rgb, regular_color.rgb + mix(vec3(1.0), vec3(0.0), pattern), 0.1);
	}
	
	for (int i = 0; i < 1; i++) {
		float pattern = abs(cos((distort_uv.x + (0.003 * float(i))) * bars_amount * PI));
		regular_color.rgb = mix(regular_color.rgb, regular_color.rgb + mix(vec3(1.0), vec3(0.0), pattern), 0.5);
	}
	
	regular_color.rgb *= base_color * 0.75;
	regular_color.rgb += base_color * 0.5;
	
	regular_color.rgb = adjustContrast(regular_color.rgb, contrast);
	
	ALBEDO = regular_color.rgb;
	ALPHA = regular_color.a;
	
	EMISSION = regular_color.rgb * emission;
}