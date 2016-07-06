function displayTrackingResults(obj, frame, mask, tracks)
    % Convertir frame y m�scara a uint8 RGB.
    frame = im2uint8(frame);
    mask = uint8(repmat(mask, [1, 1, 3])) .* 255;

    minVisibleCount = 4;
    if ~isempty(tracks)
        
        % Detecciones ruidosas resultan en tracks de corta vida.
        % Solo mostrar tracks que han sido visibles por m�s de un n�mero
        % m�nimo de frames.
        reliableTrackInds = ...
            [tracks(:).totalVisibleCount] > minVisibleCount;
        reliableTracks = tracks(reliableTrackInds);
        
        % Mostrar los objetos. Si un objeto no ha sido detectado en este
        % frame, mostrar su rect�ngulo predicho.
        if ~isempty(reliableTracks)
            % Obtener rect�ngulos de detecci�n.
            bboxes = cat(1, reliableTracks.bbox);

            % Obtener ids.
            ids = int32([reliableTracks(:).id]);
            
            % Crear etiquetas para objetos indicando los que 
            % si se usa del rect�ngulo predicho o el detectado.
            labels = cellstr(int2str(ids'));
            predictedTrackInds = ...
                [reliableTracks(:).consecutiveInvisibleCount] > 0;
            isPredicted = cell(size(labels));
            isPredicted(predictedTrackInds) = {' predicted'};
            labels = strcat(labels, isPredicted);

            % Dibujar objetos en el frame.
            frame = insertObjectAnnotation(frame, 'rectangle', ...
                bboxes, labels);

            % Dibujar objetos en la m�scara.
            mask = insertObjectAnnotation(mask, 'rectangle', ...
                bboxes, labels);
        end
    end

    % Numero de personas en el sistema actualmente
    numCars = length(tracks);
    frame = insertText(frame, [10 10], numCars, 'BoxOpacity', 1, ...
        'FontSize', 14, 'BoxColor', 'magenta');
    
    
    % Mostrar el frame y la m�scara de detecci�n.
    obj.maskPlayer.step(mask);
    obj.videoPlayer.step(frame);
end