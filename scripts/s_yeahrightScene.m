%% Render the yeahright scene
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
fname = '/home/wandell/pbrt-v2-spectral/pbrtScenes/yeahright/yeahright.pbrt';

% Read the main scene pbrt file.  Return it as a recipe
thisR = piRead(fname);

%% Set to pinhole camera for a scene
thisR = recipeSet(thisR,'camera','pinhole');
thisR = recipeSet(thisR,'pixel samples',  256);
thisR = recipeSet(thisR,'film resolution',800);

%% Write out a new pbrt file

% Docker will mount the volume specified by the working directory
workingDirectory = fullfile(piRootPath,'local');

% We copy the pbrt scene directory to the working directory
[p,n,e] = fileparts(fname); 
copyfile(p,workingDirectory);

% Now write out the edited pbrt scene file, based on thisR, to the working
% directory.
thisR.outputFile = fullfile(workingDirectory,[n,e]);

% oname = fullfile(workingDirectory,'whiteScene.pbrt');
piWrite(thisR, 'overwrite pbrt file', true,'overwrite resources',false);

%% Render with the Docker container

scene = piRender(thisR);

% Show it in ISET
vcAddObject(scene); sceneWindow;   

%%