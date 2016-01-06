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