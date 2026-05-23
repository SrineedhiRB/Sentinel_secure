import os
import urllib.request

def download_model():
    # URL to a reliable quantized MobileFaceNet TFLite model
    model_url = "https://github.com/MCarlomagno/FaceRecognitionAuth/raw/master/assets/mobilefacenet.tflite"
    
    # Target directory path
    target_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "models")
    os.makedirs(target_dir, exist_ok=True)
    
    target_file = os.path.join(target_dir, "mobile_facenet.tflite")
    
    print(f"Checking for AI model: {target_file}")
    if os.path.exists(target_file):
        print("MobileFaceNet model already present in assets.")
        return
        
    print(f"Downloading MobileFaceNet model from: {model_url}")
    try:
        urllib.request.urlretrieve(model_url, target_file)
        print(f"Success! Model saved to: {target_file}")
    except Exception as e:
        print(f"Failed to download model: {e}")
        print("Please place a valid mobile_facenet.tflite model in assets/models manually.")

if __name__ == "__main__":
    download_model()
