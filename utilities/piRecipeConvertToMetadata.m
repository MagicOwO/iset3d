function metadataRecipe = piRecipeConvertToMetadata(recipe,varargin)
% Convert radiance recipe to a metadata recipe 
%
% Syntax:
%    metadataRecipe = piRecipeConvertToMetadata(recipe,varargin)
%
% Inputs:
%  recipe - a typical radiance input recipe
%
% Optional key/value pairs:
%  'metadata' -  {'depth','mesh','material'} (V2)
%  'metadata' -  {'depth','mesh','material','coordinates'} (V3)
%
% Outputs:
%  metadataRecipe - the metadata recipe, a modification of the recipe.
%
% TL, SCIEN Stanford, 2017
%
% See also  piRender.m
%

%% Verify and clone the radiance recipe

p = inputParser;
p.addRequired('recipe',@(x)isequal(class(x),'recipe'));

metaTypes = {'depth','mesh','material','coordinates'};
p.addParameter('metadata','depth',@(x)(ismember(x,metaTypes))); % By default it is a depth map

p.parse(recipe,varargin{:});
metadata = p.Results.metadata;

metadataRecipe = copy(recipe);

%% Adjust the recipe values

% Assign metadata integrator
if(recipe.version == 3)
    integrator = struct('type','Integrator','subtype','metadata');
else 
    integrator = struct('type','SurfaceIntegrator','subtype','metadata');
end
integrator.strategy.value = metadata; % Could be mesh, material, depth or coordinates for V3
integrator.strategy.type = 'string';
metadataRecipe.integrator = integrator;

% For version 3, we have to turn off the weighting on the camera
if(recipe.version == 3)
    metadataRecipe.camera.noweighting.value = 'true';
    metadataRecipe.camera.noweighting.type = 'bool';
end

% Change sampler type for better depth sampling
sampler = struct('type','Sampler','subtype','stratified');
sampler.jitter.value = 'false';
sampler.jitter.type = 'bool';
sampler.xsamples.value= 1;
sampler.xsamples.type = 'integer';
sampler.ysamples.value = 1;
sampler.ysamples.type = 'integer';
metadataRecipe.sampler = sampler;

% Change filter for better depth sampling
filter = struct('type','PixelFilter','subtype','box');
filter.xwidth.value = 0.5;
filter.xwidth.type = 'float';
filter.ywidth.value = 0.5;
filter.ywidth.type = 'float';
metadataRecipe.filter = filter;

% Error checking
if(isempty(recipe.outputFile))
    error('Recipe output file is empty.');
end

% Assign the right depth output file.  Deep copy issue here?
[workingFolder, name, ~] = fileparts(recipe.outputFile);
metadataFile   = fullfile(workingFolder,sprintf('%s_%s.pbrt',name,metadata));
metadataRecipe.outputFile = metadataFile;

end

