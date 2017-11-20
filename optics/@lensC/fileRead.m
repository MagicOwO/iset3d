function fileRead(obj, fullFileName)
% Reads PBRT lens file
%
%   lens.fileRead(fullFileName)
%
% Input:
%   The name of a PBRT lens file
% Action:
%   The obj (a lens) has several fields set.  These are managed by the
%   method 'elementsSet', which copies the vector of lens and aperture
%   parameters into the lens.surfaceArray slot.  The parameters are the
%   surface Offset (mm), sRadius (mm), sAperture (mm), sN (index of
%   refraction).
%     
% This function converts the PBRT lens data into the format that CISET uses
% for a multi-element lens.
%
% PBRT convention typically orders the data of the multi-element array from
% the sensor to the scene, since that is the direction in which PBRT traces
% the ray. However, because PBRT reads the file from bottom to top, the
% data is written in reverse on the file. 
%
% With CISET the convention is to trace from the scene to the sensor. In
% conclusion, we do NOT need to reverse any of the PBRT data because it is
% written in reverse order already. However, we must be careful about where
% the "0" is placed in the offset variable. See below for more information.
%
% AL/TL VISTASOFT, Copyright 2014

% Open the lens file
fid = fopen(fullFileName);
if fid < 0, error('File not found %s\n',fullFileName); end

% Read each of the lens and close the file
import = textscan(fid, '%s%s%s%s', 'delimiter' , '\t');
fclose(fid);

% Read the focal length of the lens. Search for the first non-commented 
% line in the first column.
id = find(isnan(str2double(import{1})) == false,1,'first');
obj.focalLength = str2double(import{1}(id));

% First find the start of the lens line, marked "#   radius"
firstColumn = import{1};
continueRead = true;
dStart = 1;   % Row where the data entries begin
while(continueRead && dStart <= length(firstColumn))
    compare = regexp(firstColumn(dStart), 'radius');
    if(~(isempty(compare{1})))
        continueRead = false;
    end
    dStart = dStart+1;
end

% Now that we know which line the numerical data begins at, we can read
% each column and save the data.
radius = str2double(import{1});
radius = radius(dStart:length(firstColumn));

% Read in "Axpos," which is the distance from the current surface to the
% next surface. (We call this "offset.") The offset denotes the distance
% between the current surface and the previous one. In the PBRT file, there
% is a "0" at the end of the column because (1) PBRT reads the data in
% reverse and (2) there isn't a lens before the first one. For our CISET
% ray tracing convention, we go from the scene to the sensor, so we must
% move the zero to the beginning of the column but keep the rest of the
% data in the same order.
offset = str2double(import{2});
offset = offset(dStart:length(firstColumn));
offset = [0; offset(1:(end-1))]; % Shift to account for different convention

% Read in N, the index of refraction.
N = str2double(import{3});
N = N(dStart:length(firstColumn));

% Read in diameter of the aperture.
aperture = str2double(import{4});
aperture = aperture(dStart:length(firstColumn));

% Modify the object with the data we read
obj.elementsSet(offset, radius, aperture, N);

% Figure out which is the aperture/diaphragm by looking at the radius.
% When the spherical radius is 0, that means the object is an aperture.
lst = find(radius == 0);
if length(lst) > 1,         error('Multiple non-refractive elements %i\n',lst);
elseif length(lst) == 1,    obj.apertureIndex(lst);
else                        error('No non-refractive (aperture/diaphragm) element found');
end


end


