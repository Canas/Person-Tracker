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