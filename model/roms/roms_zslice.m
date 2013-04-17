function [data,x,y,t,grd] = roms_zslice(file,var,time,depth,grd)
% $Id$
% Get a constant-z slice out of a ROMS history, averages or restart file
% [data,x,y] = roms_zslice(file,var,time,depth,grd)
%
% Inputs
%    file = his or avg nc file
%    var = variable name
%    time = time index in nc file
%    depth = depth in metres of the required slice
%    grd (optional) is the structure of grid coordinates from roms_get_grid 
%
% Outputs
%    
%    data = the 2d slice at requested depth 
%    x,y = horizontal coordinates
%    t = time in days for the data
%
% John Wilkin

% whos grd

depth = -abs(depth);

% open the history or averages file
%nc = netcdf(file);

% if ~nc_isvar(file,var)
%   error([ 'Variable ' var ' is not present in file ' file])
% end

% get the time
% time_variable = nc_attget(file,var,'time');
% if isempty(time_variable)
%  time_variable = 'scrum_time'; % doubt this is really of any use any more 
% end

% if nc_varsize(file,time_variable)<time
%  disp(['Requested time index ' int2str(time) ' not available'])
%  disp(['There are ' int2str(nc_varsize(file,time_variable)) ...
%    ' time records in ' file])
%  error(' ')
% end
%t = roms_get_date(file,time); % gets output in matlab datenum convention

% open a opendap URL
%nc = netcdf('http://omgsrv1.meas.ncsu.edu:8080/thredds/dodsC/fmrc/sabgom/SABGOM_Forecast_Model_Run_Collection_best.ncd','r');

% check the grid information
if nargin<5 | (nargin==5 & isempty(grd))
  % no grd input given so try to get grd_file name from the history file
  disp(['debug3'])
  grd_file = file;
  grd = roms_get_grid(grd_file,file);
else
  % if isstruct(grd)
  %  disp(['debug4'])
  % end
  if isstr(grd)
    grd = roms_get_grid(grd,file);
  else
    % input was a grd structure but check that it includes the z values
    if ~isfield(grd,'z_r')
      error('grd does not contain z values');
    end
  end
end


% open a opendap URL
% nc = netcdf('http://omgsrv1.meas.ncsu.edu:8080/thredds/dodsC/fmrc/sabgom/SABGOM_Forecast_Model_Run_Collection_best','r');

% download a subset of the variable temp
% temp = nc{'temp'}(end,1,661:996,77:588);

% download the attribute "missing_value" and replace every
% occurrences by NaN in our local copy
% temp(temp == nc{'temp'}.missing_value) = NaN;

% close the connection
% close(nc);

% get the data to be zsliced
% data = nc_varget(file,var,[time-1 0 0 0],[1 -1 -1 -1]);

% temp = 'temp';
data = load('sabgom.mat', var);
data = data.(var);
%data = s;
%disp([data])

% THIS STEP TO ACCOMMODATE NC_VARGET RETURNING A TIME LEVEL WITH
% LEADING SINGLETON DIMENSION - BEHAVIOR THAT DIFFERS BETWEEN JAVA AND
% MATLAB OPENDAP INTERFACES - 11 Dec, 2012
data = squeeze(data);

% slice at requested depth
[data,x,y] = roms_zslice_var(data,1,depth,grd);

%disp([size(grd.lon_rho)])

switch roms_cgridpos(size(data),grd)
  case 'u'
    mask = grd.mask_u;
  case 'v'
    mask = grd.mask_v;
  case 'psi'
    mask = grd.mask_psi;
  case 'rho'
    mask = grd.mask_rho;
end

% Apply mask to catch shallow water values where the z interpolation does
% not create NaNs in the data
if 1
dry = find(mask==0);
mask(dry) = NaN;
data = data.*mask;
end

#disp(['ok9'])

csvwrite(strcat(var, ".csv"),data)
