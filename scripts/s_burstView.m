%% View burst
%
% Make a series of images showing the computed digital values from camera
% shake in burst mode photography.
%
% BW, Vistasoft team, 2017


%% Teapot example
chdir(fullfile(piRootPath,'local','teapot','renderings'));
f = dir('*.mat');

vcNewGraphWin;
for ii=1:length(f)
    load(f(ii).name,'dv');
    imagesc(dv.^0.3); colormap(gray); truesize;
    pause
end

%% Chess set example
chdir(fullfile(piRootPath,'local','chess','renderings'));
f = dir('*.mat');

vcNewGraphWin;
for ii=1:length(f)
    load(f(ii).name,'dv');
    imagesc(dv.^0.3); colormap(gray); truesize;
    pause
end

%%