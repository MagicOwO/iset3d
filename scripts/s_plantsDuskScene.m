%% Render the villa-lights-on scene (villaLights)
%
% 
% BW SCIEN 2018

%% Initialize ISET and Docker

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the pbrt scene
% This scene consists of an infinite light source and a white disk placed 1
% meter away from the camera. The disk itself has a radius of 1 meter as
% well.
% fname = fullfile(piRootPath,'data','yeahright','yeahright.pbrt');
fname = '/home/wandell/pbrt-v2-spectral/pbrtScenes/plantsDusk/plantsDusk.pbrt';

% Read the main scene pbrt file.  Return it as a recipe
thisR = piRead(fname);

%% Set to pinhole camera for a scene
thisR = recipeSet(thisR,'camera','pinhole');
thisR = recipeSet(thisR,'pixel samples',  256);
thisR = recipeSet(thisR,'film resolution',512);

%% Set up Docker directory

% Write out the pbrt scene file, based on thisR.  By def, to the working directory.
[p,n,e] = fileparts(fname); 
thisR.set('outputFile',fullfile(piRootPath,'local','plantsDusk',[n,e]));

% oname = fullfile(workingDirectory,'whiteScene.pbrt');
piWrite(thisR, 'overwrite pbrt file', true,'overwrite resources',true);

%% Render with the Docker container

scene = piRender(thisR);

% Show it in ISET
vcAddObject(scene); sceneWindow;   

%%