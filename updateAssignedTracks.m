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