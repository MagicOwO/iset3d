%% The texturedPlane scene - a way to measure planar targets
%
% This script enables you to place a spatial pattern (texture) onto a plane in
% the PBRT scene file.  You can then render the scene through optics using
% PBRT and measure properties of the irradiance.
%
% The textured plane scene consists of a single plane sized 1 m x 1 m.
% Initially, the plane is located at the origin (0,0,0) and rotated tp be
% perpendicular to the y-axis (optical axis) and in the x-z plane.
%
% The test pattern is placed on the plane by specifying an EXR image file. We
% are starting to store EXR test images in data/imageTextures.
%
% Computationa
%  Because the camera is located at (0,0,0), you will need to scale and
%  translate the plane in order to see it. We use the functions piMoveObject to
%  translate. The utilities for this are evolving.
%
% Side notes: 
%   The "no filtering" flag for the texture is automatically turned on, so there
%   is no anti-aliasing filter applied during rendering when we sample the
%   texture. This is very important, and was added by TL in PBRTv2. However,
%   given how important it is you should always check to make sure that
%   filtering is off!
%
% TL SCIEN 2017
%
% See also piWorldFindAndReplace, piMoveObject, s_CheckerboardCalibration

%% Initialize ISET and Docker

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the pbrt scene
fname = fullfile(piRootPath,'data','texturedPlane','texturedPlane.pbrt');

% Read the main scene pbrt file.  Return it as a recipe
thisR = piRead(fname);

% Setup working folder
workingDir = fullfile(piRootPath,'local','texturedPlane');
if(~isdir(workingDir))
    mkdir(workingDir);
end

%% 
% Note: In ISETBIO, we do the scaling/translating/texture all in a single
% step when we load this scene. For example: 
%
% scene =
% sceneEye('texturedPlane','planeDistance',1000,'texture','resolution.exr');
%
% This is only possible because the sceneEye object can automatically take
% care of these setps for the user. It is more convenient for the user but
% has less flexibility. Maybe we should think about whether we want
% pbrt2ISET to be as easy to use as the sceneEye object in ISETBIO.

%% Scale and translate the plane

% Let's move the plane 1 meter away and scale it to a size of 0.5 m x 0.5 m.
% The spatial units are always in mm

scale     = 0.5;  % A scaling factor, 1000*0.5 = 500 mm
translate = 1000; % mm

% The textured plane is named "Plane" in this PBRT file. The camera is located
% at the origin and looking down the positive y-axis. 
%
% Note: The order of scaling and translating matters!
piMoveObject(thisR,'Plane','Scale',[scale scale scale]); % The plane is oriented in the x-z plane
piMoveObject(thisR,'Plane','Translate',[0 translate 0]); 

%% Attach a desired texture

% Let's add a resolution chart texture from an exr file.

% Since the plane is square, the texture should also be square. Otherwise
% you should scale the plane appropriately in the above step. You can find
% some textures to use in pbrt2ISET --> data --> imageTextures.
%
% The texture also needs to be an EXR file. You can use OSX Preview app to
% convert image files. In the future, we will also add in our docker
% conversion tools into pbrt2ISET (imageMagick thing).
imageName = 'squareResolutionChart.exr';
imageFile = fullfile(piRootPath,'data','imageTextures',imageName);

% The original file has a dummy texture called "dummyTexture.exr." We use
% pbrt2ISET find and replace this texture with one of our own. Be sure to
% copy it to the right folder location!
% TODO: Should we have piWrite check for textures in the world block and
% copy them automatically? Then we would have the user put in an absolute
% path here instead of a relative one.
copyfile(imageFile,workingDir);
thisR = piWorldFindAndReplace(thisR,'dummyTexture.exr',imageName);

%% Write out a new pbrt file

% We copy the pbrt scene directory to the working directory
[p,n,e] = fileparts(fname); 

% Now write out the edited pbrt scene file, based on thisR, to the working
% directory.
thisR.outputFile = fullfile(workingDir,[n,e]);

piWrite(thisR, 'overwrite pbrt file', true,'overwrite resources',true);

%% Render with the Docker container

scene = piRender(thisR);

% Show it in ISET
vcAddObject(scene); sceneWindow;   

%%