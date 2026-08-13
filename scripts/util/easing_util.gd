






















































class_name EasingFunctions extends Node


const FLOAT_EPSILON: float = 1e-05


static func linear(start: float, end: float, value: float) -> float:
	return lerp(start, end, value)



static func spring(start: float, end: float, value: float) -> float:
	value = clampf(value, 0, 1)
	value = (sin(value * PI * (0.2 + 2.5 * value * value * value)) * pow(1 - value, 2.2) + value) * (1 + (1.2 * (1 - value)))
	return start + (end - start) * value



static func ease_in_quad(start: float, end: float, value: float) -> float:
	end -= start
	return end * value * value + start



static func ease_out_quad(start: float, end: float, value: float) -> float:
	end -= start
	return - end * value * (value - 2) + start



static func ease_in_out_quad(start: float, end: float, value: float) -> float:
	value /= 0.5
	end -= start

	if value < 1:
		return end * 0.5 * value * value + start

	value -= 1
	return - end * 0.5 * (value * (value - 2) - 1) + start



static func ease_in_cubic(start: float, end: float, value: float) -> float:
	end -= start
	return end * value * value * value + start



static func ease_out_cubic(start: float, end: float, value: float) -> float:
	value -= 1
	end -= start
	return end * (value * value * value + 1) + start



static func ease_in_out_cubic(start: float, end: float, value: float) -> float:
	value /= 0.5
	end -= start

	if value < 1:
		return end * 0.5 * value * value * value + start

	value -= 2
	return end * 0.5 * (value * value * value + 2) + start



static func ease_in_quart(start: float, end: float, value: float) -> float:
	end -= start
	return end * value * value * value * value + start



static func ease_out_quart(start: float, end: float, value: float) -> float:
	value -= 1
	end -= start
	return - end * (value * value * value * value - 1) + start



static func ease_in_out_quart(start: float, end: float, value: float) -> float:
	value /= 0.5
	end -= start

	if value < 1:
		return end * 0.5 * value * value * value * value + start

	value -= 2
	return - end * 0.5 * (value * value * value * value - 2) + start



static func ease_in_quint(start: float, end: float, value: float) -> float:
	end -= start
	return end * value * value * value * value * value + start



static func ease_out_quint(start: float, end: float, value: float) -> float:
	value -= 1
	end -= start
	return end * (value * value * value * value * value + 1) + start



static func ease_in_out_quint(start: float, end: float, value: float) -> float:
	value /= 0.5
	end -= start

	if value < 1:
		return end * 0.5 * value * value * value * value * value + start

	value -= 2
	return end * 0.5 * (value * value * value * value * value + 2) + start



static func ease_in_sine(start: float, end: float, value: float) -> float:
	end -= start
	return - end * cos(value * (PI * 0.5)) + end + start



static func ease_out_sine(start: float, end: float, value: float) -> float:
	end -= start
	return end * sin(value * (PI * 0.5)) + start



static func ease_in_out_sine(start: float, end: float, value: float) -> float:
	end -= start
	return - end * 0.5 * (cos(PI * value) - 1) + start



static func ease_in_expo(start: float, end: float, value: float) -> float:
	end -= start
	return end * pow(2, 10 * (value - 1)) + start



static func ease_out_expo(start: float, end: float, value: float) -> float:
	end -= start
	return end * ( - pow(2, -10 * value) + 1) + start



static func ease_in_out_expo(start: float, end: float, value: float) -> float:
	value /= 0.5
	end -= start

	if value < 1:
		return end * 0.5 * pow(2, 10 * (value - 1)) + start

	value -= 1
	return end * 0.5 * ( - pow(2, -10 * value) + 2) + start



static func ease_in_circ(start: float, end: float, value: float) -> float:
	end -= start
	return - end * (sqrt(1 - value * value) - 1) + start



static func ease_out_circ(start: float, end: float, value: float) -> float:
	value -= 1
	end -= start
	return end * sqrt(1 - value * value) + start



static func ease_in_out_circ(start: float, end: float, value: float) -> float:
	value /= 0.5
	end -= start

	if value < 1:
		return - end * 0.5 * (sqrt(1 - value * value) - 1) + start

	value -= 2
	return end * 0.5 * (sqrt(1 - value * value) + 1) + start



static func ease_in_bounce(start: float, end: float, value: float) -> float:
	end -= start
	const d: float = 1
	return end - ease_out_bounce(0, end, d - value) + start



static func ease_out_bounce(start: float, end: float, value: float) -> float:
	value /= 1
	end -= start

	if value < (1 / 2.75):
		return end * (7.5625 * value * value) + start

	if value < (2 / 2.75):
		value -= (1.5 / 2.75)
		return end * (7.5625 * (value) * value + 0.75) + start

	if value < (2.5 / 2.75):
		value -= (2.25 / 2.75)
		return end * (7.5625 * (value) * value + 0.9375) + start

	value -= (2.625 / 2.75)
	return end * (7.5625 * (value) * value + 0.984375) + start



static func ease_in_out_bounce(start: float, end: float, value: float) -> float:
	end -= start
	const d: float = 1

	if value < d * 0.5:
		return ease_in_bounce(0, end, value * 2) * 0.5 + start

	return ease_out_bounce(0, end, value * 2 - d) * 0.5 + end * 0.5 + start



static func ease_in_back(start: float, end: float, value: float) -> float:
	end -= start
	value /= 1
	const s: float = 1.70158
	return end * (value) * value * ((s + 1) * value - s) + start



static func ease_out_back(start: float, end: float, value: float) -> float:
	const s: float = 1.70158
	end -= start
	value -= 1
	return end * ((value) * value * ((s + 1) * value + s) + 1) + start



static func ease_in_out_back(start: float, end: float, value: float) -> float:
	var s: float = 1.70158
	end -= start
	value /= 0.5

	if (value) < 1:
		s *= 1.525
		return end * 0.5 * (value * value * (((s) + 1) * value - s)) + start

	value -= 2
	s *= 1.525
	return end * 0.5 * ((value) * value * (((s) + 1) * value + s) + 2) + start



static func ease_in_elastic(start: float, end: float, value: float) -> float:
	end -= start
	const d: float = 1
	const p: float = d * 0.3
	var s: float = 0
	var a: float = 0

	if absf(value) < FLOAT_EPSILON:
		return start

	value /= d
	if absf(value - 1) < FLOAT_EPSILON:
		return start + end

	if absf(a) < FLOAT_EPSILON || a < absf(end):
		a = end
		s = p / 4
	else:
		s = p / (2 * PI) * asin(end / a)

	value -= 1
	return - (a * pow(2, 10 * value) * sin((value * d - s) * (2 * PI) / p)) + start



static func ease_out_elastic(start: float, end: float, value: float) -> float:
	end -= start
	const d: float = 1
	const p: float = d * 0.3
	var s: float = 0
	var a: float = 0

	if abs(value) < FLOAT_EPSILON:
		return start

	value /= d
	if abs((value - 1) < FLOAT_EPSILON):
		return start + end

	if abs(a) < FLOAT_EPSILON || a < abs(end):
		a = end
		s = p * 0.25
	else:
		s = p / (2 * PI) * asin(end / a)

	return (a * pow(2, -10 * value) * sin((value * d - s) * (2 * PI) / p) + end + start)



static func ease_in_out_elastic(start: float, end: float, value: float) -> float:
	end -= start
	const d: float = 1
	const p: float = d * 0.3
	var s: float = 0
	var a: float = 0

	if abs(value) < FLOAT_EPSILON:
		return start;

	value /= d
	if (abs(value * 0.5) - 2) < FLOAT_EPSILON:
		return start + end

	if abs(a) < FLOAT_EPSILON || a < abs(end):
		a = end
		s = p / 4
	else:
		s = p / (2 * PI) * asin(end / a)

	if value < 1:
		value -= 1
		return -0.5 * (a * pow(2, 10 * value) * sin((value * d - s) * (2 * PI) / p)) + start

	value -= 1
	return a * pow(2, -10 * value) * sin((value * d - s) * (2 * PI) / p) * 0.5 + end + start
