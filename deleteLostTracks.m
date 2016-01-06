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