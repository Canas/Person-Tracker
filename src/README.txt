Paso 1: Crear objetos de Sistema
La función 'setupSystemObjects' se encarga de crear todos los objetos que el detector utilizará para leer frames, separar background de foreground y encontrar puntos de interés (con su respectivo rectangulo de deteccion).

-----------------------------------------
Paso 2: Inicializar tracks e info
La función 'initializeTracks' crea una estructura (tracks) con propiedades del objecto al que se le hará seguimiento en el video. Contiene todas las personas siendo trackeadas en el video; si una persona desaparece por mucho tiempo, se elimina del arreglo.

La función 'initializeInfo' crea una estructura (info) con propiedades de la persona en el sistema (id, entrada, salida, rectangulo, angulo, etc). Contiene todas las personas detectadas por el sistema desde el inicio hasta el fin del algoritmo.

-----------------------------------------
Paso 3: Detectar personas
'detectObject()' se encarga de procesar y separar background de foreground. Luego obtiene todas las personas potenciales en ese frame específico.

-----------------------------------------
Paso 4: Predicción de siguiente estado
'PredictNewLocationOfTracks()' hace una estimación de donde estará el siguiente rectángulo de detección. Esto es fundamental para que el seguimiento sea robusto, ya que se comparará el rectángulo de detección siguiente con el que se obtuvo en la predicción.

-----------------------------------------
Paso 5: Asociar personas detectadas en el foreground con su id en el arreglo track
Una cosa es detectar personas en una imagen, otra es asociarlas a su identificador correspondiente en el arreglo que lleva el seguimiento (track). 'detectionToTrackAssignment()' toma los datos anteriores y entrega tres indices diferentes:
- Personas detectadas que tienen una id asociada a track
- Personas detectadas que no tienen una id asociada a track
- Personas no-detectadas que tienen una id asociada a track

-----------------------------------------
Paso 6: Actualizar tracks e info
Con los indices obtenidos en la Parte 5, se realizan varios procesos
'updateAssignedTracks' 		-> Si hay una persona detectada asociada a un frame pasado, actualizar su pose
'updateUnassignedTracks' 	-> Si una persona de un frame pasado no aparece este frame, se marca 'invisible'
'deleteLostTracks'			-> Si una persona lleva muchos frames 'invisible', ya no está en el sistema
'createNewTracks'			-> Si se detecta una persona nueva en el frame, se añade al sistema