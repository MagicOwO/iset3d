function [fnameZIP, artifact] = piPBRTFetch(aName,varargin)
% FETCH a PBRT file from the RDT archive to a local directory.
%
% Syntax
%  piPBRTFetch(artifactName,varargin)
%
% Required input
%   artifactName - The base name of the artifact that can be found by a search
%   
% Optional inputs
%   destinationFolder - default is piRootPath/data
%   unzip     - perform the unzip operation (default true)
%   deletezip - delete zip after unzipping (default false)
%
% Return
%   fnameZIP - full path to the zip file
%   artifact - artifact that was found on the remote site during the search
%
% Description
%   The PBRT data are stored as zip files that include the pbrt scene file
%   along with all of the necessary additional files.  These are typically
%   stored inside of folders (geometry, brdfs, spds, textures).  This
%   function pulls down the zip file containing everything and, by default,
%   unzips the file so that the scene and auxiliary files are in a single
%   directory.
% 
% Wandell, SCIEN Stanford, 2017

% Examples
%{
 % Specify the artifact name, download it, and render it
 % By default, the download is to piRootPath/data
 [fnameZIP, artifact] = piPBRTFetch('whiteScene');

 % Read the recipe from the pbrt scene file, which is contained inside a
 % directory of the same name 
 [p,n,e] = fileparts(fnameZIP);
 dname = fullfile(p,n); fname = [n,'.pbrt'];
 thisR = piRead(fullfile(dname,fname));
%}

%% Parse inputs
p = inputParser;
p.addRequired('aName',@ischar);
p.addParameter('destinationFolder',fullfile(piRootPath,'data'),@ischar);
p.addParameter('unzip',true,@islogical);
p.addParameter('deletezip',false,@islogical);

p.parse(aName,varargin{:});
destinationFolder = p.Results.destinationFolder;
zipFlag = p.Results.unzip;
deleteFlag = p.Results.deletezip;

%% Get the file from the RDT

rdt = RdtClient('isetbio');
rdt.crp('/resources/scenes/pbrt');
a = rdt.searchArtifacts(aName);

% There should only be one artifact matching the aName.  But in case there
% are more, we have the user select.
if length(a) > 1
    fprintf('Artifact names\n------------\n');
    for ii=1:length(a)
        fprintf('%d - %s\n',a(ii).artifactId);
    end
    ii = input('Select a number','s');
else
    ii = 1;
end

% Go git it.
[fnameZIP, artifact] =rdt.readArtifact(a(ii),...
    'destinationFolder',destinationFolder);

%% If download succeeded, check if unzip and delete are requested
if exist(fnameZIP,'file')
    if zipFlag
        % unzip into the destionation directory.
        unzip(fnameZIP,destinationFolder);
    end
    
    % Only delete the zip file if the person has unzipped.  This prevents
    % boneheaded mistakes.
    if deleteFlag && zipFlag,  delete(fnameZIP); end
end

end
