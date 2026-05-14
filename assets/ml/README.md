<!-- TFLite Model Assets — Placeholders
     
     These files must be provided separately. The AI detection services
     will fall back to heuristic-based detection when models are not available.
     
     Required model files:
     
     1. movement_model.tflite
        - Input:  [1, 50, 6] float32 (50 frames × 6 channels: accel XYZ + gyro XYZ)
        - Output: [1, 4] float32 (probabilities: normal, fall, fight, running)
        - Training: Use the companion Python training script with accelerometer/gyroscope data
     
     2. audio_model.tflite
        - Input:  [1, 32, 13] float32 (32 MFCC frames × 13 coefficients)
        - Output: [1, 3] float32 (probabilities: normal, scream, keyword)
        - Training: Use the companion Python training script with audio samples
     
     3. audio_model_config.json
        - Contains: sample_rate, frame_length, num_mfcc, hop_length, n_fft
     
     4. scaler_mean.json
        - Contains: mean values for each MFCC feature (for normalisation)
     
     5. scaler_std.json
        - Contains: standard deviation for each MFCC feature (for normalisation)
-->
