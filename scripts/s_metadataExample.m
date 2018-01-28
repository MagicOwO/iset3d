%% Illustrate methods for retrieving scene metadata
%
% Description:
%  For several purposes, but especially machine-learning algorithms, we
%  like to have pixel-by-pixel metadata. These describe the material or the
%  identity of the mesh or the depth at that pixel. This script shows how
%  to calculate the pixel-wise metadata information.
%
%  At this level, you only need to set the 'renderType' parameter when
%  you invoke piRender.
%
%  The implementation uses that flag to write out a value in the PBRT scene
%  file. TL modified PBRT to detect this value in the file and return the
%  metadata rather than the radiance or irradiance image.
%
%  This script uses the numbersAtDepth scene, but it is possible to use
%  other scenes (e.g., teapot-area-light) as easily.
%
% TL/BW SCIEN 2018
%
% See also s_piReadRender

%% Initialize ISET and Docker

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Import the pbrt file

% fname = fullfile(piRootPath,'data','NumbersAtDepth','numbersAtDepth.pbrt');
% fname = fullfile(piRootPath,'data','teapot-area','teapot-area-light.pbrt');
fname = fullfile(piRootPath,'data','ChessSet','chessSet.pbrt');

if ~exist(fname,'file'), error('File not found'); end
thisR = piRead(fname);

%% Use a pinhole for quick rendering. 

thisR.set('camera','pinhole');
thisR.set('fov',40);
thisR.set('film resolution',128);
thisR.set('rays per pixel',64);

% Write out the recipe
[p,n,e] = fileparts(fname); 
thisR.set('outputFile',fullfile(piRootPath,'local',[n,e]));
piWrite(thisR);

%% Render a radiance file and a depth map.

scene = piRender(thisR);
scene = oiSet(scene,'name','Radiance_and_Depth');
vcAddObject(scene); sceneWindow;   
sceneSet(scene,'gamma',0.5);

%% Render an image with each pixel labeled by material type.

matImage = piRender(thisR,'renderType','material'); % This just returns a 2D image

vcNewGraphWin;
imagesc(matImage); axis image;
title('Material'); colorbar;

% There is no text file associated with materials, since it is difficult to
% look up material names, internally, within PBRT. 

%% Render only a depth map

depthImage = piRender(thisR,'renderType','depth'); % This just returns a 2D image

vcNewGraphWin;
imagesc(depthImage); axis image; 
title('Depth'); colormap(gray); colorbar;

%% Show which mesh is associated with each pixel values

meshImage = piRender(thisR,'renderType','mesh'); % This just returns a 2D image

% You can find a txt file with the mesh names corresponding to each index
% in the 'renderings' folder of the output. In this case...
meshTextFile = fullfile(piRootPath,'local','renderings',strcat(n,'_mesh_mesh.txt'));

% The mesh indices are not always helpful, unless someone has curated the
% PBRT scene file.
fprintf('For mesh indices labels, see: \n   %s \n',meshTextFile);
% edit(meshTextFile)

% We make an image with one color for each unique mesh value.

uniqueValues = unique(meshImage(:));
nValues = length(uniqueValues);
fprintf('There are %d unique mesh values\n',length(uniqueValues));
remap  = 1:nValues;
for ii = 1:nValues
    % Find the meshImage points with this unique value
    curI = (meshImage == uniqueValues(ii));
    meshImage(curI) = remap(ii);
end

% Now, show the image using a map that can probably distinguish adjacent
% colors reasonably.  
vcNewGraphWin;
imagesc(meshImage); axis image;
mp = parula(nValues); mp = mp(randperm(nValues),:);
colormap(mp); title('Mesh (re-mapped)');
 
% Example:
%{
% If you are looping, you may only want the depth once. This is how you get
% just the radiance.
scene = piRender(thisR,'renderType','radiance');
scene = oiSet(scene,'name','Radiance only');
vcAddObject(scene); sceneWindow; 
%}

%%