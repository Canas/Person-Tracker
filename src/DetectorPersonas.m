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