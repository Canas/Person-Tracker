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