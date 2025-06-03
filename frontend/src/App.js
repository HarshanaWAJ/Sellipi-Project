import React, { useState } from 'react';
import 'bootstrap/dist/css/bootstrap.min.css';
import './App.css';

function App() {
  const [image, setImage] = useState(null);
  const [preview, setPreview] = useState('');
  const [prediction, setPrediction] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setImage(file);
      setPreview(URL.createObjectURL(file));
      setPrediction(null); // Reset previous prediction
    }
  };

  const handleSubmit = async () => {
    if (!image) return;

    setLoading(true);
    setPrediction(null);

    const formData = new FormData();
    formData.append('image', image);
    formData.append('augment', 'false');
    formData.append('to_gray', 'false');

    try {
      const response = await fetch('http://localhost:5000/predict', {
        method: 'POST',
        body: formData
      });

      const data = await response.json();
      console.log(data);
      

      if (response.ok) {
        setPrediction(data);
      } else {
        console.error('Prediction failed:', data.error);
        alert(`Prediction failed: ${data.error}`);
      }
    } catch (error) {
      console.error('Network error:', error);
      alert('Network error. Is your backend running?');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="container py-5">
      <div className="text-center">
        <h2 className="mb-4">Image Classification</h2>

        <div className="mb-3">
          <input
            type="file"
            accept="image/*"
            onChange={handleImageChange}
            className="form-control w-50 mx-auto"
          />
        </div>

        <button
          className="btn btn-primary"
          onClick={handleSubmit}
          disabled={!image || loading}
        >
          {loading ? 'Processing...' : 'Predict'}
        </button>
      </div>

      {preview && (
        <div className="text-center mt-5">
          <h4>Original Image</h4>
          <img src={preview} alt="Uploaded" className="img-thumbnail mt-2" width="300" />
        </div>
      )}

      {prediction && (
        <div className="mt-5">
          <div className="card shadow-sm">
            <div className="card-body">
              <h4 className="card-title text-center">Prediction Results</h4>
              <p className="card-text text-center">
                <strong>Class:</strong> {prediction.predicted_class} <br />
                <strong>Confidence:</strong> {(prediction.confidence * 100).toFixed(2)}%
              </p>

              {prediction.meaning && (
                <div className="mt-3">
                  <h5 className="text-center">Meaning</h5>
                  <div
                    className="text-muted mx-auto"
                    style={{
                      maxWidth: '800px',
                      whiteSpace: 'pre-line',
                      textAlign: 'justify',
                      lineHeight: '1.6',
                      backgroundColor: '#f8f9fa',
                      padding: '15px',
                      borderRadius: '5px',
                      border: '1px solid #dee2e6'
                    }}
                  >
                    {prediction.meaning}
                  </div>
                </div>
              )}

              {prediction.preprocessed_image_base64 && (
                <div className="text-center mt-4">
                  <h5>Preprocessed Image</h5>
                  <img
                    src={`data:image/jpeg;base64,${prediction.preprocessed_image_base64}`}
                    alt="Processed"
                    className="img-thumbnail mt-2"
                    width="300"
                  />
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default App;
