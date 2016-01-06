%% Limpiar Workspace
clear all;
close all;
clc;

%% Crear objetos para leer video y detectar personas
obj = setupSystemObjects();
tracks = initializeTracks();     % Información de detector
info   = initializeInfo();       % Información de personas
nextId = 1;                      % ID del primer auto

%% Entrenar Background por 75 frames
for i = 1:75
    frame = obj.reader.step();
    mask  = obj.detector.step(frame);
end

%% Detectar objetos en movimiento y trackearlos 
while ~isDone(obj.reader)
    frame = obj.reader.step();
    [centroids, bboxes, mask] = detectObjects(frame, obj);
    tracks = predictNewLocationsOfTracks(tracks);
    [assignments, unassignedTracks, unassignedDetections] = ...
        detectionToTrackAssignment(tracks, centroids);

    [info, tracks, assignments] = updateAssignedTracks(info, tracks, assignments, ...
        centroids, bboxes);
    [tracks, unassignedTracks] = updateUnassignedTracks(tracks, unassignedTracks);
    [info, tracks] = deleteLostTracks(info, tracks);
    [info, tracks, nextId] = createNewTracks(info, tracks, ...
        unassignedDetections, centroids, bboxes, nextId);

    displayTrackingResults(obj, frame, mask, tracks);
end

release(obj.videoPlayer); delete(obj.videoPlayer);
release(obj.maskPlayer); delete(obj.maskPlayer);


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

function tracks = initializeTracks()
        % Crear un arreglo vacío de tracks.
        tracks = struct(...
            'id', {}, ...
            'bbox', {}, ...
            'kalmanFilter', {}, ...
            'age', {}, ...
            'totalVisibleCount', {}, ...
            'consecutiveInvisibleCount', {});
end

function info = initializeInfo()
        % Crear un arreglo vacío de personas.
        info = struct(...
            'id', {}, ...
            'entrada', {}, ...
            'salida', {}, ...
            'rectangulo', {}, ...
            'angulo', {}, ...
            'centroide', {}, ...
            'totalVisibleCount', {});
end

function [centroids, bboxes, mask] = detectObjects(frame, obj)

        % Detectar Foreground
        mask = obj.detector.step(frame);
        
        % Aplicar operaciones morfológicas para remover ruido
        %mask = imopen(mask, strel('Disk',1));
        mask = imopen(mask, strel('rectangle', [4,4]));
        mask = imclose(mask, strel('rectangle', [15, 15]));
        mask = imfill(mask, 'holes');
        
        % Realizar análisis de blob (trozos blancos en la imagen) para
        % encontrar componentes contectados
        [~, centroids, bboxes] = obj.blobAnalyser.step(mask);
end

function tracks = predictNewLocationsOfTracks(tracks)
    for i = 1:length(tracks)
        bbox = tracks(i).bbox;

        % Predecir la ubicación actual del track.
        predictedCentroid = predict(tracks(i).kalmanFilter);

        % Mover el rectangulo de deteccion para que este al centro de la
        % ubicación predicha.
        predictedCentroid = int32(predictedCentroid) - bbox(3:4) / 2;
        tracks(i).bbox = [predictedCentroid, bbox(3:4)];
    end
end

function [assignments, unassignedTracks, unassignedDetections] = ...
        detectionToTrackAssignment(tracks, centroids)

    nTracks = length(tracks);
    nDetections = size(centroids, 1);
    
    % Calcular el costo de asignar cada detección a cada track.
    cost = zeros(nTracks, nDetections);
    for i = 1:nTracks
        cost(i, :) = distance(tracks(i).kalmanFilter, centroids);
    end

    % Resolver el problema de asignación.
    costOfNonAssignment = 20;
    [assignments, unassignedTracks, unassignedDetections] = ...
        assignDetectionsToTracks(cost, costOfNonAssignment);
end

function [info, tracks, assignments] = updateAssignedTracks(info, tracks, ...
        assignments, centroids, bboxes)

    numAssignedTracks = size(assignments, 1);
    for i = 1:numAssignedTracks
        trackIdx = assignments(i, 1);
        detectionIdx = assignments(i, 2);
        infoIdx = tracks(trackIdx).id;
        
        centroid = centroids(detectionIdx, :);
        bbox = bboxes(detectionIdx, :);

        % Corregir estimado de la ubicación de persona usando la detección
        % nueva.
        correct(tracks(trackIdx).kalmanFilter, centroid);
        
        % Reemplazar rectángulo de predicción con el rectángulo predicho.
        tracks(trackIdx).bbox = bbox;
        info(infoIdx).rectangulo = bbox(3:4);
        
        % Obtener dirección de movimiento.
        c1 = info(infoIdx).centroide;
        c2 = centroid;
        c3 = c2 - c1;
        info(infoIdx).angulo = rad2deg(atan2(c3(2),c3(1)));

        % Actualizar edad del track.
        tracks(trackIdx).age = tracks(trackIdx).age + 1;

        % Actualizar visibilidad.
        tracks(trackIdx).totalVisibleCount = ...
            tracks(trackIdx).totalVisibleCount + 1;
        tracks(trackIdx).consecutiveInvisibleCount = 0;
        
        info(infoIdx).totalVisibleCount = tracks(trackIdx).totalVisibleCount;
    end
end

function [tracks, unassignedTracks] = updateUnassignedTracks(tracks, unassignedTracks)
    for i = 1:length(unassignedTracks)
        ind = unassignedTracks(i);
        tracks(ind).age = tracks(ind).age + 1;
        tracks(ind).consecutiveInvisibleCount = ...
            tracks(ind).consecutiveInvisibleCount + 1;
    end
end

function [info, tracks] = deleteLostTracks(info, tracks)
    if isempty(tracks)
        return;
    end

    invisibleForTooLong = 10;
    ageThreshold = 8;

    % Calcular fracción de edad en que el track ha sido visible.
    ages = [tracks(:).age];
    totalVisibleCounts = [tracks(:).totalVisibleCount];
    visibility = totalVisibleCounts ./ ages;

    % Encontrar los índices de los tracks perdidos (lostInds)
    lostInds = (ages < ageThreshold & visibility < 0.6) | ...
        [tracks(:).consecutiveInvisibleCount] >= invisibleForTooLong;
    
    % Actualizar hora de salida en info.
    lostIdx = find(lostInds);
    if(~isempty(lostIdx))
        for i=1:length(lostIdx)
            idx = tracks(lostIdx(1)).id;
            info(idx).salida = datetime('now');
        end
    end
    
    % Borrar tracks perdidos en track.
    tracks = tracks(~lostInds);
end

function [info, tracks, nextId] = createNewTracks(info, tracks, ...
        unassignedDetections, centroids, bboxes, nextId)
    
    centroids = centroids(unassignedDetections, :);
    bboxes = bboxes(unassignedDetections, :);

    for i = 1:size(centroids, 1)

        centroid = centroids(i,:);
        bbox = bboxes(i, :);

        % Crear objeto de Filtro de Kalman.
        kalmanFilter = configureKalmanFilter('ConstantVelocity', ...
            centroid, [200, 50], [100, 25], 100);

        % Crear nueva estructura de track.
        newTrack = struct(...
            'id', nextId, ...
            'bbox', bbox, ...
            'kalmanFilter', kalmanFilter, ...
            'age', 1, ...
            'totalVisibleCount', 1, ...
            'consecutiveInvisibleCount', 0);

        % Crear nueva estructura de persona.
        newInfo = struct(...
            'id', nextId, ...
            'entrada', datetime('now'), ...
            'salida', 0, ...
            'rectangulo', bbox(3:4), ...
            'angulo', 0, ...
            'centroide', centroid, ...
            'totalVisibleCount', 1);
        
        % Añadir a los arreglos de track e info.
        tracks(end + 1) = newTrack;
        info(end + 1) = newInfo;

        % Asignar la siguiente Id.
        nextId = nextId + 1;
    end
end

function displayTrackingResults(obj, frame, mask, tracks)
    % Convertir frame y máscara a uint8 RGB.
    frame = im2uint8(frame);
    mask = uint8(repmat(mask, [1, 1, 3])) .* 255;

    minVisibleCount = 4;
    if ~isempty(tracks)
        
        % Detecciones ruidosas resultan en tracks de corta vida.
        % Solo mostrar tracks que han sido visibles por más de un número
        % mínimo de frames.
        reliableTrackInds = ...
            [tracks(:).totalVisibleCount] > minVisibleCount;
        reliableTracks = tracks(reliableTrackInds);
        
        % Mostrar los objetos. Si un objeto no ha sido detectado en este
        % frame, mostrar su rectángulo predicho.
        if ~isempty(reliableTracks)
            % Obtener rectángulos de detección.
            bboxes = cat(1, reliableTracks.bbox);

            % Obtener ids.
            ids = int32([reliableTracks(:).id]);
            
            % Crear etiquetas para objetos indicando los que 
            % si se usa del rectángulo predicho o el detectado.
            labels = cellstr(int2str(ids'));
            predictedTrackInds = ...
                [reliableTracks(:).consecutiveInvisibleCount] > 0;
            isPredicted = cell(size(labels));
            isPredicted(predictedTrackInds) = {' predicted'};
            labels = strcat(labels, isPredicted);

            % Dibujar objetos en el frame.
            frame = insertObjectAnnotation(frame, 'rectangle', ...
                bboxes, labels);

            % Dibujar objetos en la máscara.
            mask = insertObjectAnnotation(mask, 'rectangle', ...
                bboxes, labels);
        end
    end

    % Numero de personas en el sistema actualmente
    numCars = length(tracks);
    frame = insertText(frame, [10 10], numCars, 'BoxOpacity', 1, ...
        'FontSize', 14, 'BoxColor', 'magenta');
    
    
    % Mostrar el frame y la máscara de detección.
    obj.maskPlayer.step(mask);
    obj.videoPlayer.step(frame);
end