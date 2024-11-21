import numpy as np
import math
import dlib
import cv2
import simpleaudio
import time
'''
ランドマーク座標: https://ibug.doc.ic.ac.uk/resources/facial-point-annotations/
'''

# 入力された座標(x or y)に対して定数を以て変換する二次関数
def make_enlarge_delta(src, scale, max_scale):
	return (scale - 1) / abs(1-max_scale)**(1/2) * abs(src-max_scale)*(1/2) + 1


def make_maxarea_ellipse(landmark, max_scale):
	ellipse = cv2.fitEllipse(landmark)
	(p, q), (a, b), _ = ellipse		# 楕円のパラメタを代入
	r = 0
	if a > b:
		r = a
	else:
		r = b
	r = r / 2 * max_scale	# 直径を半径にするための割る2
	def calc_ellipse(x, y):
		eq1 = (x - p)**2 + (y - q)**2 - r**2
		return eq1

	return calc_ellipse


def make_ellipse_parameter(landmark):
	ellipse = cv2.fitEllipse(landmark)
	(p, q), (a, b), _ = ellipse		# 楕円のパラメタを代入
	r = 0
	if a > b:
		r = a
	else:
		r = b
	r /= 2
	return np.array([p, q, r])


def current_position(cur, ellipse_param):
	p, q, r = ellipse_param
	x = cur[0] - p
	y = cur[1] - q
	intersection = x*r/math.sqrt(x**2+y**2)
	return x / intersection		# landmarkを1としたときの現在の位置を返す


def eye_enlarge(map_x, map_y, points, rate):
	scale = 1/(1 + rate*4/1000)
	max_scale = 1.4		# 変形可能な最大範囲を決めるパラメタ, 複数回の試行によって適切な値を取る
	center_x, center_y, r = make_ellipse_parameter(points)
	max_ellipse = make_maxarea_ellipse(points, max_scale)
	h, w = map_x.shape
	for i in range(h):
		for j in range(w):
			if max_ellipse(j, i) <= 0:
				cur = current_position((j, i), (center_x, center_y, r))
				delta = make_enlarge_delta(cur, scale, max_scale)
				map_x[i, j] = center_x + (j - center_x) * delta
				map_y[i, j] = center_y + (i - center_y) * delta
	return map_x, map_y


def main():
	# 画像の読み込み
	image = cv2.imread("input.jpg", 1)
	h, w =  image.shape[:2]

	# TODO: 目の拡大を行う処理
	map_x, map_y = np.meshgrid(np.arange(w), np.arange(h))
	map_x = map_x.astype(np.float32)
	map_y = map_y.astype(np.float32)

	# dlibの顔検出器とランドマーク予測器のロード
	detector = dlib.get_frontal_face_detector()
	predictor = dlib.shape_predictor('shape_predictor_68_face_landmarks.dat')

	# グレースケール
	gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

	# 顔を検出
	faces = detector(gray)
	for face in faces:	# 複数人の顔から1人ずつ取り出している
		landmarks = predictor(gray, face)

		# 左目と右目のランドマーク座標を取得
		left_eye_landmarks = np.array([(landmarks.part(i).x, landmarks.part(i).y) for i in range(36, 42)]).astype(np.float32)
		right_eye_landmarks = np.array([(landmarks.part(i).x, landmarks.part(i).y) for i in range(42, 48)]).astype(np.float32)
		mouth_landmarks = np.array([(landmarks.part(i).x, landmarks.part(i).y) for i in range(49, 60)]).astype(np.float32)

		map_x, map_y = eye_enlarge(map_x, map_y, left_eye_landmarks, 40)
		map_x, map_y = eye_enlarge(map_x, map_y, right_eye_landmarks, 40)
		image = cv2.remap(image, map_x, map_y, cv2.INTER_CUBIC, borderMode=cv2.BORDER_TRANSPARENT)

	cv2.imwrite('output.jpg', image)


if __name__ == '__main__':
	start = time.perf_counter()
	main()
	end = time.perf_counter()
	print(f"{(end-start)/60:.0f}:{((end-start)%60):.2f}")
	wav_obj = simpleaudio.WaveObject.from_wave_file("notification.wav")
	play_obj = wav_obj.play()
	play_obj.wait_done()