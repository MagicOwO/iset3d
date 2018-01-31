classdef lens <  handle
    % Create a multiple element lens object
    %
    %   lens = lens(elOffset, elRadius, elAperture, elN, aperture, focalLength, center);
    %
    % Distance units, when not otherwise specified, are millimeters.
    %
    % We represent multi-element lenses as a set of spherical lenses and
    % circular apertures. The multiple elements are defined by a series of
    % surfaces with a curvature, position, and index of refraction (as a
    % function of wavelength).
    %
    % We specify the position of each surface as the center of the
    % spherical lens.  Rays travel from left (the scene) to right. The zero
    % position is the right-most spherical surface. The film (sensor) is at
    % a positive position.
    %
    %     Scene ->  | Lens Surfaces ->|   Film
    %                    -            0     +
    %
    % Apertures are circular, their center is in the (0,0) position and
    % they are specified by a single parameter (diameter in mm).
    %
    % The index of refraction (n) attached to a surface defines the
    % material to the left of the surface.
    %
    % Lens files and surface arrays are specified from the front most
    % element (closest to the scene), to the back-most element (closest to
    % the sensor).  Hence, surface arrays are listed from negative
    % positions to positive positions.
    %
    % Pinhole cameras have no aperture and the pinhole lens will inherit
    % this superclass. This will be a superclass that will be inherited by
    % other classes in the future [BW/TL don't understand].
    %
    % We aim to be consistent with the PBRT lens files, and maybe the Zemax
    % as far possible.
    %
    % Todo: consider a set function for better error handling.
    %
    % Example:
    %  Create a lens object
    %
    %   thislens = lens();
    %
    %
    % AL Vistasoft Copyright 2014
    
    properties
        name = 'default';
        type = 'multi element lens';
        surfaceArray = surfaceC();     % Set of spherical surfaces and apertures
        diffractionEnabled = false;    % Not implemented yet
        wave = 400:50:700;             % nm
        focalLength = 50;              % mm, focal length of multi-element lens
        apertureMiddleD = 8;           % mm, diameter of the middle aperture
        apertureSample = [151 151];    % Number of spatial samples in the aperture.  Use odd number
        centerZ = 0;                   % Theoretical center of lens (length-wise) in the z coordinate
        
        % When we draw the lens we store the figure handle here
        fHdl = [];
        
        % Black Box Model
        BBoxModel=[]; % Empty
    end
    
    properties (SetAccess = private)
        centerRay = [];                 % for use for ideal Lens
        inFocusPosition = [0 0 0];
    end
    
    methods (Access = public)
        
        %Multiple element lens constructor
        function obj = lens(varargin)
            
            % Initialize with the default lens file
            lensFileName = '2ElLens.dat';
            obj.fileRead(lensFileName);
            obj.name = '2ElLens';
            
            if isempty(varargin), return;
            elseif isodd(length(varargin))
                error('pair/value pairs required');
            end
            
            % Some parameters are sent in as parameter/value pairs
            % Set them here.
            for ii=1:2:length(varargin)
                p = ieParamFormat(varargin{ii});
                switch p
                    case 'name'
                        obj.name = varargin{ii+1};
                    case 'type'
                        obj.type = varargin{ii+1};
                    case 'surfacearray'
                        obj.surfaceArray = varargin{ii+1};
                    case 'aperturesample'
                        obj.apertureSample = varargin{ii+1};  %must be a 2 element vector
                        %                     case 'aperturemiddled'
                        %                         % d for Diameter
                        %                         % Let's git rid of this and only have an aperture
                        %                         % diameter for the surface elements.  Then we must
                        %                         % make sure that the lens.draw routine uses that
                        %                         % aperture. (BW,AJ)
                        %                         obj.apertureMiddleD = varargin{ii+1};
                    case 'apertureindex'
                        obj.apertureIndex(varargin{ii+1});
                    case 'focallength'
                        obj.focalLength = varargin{ii+1};
                    case 'diffractionenabled'
                        obj.diffractionEnabled = varargin{ii+1};
                    case 'wave'
                        obj.set('wave', varargin{ii+1});
                    case 'filename'
                        obj.fileRead(varargin{ii+1});
                        [~,n,~] = fileparts(varargin{ii+1});
                        obj.name = n;
                    case {'figure handle','fhdl'}
                        obj.fHdl = varargin{ii+1};
                    case {'blackboxmodel';'blackbox';'bbm'} % equivalent BLACK BOX MODEL
                        obj.BBoxModel = varargin{ii+1};
                        
                    otherwise
                        error('Unknown parameter %s\n',varargin{ii});
                end
            end
        end
        
        %% Helper
        function files = list(~,varargin)
            % List and summarize the lenses in data/lens
            p = inputParser;
            
            % If you want the list returned without a print
            p.addParameter('quiet',false,@islogical);
            p.parse(varargin{:});
            
            quiet = p.Results.quiet;  
            
            files = dir(fullfile(piRootPath,'data','lens','*.dat'));
            if quiet, return; end
            
            for ii=1:length(files)
                fprintf('%d - %s\n',ii,files(ii).name);
            end
        end
        
        %% Get properties
        function res = get(obj,pName,varargin)
            % Get various derived lens properties though this call
            pName = ieParamFormat(pName);
            switch pName
                case 'name'
                    res = obj.name;
                case 'wave'
                    res = obj.wave;
                case 'nwave'
                    res = length(obj.wave);
                case 'type'
                    res = obj.type;
                case {'nsurfaces','numels'}
                    % Should be nsurfaces
                    res = length(obj.surfaceArray);
                case {'lensthickness','totaloffset'}
                    % This is the size (in mm) from the front surface to
                    % the back surface.  The last surface is at 0, so the
                    % position of the first surface is the total size.
                    sArray = obj.surfaceArray;
                    res    = -1*sArray(1).get('zpos');
                    % We have a special case when rt is the ideal. 
                    % Not handled properly yet.  Need a validation for the
                    % 'ideal' case.
                    %
                    %                     if strcmp(rtType,'ideal')
                    %                         % The 'ideal'thin lens has a front surface at
                    %                         res = 0;
                    %                     end
                    

                case 'offsets'
                    % Offsets format (like PBRT files) from center/zPos
                    % data
                    res = obj.offsetCompute();
                case 'surfacearray'
                    % lens.get('surface array',[which surface])
                    if isempty(varargin), res = obj.surfaceArray;
                    else                  res = obj.surfaceArray(varargin{1});
                    end
                    
                case {'indexofrefraction','narray'}
                    nSurf = obj.get('nsurfaces');
                    sWave  = obj.surfaceArray(1).wave;
                    res = zeros(length(sWave),nSurf);
                    for ii=1:nSurf
                        res(:,ii) = obj.surfaceArray(ii).n(:)';
                    end
                case {'refractivesurfaces'}
                    % logicalList = lens.get('refractive surfaces');
                    % Returns
                    %  1 at the positions of refractive surfaces, and
                    %  0 at diaphgrams
                    nSurf = obj.get('nsurfaces');
                    res = ones(nSurf,1);
                    for ii=1:nSurf
                        if strcmp(obj.surfaceArray(ii).subtype,'diaphragm')
                            res(ii) = 0;
                        end
                    end
                    res = logical(res);
                case {'nrefractivesurfaces'}
                    % nMatrix = lens.get('n refractive surfaces')
                    %
                    % The refractive indices for each wavelength of each
                    % refractive surface.  The returned matrix has size
                    % nWave x nSurface
                    lst = find(obj.get('refractive surfaces'));
                    nSurfaces = length(lst);
                    nWave = obj.get('nwave');
                    res = zeros(nWave,nSurfaces);
                    for ii = 1:length(lst)
                        res(:,ii) = obj.surfaceArray(lst(ii)).n(:);
                    end
                    
                case 'sradius'
                    % spherical radius of curvature of this surface.
                    % lens.get('sradius',whichSurface)
                    if isempty(varargin), this = 1;
                    else this = varargin{1};
                    end
                    res = obj.surfaceArray(this).sRadius;
                case 'sdiameter'
                    % lens.get('s diameter',nS);
                    % Aperture diameter of this surface.
                    % lens.get('sradius',whichSurface)
                    if isempty(varargin), this = 1;
                    else this = varargin{1};
                    end
                    res = obj.surfaceArray(this).apertureD;
                case {'aperture','diaphragm'}
                    % lens.get('aperture')
                    % Returns the surface number of the aperture
                    % (diaphragm)
                    s = obj.surfaceArray;
                    for ii=1:length(s)
                        if strcmp(s(ii).subtype,'diaphragm')
                            res = ii;
                            return;
                        end
                    end
                case 'aperturesample'
                    res =  obj.apertureSample ;
                case {'middleapertured','aperturemiddled'}
                    % The middle aperture is the diameter of the diaphragm,
                    % which is normally the middle aperture.  We should
                    % change this somehow for clarity.  Or we should find
                    % the diaphragm and return its diameter.
                    %
                    % The diameter of the middle aperture
                    % units are mm
                    res = obj.apertureMiddleD;
                    
                case {'blackboxmodel';'blackbox';'bbm'} % equivalent BLACK BOX MODEL
                    param=varargin{1};  %witch field of the black box to get
                    res = obj.bbmGetValue(param);
                    
                case {'lightfieldtransformation';'lightfieldtransf';'lightfield'} % equivalent BLACK BOX MODEL
                    if nargin >2
                        param = varargin{1};  %witch field of the black box to get
                        param = ieParamFormat(param);
                        switch param
                            case {'2d'}
                                res = obj.bbmGetValue('abcd');
                            case {'4d'}
                                abcd = obj.bbmGetValue('abcd');
                                nW=size(abcd,3);
                                dummy=eye(4);
                                for li=1:nW
                                    abcd_out(:,:,li)=dummy;
                                    abcd_out(1:2,1:2,li)=abcd(:,:,li);
                                end
                                res=abcd_out;
                            otherwise
                                error(['Not valid :',param ,' as type for  Light Field tranformation']);
                        end
                    else
                        res = obj.bbmGetValue('abcd');
                    end
                    
                    
                case {'opticalsystem'; 'optsyst';'opticalsyst';'optical system structure'}
                    % Get the equivalent optical system structure generated
                    % by Michael's script
                    % Can be specify refractive indices for object and
                    % image space as varargin {1} and {2}
                    if nargin >2
                        n_ob=varargin{1};    n_im=varargin{2};
                        OptSyst=obj.bbmComputeOptSyst(n_ob,n_im);
                    else
                        OptSyst=obj.bbmComputeOptSyst();
                    end
                    res = OptSyst;
                    
                otherwise
                    error('Unknown parameter %s\n',pName);
            end
        end
        
        %% Set
        function set(obj,pName,val,varargin)
            pName = ieParamFormat(pName);
            switch pName
                case 'wave'
                    % lens.set('wave',val);
                    % The wavelength var is annoying. This could go away
                    % some day.  But for now, the wavelength set is
                    % ridiculous because there are so many copies of wave.
                    % We should set it here rather than addressing every
                    % surface element. 
                    obj.wave = val;
                    nSurfaces = obj.get('n surfaces');
                    for ii=1:nSurfaces
                        obj.surfaceArray(ii).set('wave', val);
                    end
                case 'surfacearray'
                    % lens.set('surface array',surfaceArrayClass);
                    obj.surfaceArray = val;
                case 'middleaperturediameter'
                    % Set the middle aperture to diameter val (mm)
                    middleAperture = obj.get('aperture');
                    obj.surfaceArray(middleAperture).apertureD = val;
                case 'aperturesample'
                    obj.apertureSample = val;
                case 'surfacearrayindex'
                    index=varargin{1};
                    % lens.set('surface array',val);
                    obj.surfaceArray(index) = val;
                case 'apertureindex'
                    % lens.set('aperture index',val);
                    % Indicates which of the surfaces is the aperture.
                    index=val;
                    obj.apertureIndex(index); % Set the surface (specify by varargin) as aperture
                case 'nall'
                    % Set the index of refraction to all the surfaces
                    nSurfaces = obj.get('n surfaces');
                    for ii=1:nSurfaces
                        obj.surfaceArray(ii).n = val;
                    end
                case 'nrefractivesurfaces'
                    % lens.set('n refractive surfaces',nMatrix)
                    %
                    % The nMatrix should be nWave x nSurfaces where
                    % nSurfaces are only the refractive surfaces.  This
                    % sets the index of refraction to all those surfaces
                    
                    % Indices of the refractive surfaces
                    lst = find(obj.get('refractive surfaces'));
                    
                    % For every column in val, put it in the next
                    % refractive index of the lst.
                    kk = 0;   % Initiate the counter
                    for ii = 1:length(lst)
                        kk = kk + 1;
                        obj.surfaceArray(lst(ii)).n(:) = val(:,kk);
                    end
                    
                case {'effectivefocallength';'efl';'focalradius';'imagefocalpoint';...
                        'objectfocalpoint';'imageprincipalpoint';'objectprincipalpoint';...
                        'imagenodalpoint';'objectnodalpoint';'abcd';'abcdmatrix'}
                    % Build the field to append
                    obj.bbmSetField(pName,val);
                case {'figurehandle','fhdl'}
                    obj.fHdl = val;
                    
                case {'blackboxmodel';'blackbox';'bbm'}
                    % Get the parameters from the optical system structure
                    % to build an  equivalent Black Box Model of the lens.
                    % The OptSyst structure has to be built with the
                    % function 'paraxCreateOptSyst' Get 'new' origin for
                    % optical axis
                    OptSyst=val;
                    %                     z0 = OptSyst.cardPoints.lastVertex;
                    z0=paraxGet(OptSyst,'lastVertex');
                    % Variable to append
                    %                     efl=OptSyst.cardPoints.fi; %focal lenght of the system
                    efl=paraxGet(OptSyst,'efl');
                    obj.bbmSetField('effectivefocallength',efl);
                    %                     pRad = OptSyst.Petzval.radius; % radius of curvature of focal plane
                    pRad = paraxGet(OptSyst,'focalradius'); % radius of curvature of focal plane
                    obj.bbmSetField('focalradius',pRad);
                    %                     Fi=OptSyst.cardPoints.dFi;     %Focal point in the image space
                    Fi= paraxGet(OptSyst,'imagefocalpoint')-z0;     %Focal point in the image space
                    obj.bbmSetField('imagefocalpoint',Fi);
                    %                     Hi=OptSyst.cardPoints.dHi; % Principal point in the image space
                    Hi= paraxGet(OptSyst,'imageprincipalpoint')-z0; % Principal point in the image space
                    obj.bbmSetField('imageprincipalpoint',Hi);
                    %                     Ni=OptSyst.cardPoints.dNi;     % Nodal point in the image space
                    Ni=paraxGet(OptSyst,'imagenodalpoint')-z0;    % Nodal point in the image space
                    obj.bbmSetField('imagenodalpoint',Ni);
                    %                     Fo=OptSyst.cardPoints.dFo-z0; %Focal point in the object space
                    Fo=paraxGet(OptSyst,'objectfocalpoint')-z0; %Focal point in the object space
                    obj.bbmSetField('objectfocalpoint',Fo);
                    %                     Ho=OptSyst.cardPoints.dHo-z0; % Principal point in the object space
                    Ho=paraxGet(OptSyst,'objectprincipalpoint')-z0; % Principal point in the object space
                    obj.bbmSetField('objectprincipalpoint',Ho);
                    %                     No=OptSyst.cardPoints.dNo-z0; % Nodal point in the object space
                    No=paraxGet(OptSyst,'objectnodalpoint')-z0; % Nodal point in the object space
                    obj.bbmSetField('objectnodalpoint',No);
                    M = paraxGet(OptSyst,'abcd'); % The 4 coefficients of the ABCD matrix of the overall system
                    obj.bbmSetField('abcd',M);
                    
                otherwise
                    error('Unknown parameter %s\n',pName);
            end
            
        end
        
    end
    
    
    %% Not sure why these are private. (BW).
    methods (Access = private)
        
        % These values should be obtained using the 'get' function, which
        % is public.  So, obj.get('aperture mask') would be the way to call
        % this function.  Similarly for the others.
        
        function apertureMask = apertureMask(obj)
            % Identify the grid points on the circular aperture.
            %
            
            % Here is the full sampling grid for the resolution and
            % aperture radius
            aGrid = obj.fullGrid;
            
            % We assume a circular aperture. This mask is 1 for the sample
            % points within a circle of the aperture radius
            firstApertureRadius = obj.surfaceArray(1).apertureD/2;
            apertureMask = (aGrid.X.^2 + aGrid.Y.^2) <= firstApertureRadius^2;
            % vcNewGraphWin;  mesh(double(apertureMask))
            
        end
        
        function elementsSet(obj, sOffset, sRadius, sAperture, sN)
            % Copies the lens elements typically from a PBRT file into the
            % correct slots of a surfaceArray object. The object is then
            % attached to the lens.
            %
            % The input vectors should have equal length, and be of type
            % double.  They are the surface offset (relative to ...) in mm,
            % radius (mm), aperture (mm) and index of refraction.
            %
            % The conventional way to set the surface array is to create a
            % surface array object and call lens.set('surface array',obj)
            %
            % This function is used by lens.fileRead, which converts the
            % PBRT lens data into a surface array.
            
            % Check argument size
            if (length(sOffset)     ~= length(sRadius) || ...
                    length(sOffset) ~= length(sAperture) || ...
                    length(sOffset) ~= size(sN,1))
                error('Input vectors must be of equal length');
            end
            
            % If no wavelength dependence of index of refraction specified,
            % we assume constant across all measurement wavelengths
            % sN is nSurfaces x nWave
            if (size(sN,2) == 1)
                sN = repmat(sN, [1 length(obj.wave)]);
            end
            
            %create array of surfaces
            obj.surfaceArray = surfaceC();
            
            %compute surface array centers
            centers = obj.centersCompute(sOffset, sRadius);
            
            for i = 1:length(sOffset)
                obj.surfaceArray(i) = ...
                    surfaceC('sCenter', centers(i, :), ...
                    'sRadius', sRadius(i), ...
                    'apertureD', sAperture(i), 'n', sN(i, :));
            end
            
        end
                
    end
end


