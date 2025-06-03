import os
import io
import base64
import random
import numpy as np
import cv2
from PIL import Image
from flask import Flask, request, jsonify
from flask_cors import CORS
from keras.src.utils import img_to_array
from tensorflow.keras.models import load_model

# === Load model ===
model = load_model('model_transfer_learning.h5')

# === Dataset & Class Mapping ===
root_dataset_dir = 'pre_process_data'
class_names = sorted(os.listdir(root_dataset_dir))
class_map = {idx: name for idx, name in enumerate(class_names)}
IMG_SIZE = (244, 244)

# === Load Class Meanings ===
meanings_dir = 'meanings'
class_meanings = {}
for class_name in class_names:
    meaning_file_path = os.path.join(meanings_dir, f"{class_name}.txt")
    if os.path.exists(meaning_file_path):
        with open(meaning_file_path, 'r', encoding='utf-8') as f:
            class_meanings[class_name] = f.read().strip()
    else:
        class_meanings[class_name] = "No meaning available."

# === Image Preprocessing Functions ===
def to_grayscale(img):
    return cv2.cvtColor((img * 255).astype(np.uint8), cv2.COLOR_RGB2GRAY)

def apply_clahe(gray_img):
    clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
    return clahe.apply(gray_img)

def denoise_image(img):
    img = (img * 255).astype(np.uint8)
    if len(img.shape) == 2 or img.shape[2] == 1:
        img = cv2.cvtColor(img, cv2.COLOR_GRAY2RGB)
    return cv2.fastNlMeansDenoisingColored(img, None, 10, 10, 7, 21)

def sharpen_image(img):
    kernel = np.array([[0, -1, 0],
                       [-1, 5, -1],
                       [0, -1, 0]])
    return cv2.filter2D(img, -1, kernel)

def boost_contrast(gray_img):
    return cv2.equalizeHist(gray_img)

def random_flip(img):
    if random.random() > 0.5:
        return np.fliplr(img)
    return img

def preprocess_image(image_path=None, image_pil=None, augment=False, to_gray=False):
    if image_path:
        img = Image.open(image_path).convert('RGB').resize(IMG_SIZE)
    else:
        img = image_pil.convert('RGB').resize(IMG_SIZE)

    img = img_to_array(img) / 255.0

    if augment:
        img = random_flip(img)

    if to_gray:
        img = to_grayscale(img)
        img = apply_clahe(img)
        img = boost_contrast(img)
        img = cv2.cvtColor(img, cv2.COLOR_GRAY2RGB)

    img = denoise_image(img)
    img = sharpen_image(img)
    img = img.astype(np.float32) / 255.0

    return np.expand_dims(img, axis=0), img

# === Flask App Setup ===
app = Flask(__name__)
CORS(app)  # Allow cross-origin requests from frontend

@app.route('/predict', methods=['POST'])
def predict():
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400

    try:
        image_file = request.files['image']
        augment = request.form.get('augment', 'false').lower() == 'true'
        to_gray = request.form.get('to_gray', 'false').lower() == 'true'

        image_pil = Image.open(image_file)
        processed_image, processed_np = preprocess_image(image_pil=image_pil, augment=augment, to_gray=to_gray)

        prediction = model.predict(processed_image)
        predicted_class_index = int(np.argmax(prediction))
        predicted_class = class_map[predicted_class_index]
        confidence = float(np.max(prediction))
        class_meaning = class_meanings.get(predicted_class, "No meaning available.")

        # Convert preprocessed image to base64
        processed_np_uint8 = (processed_np * 255).astype(np.uint8)
        processed_img_pil = Image.fromarray(processed_np_uint8)
        buffered = io.BytesIO()
        processed_img_pil.save(buffered, format="JPEG")
        processed_base64 = base64.b64encode(buffered.getvalue()).decode('utf-8')

        return jsonify({
            'predicted_class': predicted_class,
            'confidence': confidence,
            'meaning': class_meaning,
            'preprocessed_image_base64': processed_base64
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
