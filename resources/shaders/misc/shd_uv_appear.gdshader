// Recreation of effect on notepad with movement
// Look in code for credits
// Shader by lunarcleint, your good to use this on anything without credit

shader_type spatial;
render_mode unshaded, cull_disabled;

#define PI 3.1415926535897932384626433832795
#define TWO_PI (PI * 2.0)

uniform sampler2D sprite_texture : source_color;
uniform float appear_progress : hint_range(0.0, 1.0) = 1.0;

const int SAMPLES = 12;

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
    return 0.7 * snoise(vec3(xy, 0.3 * TIME));
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

// Function from: https://tsev.dev/posts/2020-06-19-colour-correction-with-webgl/
vec3 adjustContrast(vec3 color, float value) {
  return 0.5 + value * (color - 0.5);
}

void fragment() {
	vec3 noise = fullnoise(UV);
	vec2 slight_wavy = UV + (noise.zz * 0.00798);
	
    vec4 tex = texture(sprite_texture, slight_wavy);
	tex.r += texture(sprite_texture, slight_wavy + noise.xy * 0.002).r * 0.85;
	tex.b += texture(sprite_texture, slight_wavy + noise.xy * 0.002).b * 0.85;
	
	vec3 redify = mix(
		vec3(230.0 / 255.0, 103.0 / 255.0, 141.0 / 255.0),
		vec3(1.0),
		0.4
	);
	redify *= 1.0 - ((noise.x + noise.y + noise.z) / 3.0);
	tex.rgb += tex.rgb * redify;
	
	tex.rgb *= mix(
		vec3(237.0 / 255.0, 62.0 / 255.0, 62.0 / 255.0),
		vec3(1.0),
		0.225
	);
	
	vec3 blueify = mix(
		vec3(0.0 / 255.0, 236.0 / 255.0, 255.0 / 255.0),
		vec3(1.0),
		0.51
	);
	
	float blur_alpha = 0.0;
	
	float degree = 33.3333 + sin(TIME) * 40.0 + cos(TIME * 0.35) * 10.0;
	float spread_x = max(0.423, 0.9 + (sin(TIME) * 0.4) + sin(TIME * 2.0) * 0.463);
	float spread_y = max(0.423, 0.65 + (sin(TIME) * 0.3) + sin(TIME * 2.0) * 0.263);
	
	float circ_x = cos(TIME) * 0.004 + sin(TIME * 0.43+ 1.3) * 0.005;
	float circ_y = sin(TIME) * 0.006;
	
	for(float i = -float(SAMPLES) / 2.0; i < float(SAMPLES) / 2.0; i++) {
		float local_spread_x = spread_x + (noise.y * 0.4) + (float(i) * 0.03);
		float local_spread_y = spread_y + (noise.x * 0.4) + (float(i) * 0.03);
		
		float skewer_x = circ_x + sin((degree / 360.0) * TWO_PI) * float(i) * 0.0035 * local_spread_x;
		float skewer_y = circ_y + cos((degree / 360.0) * TWO_PI) * float(i) * 0.0035 * local_spread_y;
		
		skewer_x += noise.x * (0.02 * 0.654);
		skewer_y += noise.y * (0.02 * 0.12);
		skewer_y += noise.x * (0.02 * 0.654);
		skewer_x += noise.z * (0.04 * 0.12);
		
		vec4 sample = texture(sprite_texture, UV + vec2(skewer_x, skewer_y));
		
		if (sample.r > 0.0) {
			tex.rgb += sample.rgb * blueify * 0.015;
			blur_alpha += sample.a * 0.075;
		}
	}
	
	ALBEDO = tex.rgb * 1.4;
	ALPHA = min((tex.a * ((noise.x + noise.y + noise.z) / 3.0)) + blur_alpha, 1.0);
	
	vec3 appear_noise = adjustContrast(noise.rgb, 1.3);
	ALPHA *= mix(((appear_noise.z + appear_noise.y) / 2.0) * appear_progress, 1.0, appear_progress);
}