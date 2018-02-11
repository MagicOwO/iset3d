%% Render a sanmiguel scene with lens optics
%
% NOTES:
%
% Timing on a Linux box with multiple cores (gray.stanford.edu).
%
%  Timing     film resol   rays per pixel
%     216 s     192          128
%     285 s     256          128 
%     40  m     768          128 
%
% The sanmiguel scene is fairly large, so we do not include it in the github
% repository.  To download it, you can use the RemoteDataToolbox
% <https://github.com/isetbio/RemoteDataToolbox.git>.  
%
% The commands to download from the RDT are
%
%{
 rdt = RdtClient('isetbio');               % Open the connection
 a = rdt.searchArtifacts('sanmiguel');     % Root name of the artifact

 % Where you put the file and how you set it up is your choice. 
 destinationFolder = fullfile(piRootPath,'local');
 rdt.readArtifact(a,'destinationFolder',destinationFolder);
 fnameZIP = fullfile(destinationFolder,'sanmiguel.zip'); 
 unzip(fnameZIP);

 %  Make the fname below consistent with what you did above.  Might be this.
 fname = fullfile(destinationFolder,'sanmiguel','sanmiguel.pbrt'); 
%}
%
% BW SCIEN 2017

%% Initialize ISET and Docker

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Specify the pbrt scene file and its dependencies

% We organize the pbrt files with its includes (textures, brdfs, spds, geometry)
% in a single directory. 
% fname = '/home/wandell/pbrt-v2-spectral/pbrtScenes/sanmiguel/sanmiguel.pbrt';
fname = fullfile(piRootPath,'data','sanmiguel','sanmiguel.pbrt');
if ~exist(fname,'file'), error('File not found'); end

% Read the main scene pbrt file.  Return it as a recipe
thisR = piRead(fname);

%{
% To choose a lens, we may need to find the distance to points 
% near the center of the scene and set the lookAt correctly.
% To explore the situation, we use the pinhole camera default and measure the
% depth map.

% Write out the data 
[p,n,e] = fileparts(fname); 
thisR.outputFile = fullfile(piRootPath,'local',[n,e]);
piWrite(thisR);
scene = piRender(thisR);
depthMap = sceneGet(scene,'depthmap');
% This is an alternative this would run faster.
% depthMap = piRender(thisR,'renderType','depth');

% Confirm that it ran OK
% ieAddObject(scene); sceneWindow;
% Show the depth map
vcNewGraphWin; mesh(depthMap);
vcNewGraphWin; hist(depthMap(:),100); grid on
%}
%{
% Explore lens properties
l = lens; lNames = l.list;
thisLens = lens('filename',lNames(5).name);
thisLens.plot('focal distance');

%}

%% Default is a relatively low resolution (256).

% We need to choose a lens file, probably by hand.
thisR.set('camera','realistic');
thisR.set('aperture',2);  % The number of rays should go up with the aperture 
thisR.set('film resolution',256);
thisR.set('rays per pixel',64);

% We need to move the camera far enough away so we get a decent view.
objDist = thisR.get('object distance');
thisR.set('object distance',100*objDist);
thisR.set('autofocus',true);

%% Set up Docker 

[p,n,e] = fileparts(fname); 
thisR.outputFile = fullfile(piRootPath,'local',[n,e]);
piWrite(thisR);

%% Render with the Docker container

scene = piRender(thisR);

% Show it in ISET
vcAddObject(scene); sceneWindow; sceneSet(scene,'gamma',0.5);

%%
