%% Download all the pbrt scenes from the Archiva server
%

rd = RdtClient('isetbio');
rd.crp('/resources/scenes/pbrt');
a = rdt.listArtifacts('print',true);

%%  This copies all the zip file artifacts to my Google Drive in data/PBRT

destinationFolder = '/Users/wandell/Google Drive/Data/PBRT';
for ii=1:length(a)
    [fnameZIP, artifact] =rdt.readArtifact(a(ii),...
    'destinationFolder',destinationFolder);
    disp(fnameZIP);
end

%%