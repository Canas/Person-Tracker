function obj = setupSystemObjects()
    % Crear lector de video
    obj.reader = vision.VideoFileReader('carsRt9_3.avi');
    
    % Crear reproductor de video
    obj.videoPlayer = vision.VideoPlayer('Position', [650, 0, 700, 400]);
    obj.maskPlayer = vision.VideoPlayer('Position', [50, 0, 700, 400]);
    
    % Separar foreground y background
    obj.detector = vision.ForegroundDetector('NumGaussians', 3, ...
        'NumTrainingFrames', 50);

    % Obtener blobs de personas
    obj.blobAnalyser = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
            'AreaOutputPort', true, 'CentroidOutputPort', true, ...
            'OrientationOutputPort', false, 'MinimumBlobArea', 150);
end