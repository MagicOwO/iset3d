function [artifacts, idx, rd] = piPBRTPush(fnameZIP,varargin)
% Push a zipped PBRT scene to the RDT archive. 
%
% Syntax
%  [artifacts, idx, rd] = piPBRTPush(fnameZIP,varargin)
%
% Description
%   N.B. You must have write permission to push the zip file to the server.
%   Requires the RemoteDataToolbox.
%
%   Transfers a zip file containing a PBRT scene and its related files to
%   the Archiva server in the remote directory '/resources/scenes/pbrt'.
%   The file can be downloaded using piPBRTFetch.m
%
% Required input
%   fnameZIP     - name of the ZIP file to push to the server 
%   artifactName - name of the artifact assigned on the server
%   
% Optional inputs
%   rdtclient    - RdtClient with credentials
%   artifactName - Name to use for the remote artifact.
%
% Return
%   artifacts  - List of artifacts at '/resources/scenes/pbrt'
%   idx        - Index of this artifact
%
% TL, SCIEN Stanford, 2017
%
% See also: piPBRTFetch, RdtClient

% Examples
%{
  zipFile = fullfile(isetbioDataPath,'pbrtscenes','SlantedBar.zip');
  [artifacts, idx, rd] = piPBRTPush(zipFile);
%}
%{
  % After you run the code above, you can delete 
  % the artifact using this code
  rd = RdtClient('isetbio');
  rd.credentialsDialog
  [artifacts, idx, rd] = piPBRTPush(zipFile,'rdtclient',rd);

  rd.crp('/resources/scenes/pbrt');
  % rd.listArtifacts('print',true);
  rd.removeArtifacts(artifacts(idx));
%}

%% Parse inputs
p = inputParser;
p.addRequired('fnameZIP',@ischar);
p.addParameter('artifactName','',@ischar);
p.addParameter('rdtclient','',@(x)(isa(x,'RdtClient')));

p.parse(fnameZIP,varargin{:});

artifactName = p.Results.artifactName;
rd           = p.Results.rdtclient;

% Check zip file existence
if(~exist(fnameZIP,'file'))
    error('Given file does not exist.');
end

% Check that it is a zip file using the extension
% Is there a better way to do this?
[~,name,ext] = fileparts(fnameZIP);
if(~strcmp(ext,'.zip'))
    error('Given file does not seem to be a zip file.')
end

%% Get the file from the RDT
% To upload requires that you have a password on the Remote Data site.
% Login here. 
if isempty(rd)
    rd = RdtClient('isetbio');
    rd.credentialsDialog
end

%% Upload to RDT archive
rd.crp('/resources/scenes/pbrt');
fprintf('Uploading... \n');
if(isempty(artifactName))
    rd.publishArtifact(fnameZIP);
else
    rd.publishArtifact(fnameZIP,'artifactId',artifactName);
end
 
%% Update status
fprintf('Upload complete. \n');

%% Create return variables
% Print the artifacts, return the list, and find the index of this file in
% the artifacts list 
artifacts = rd.listArtifacts('print',true,'sortField','artifactId');
[~,idx] = ismember(name,{artifacts(:).artifactId});

end
