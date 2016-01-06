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