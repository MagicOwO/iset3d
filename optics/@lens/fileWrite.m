function fileWrite(obj, fullFileName, description)
% Writes PBRT lens file from Scene3D data
%
%   lens.fileWrite(fullFileName)
%
% The PBRT file has focal length information added to the header. This
% function converts the PBRT matrix of data into the format that Scene3d
% uses for a multielement lens.
%
% The basic look of a PBRT lens file is this
%
%  # Name: 2ElLens.dat
%  # Description: 2 Element simple lens
%  # Focal length (in mm)
%  50
%  # Each row is a surface. The order of surfaces starts from the image and
%  # heads to the sensor.  Zero is the position of the first lens surface.
%  # Positive numbers are towards the lens, and negative numbers are towards
%  # the image.
%  #      Object < 0)    0=First Surface    0 < Sensor plane
%  #
%  #    radius (mm)	 offset      N       diameter (mm)
%       67          1.5      1.65       10
%       0           1.5      1.65       10
%       -67         0	     1          10
%  # END
%
% Always assume the sensor is to the right and the object world is to
% the left.
%
% To interpret the matrix, it is easiest to start at the bottom row and
% read up.
%
% The bottom row is a surface that initiates everything and thus its offset
% is always 0. The radius of curvature is the distance to the center of
% sphere, which is negative in this case. Thus, the surface is like a
% backwards 'C'.  The index of refraction is to the right of the surface
% and for the first surface it will generally be air (1).
%
% The next row up is 1.5 mm offset towards the next object. We have a 0
% radius object, which means it's an aperture.  The material between this
% position and the first surface is glass (N = 1.65).
%
% The third row up has a center to the right, so the shape is a 'C'.  The
% material is still glass. %
%
% In the lens class, we don't use offsets. Instead, we store the sphere
% centers (sCenters) and radii (units of mm).  So here we go through the
% surfaceArray and produce the radius and offset needed for the PBRT matrix
% from the surfaceArray object sCenters and radius.
%
% AL VISTASOFT, Copyright 2014

%%
if ieNotDefined('description'), description = obj.type; end

% Open the lens file for writing
% fid = fopen(fullfile(dataPath, 'rayTrace', 'dgauss.50mm.dat'));
fid = fopen(fullFileName,'w');

%% Write the header
hdr = lensHeader(obj,description);
fprintf(fid,'%s',hdr);

%% Write the data matrix
d  = lensMatrix(obj);
for ii=1:size(d,1)
    fprintf(fid,'%f\t%f\t%f\t%f\n', d(ii,1), d(ii, 2), d(ii,3), d(ii,4));
end

%ftr = lensFooter(obj);
%fprintf(fid,'%s',ftr);
fclose(fid);
end




% % i is the row where the data begin
% 
% % The next values are the matrix data
% % put these data into lens object
% radius = str2double(import{1});
% radius = radius(dStart:length(firstColumn));
% 
% % Change from pbrt Scene3D format to raytrace Scene3D format
% % In PBRT, the row has the offset from the previous surface.  In
% % PBRT the data are read from the bottom up.  The last row has no
% % offset.
% % In PBRT, we trace from the sensor to the scene.
% % In Scene3D we trace from the scene to the sensor.
% % So, the offsets are shifted down.  This means:
% %
% offset = str2double(import{2});
% offset = offset(dStart:length(firstColumn));
% offset = [0; offset(1:(end-1))];
% 
% % Index of refraction in the 3rd column
% N = str2double(import{3});
% N = N(dStart:length(firstColumn));
% 
% % Diameter of the aperture (or maybe radius.  Must determine).
% aperture = str2double(import{4});
% aperture = aperture(dStart:length(firstColumn));
% 
% %modify the object and reinitialize
% obj.elementsSet(offset, radius, aperture, N);
% 
% % Figure out which is the aperture/diaphragm by looking at the radius.
% % When the spherical radius is 0, that means the object is an aperture.
% lst = find(radius == 0);
% if length(lst) > 1,         error('Multiple non-refractive elements %i\n',lst);
% elseif length(lst) == 1,    obj.apertureIndex(lst);
% else                        error('No non-refractive (aperture/diaphragm) element found');
% end
% 
% 
% end


%% The header

function hdr = lensHeader(obj, description)

hdr = sprintf('# Name: %s\n',obj.name);

str = sprintf('# Description: %s\n',description);
hdr = addText(hdr,str);

str = sprintf('# Focal length (mm) \n');
hdr = addText(hdr,str);

str = sprintf('%.3f\n',obj.focalLength);
hdr = addText(hdr,str);

str = sprintf('# Each row is a surface.\n');
hdr = addText(hdr,str);

str = sprintf('# The order of surfaces starts from the image and\n');
hdr = addText(hdr,str);

str = sprintf('# heads to the sensor.  Zero is the position of the first lens surface.\n');
hdr = addText(hdr,str);

str = sprintf('# Positive numbers are towards the lens, and negative numbers are towards\n');
hdr = addText(hdr,str);

str = sprintf('# the image\n');
hdr = addText(hdr,str);

str = sprintf('#    radius	 axpos	N	aperture\n');
hdr = addText(hdr, str);

end


%% Convert the surface array data to the PBRT matrix we want to write
function d = lensMatrix(lens)
% In the lens class, we don't use offsets. Instead, we store the sphere
% centers (sCenters) and radii (units of mm).  So here we go through the
% surfaceArray and produce the radius and offset needed for the PBRT matrix
% from the surfaceArray object sCenters and radius.

nSurfaces = lens.get('n surfaces');

% The PBRT data matrix
d = zeros(nSurfaces,4);
offsets = lens.get('offsets');
nArray = lens.get('index of refraction');
nArray = nArray(round((size(nArray,1) + 1)/2), :);
for ii=1:nSurfaces
    d(ii,1) = lens.get('s radius',ii);
    d(ii,2) = offsets(ii);
    
    % Pbrt does not yet support custom specified index of refractions. 
    % Thus, we will take the middle one 
    d(ii,3) = nArray(ii);
    d(ii,4) = lens.get('sdiameter', ii);
end




end
