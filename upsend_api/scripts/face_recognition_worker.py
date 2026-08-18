#!/usr/bin/env python3
"""
Face Recognition Worker

Prioritas utama: pakai library gratis yang paling akurat bila tersedia
(face_recognition), lalu fallback ke OpenCV agar tetap bisa berjalan.
"""
import json
import math
import sys
from pathlib import Path

import cv2
import numpy as np

try:
    import face_recognition
except Exception:
    face_recognition = None

# Cascade classifier untuk fallback
FACE_CASCADE_PATH = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
face_cascade = cv2.CascadeClassifier(FACE_CASCADE_PATH)


def normalize_vector(value):
    """Normalisasi reference candidate ke list angka float."""
    if value is None:
        return None

    if isinstance(value, dict):
        for key in ('embedding', 'encoding', 'vector', 'features'):
            if key in value:
                return normalize_vector(value[key])
        return None

    if isinstance(value, (list, tuple, np.ndarray)):
        arr = np.asarray(value, dtype=np.float32).ravel()
        if arr.size == 0:
            return None
        return arr.astype(float).tolist()

    return None


def get_largest_face(image):
    """Ambil wajah terbesar di frame, tetapi tolak bila lebih dari satu wajah terdeteksi."""
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    faces = face_cascade.detectMultiScale(
        gray,
        scaleFactor=1.15,
        minNeighbors=6,
        minSize=(60, 60),
    )

    if len(faces) == 0:
        raise ValueError('Tidak ada wajah terdeteksi pada gambar')

    if len(faces) > 1:
        raise ValueError('Hanya satu wajah yang diizinkan untuk absensi.')

    return max(faces, key=lambda rect: rect[2] * rect[3])


def align_face(image, face_rect):
    """Crop wajah dengan margin yang cukup dan ubah ukuran agar lebih stabil."""
    x, y, w, h = [int(v) for v in face_rect]
    margin_x = int(w * 0.25)
    margin_y = int(h * 0.35)

    x1 = max(0, x - margin_x)
    y1 = max(0, y - margin_y)
    x2 = min(image.shape[1], x + w + margin_x)
    y2 = min(image.shape[0], y + h + margin_y)

    face = image[y1:y2, x1:x2]
    face = cv2.resize(face, (256, 256), interpolation=cv2.INTER_LINEAR)
    gray = cv2.cvtColor(face, cv2.COLOR_BGR2GRAY)
    gray = cv2.equalizeHist(gray)
    return cv2.cvtColor(gray, cv2.COLOR_GRAY2RGB)


def fallback_embedding(image_path: str):
    """Fallback embedding untuk saat face_recognition tidak ada."""
    image = cv2.imread(image_path)
    if image is None:
        raise ValueError('Gagal membaca gambar')

    face_rect = get_largest_face(image)
    aligned = align_face(image, face_rect)

    gray = cv2.cvtColor(aligned, cv2.COLOR_BGR2GRAY)
    resized = cv2.resize(gray, (128, 128), interpolation=cv2.INTER_AREA)
    emb = resized.astype(np.float32) / 255.0
    emb = emb.reshape(-1)
    emb = emb / (np.linalg.norm(emb) + 1e-8)
    return emb.astype(float).tolist()


def extract_encoding(image_path: str):
    """Ekstrak embedding wajah. Prefer pakai face_recognition gratis bila ada."""
    if not Path(image_path).exists():
        raise FileNotFoundError(f'Gambar tidak ditemukan: {image_path}')

    if face_recognition is not None:
        image = face_recognition.load_image_file(image_path)
        locations = face_recognition.face_locations(image, model='hog')

        if len(locations) == 0:
            raise ValueError('Tidak ada wajah terdeteksi pada gambar')

        if len(locations) > 1:
            raise ValueError('Hanya satu wajah yang diizinkan untuk absensi.')

        encodings = face_recognition.face_encodings(
            image,
            known_face_locations=locations,
            num_jitters=5,
            model='small',
        )
        if not encodings:
            raise ValueError('Encoding wajah gagal dibuat')
        return encodings[0].astype(float).tolist()

    return fallback_embedding(image_path)


def cosine_distance(a, b):
    a = np.asarray(a, dtype=np.float32)
    b = np.asarray(b, dtype=np.float32)
    if a.size == 0 or b.size == 0:
        return 1.0
    norm_a = np.linalg.norm(a) + 1e-8
    norm_b = np.linalg.norm(b) + 1e-8
    similarity = float(np.dot(a, b) / (norm_a * norm_b))
    return 1.0 - max(min(similarity, 1.0), -1.0)


def verify_with_references(candidate_path: str, reference_payload):
    """Verifikasi candidate terhadap reference faces."""
    threshold = 0.32

    try:
        candidate_vector = extract_encoding(candidate_path)
    except Exception as exc:
        print(json.dumps({
            'matched': False,
            'best_distance': 1.0,
            'message': f'Gagal memproses foto kandidat: {str(exc)}',
        }))
        return

    references = []
    for ref in reference_payload:
        vector = normalize_vector(ref)
        if vector is not None:
            references.append(vector)

    if not references:
        print(json.dumps({
            'matched': False,
            'best_distance': 1.0,
            'message': 'Tidak ada reference embeddings yang ditemukan.',
        }))
        return

    distances = []
    for ref in references:
        distance = cosine_distance(candidate_vector, ref)
        distances.append(distance)

    best_distance = float(min(distances)) if distances else 1.0
    matched = bool(best_distance <= threshold)

    print(json.dumps({
        'matched': matched,
        'best_distance': best_distance,
        'threshold': threshold,
        'message': 'Wajah cocok dengan data yang terdaftar.' if matched else 'Wajah tidak cocok dengan data yang terdaftar.',
    }))


def main():
    if len(sys.argv) < 3:
        print(json.dumps({
            'status': 'error',
            'message': 'Missing arguments. Usage: python face_recognition_worker.py <mode> <image_path> [references_json]',
        }))
        raise SystemExit(1)

    mode = sys.argv[1]

    try:
        if mode == 'register':
            image_path = sys.argv[2]
            encoded = extract_encoding(image_path)
            print(json.dumps({
                'status': 'ok',
                'encoding': encoded,
                'message': 'Face encoding generated successfully.',
            }))
            return

        if mode == 'verify':
            candidate_path = sys.argv[2]
            references_payload = sys.argv[3] if len(sys.argv) > 3 else '[]'

            if Path(references_payload).exists():
                with open(references_payload, 'r', encoding='utf-8') as fh:
                    references = json.load(fh)
            else:
                references = json.loads(references_payload)

            verify_with_references(candidate_path, references)
            return

        print(json.dumps({
            'status': 'error',
            'message': f'Unknown mode: {mode}',
        }))
        raise SystemExit(1)

    except Exception as exc:
        print(json.dumps({
            'status': 'error',
            'message': str(exc),
        }))
        raise SystemExit(1)


if __name__ == '__main__':
    main()
