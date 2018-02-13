%% Lens tutorial
%
% Wandell
%
% See also

%% Find the lenses
thisLens = lens;
lenses = thisLens.list;

%% Pick a lens and draw it and plot the focal distance

thisLens = lens('filename',lenses(5).name);
thisLens.draw;
thisLens.plot('focal distance');

%% Show a point ray traced through the lens
