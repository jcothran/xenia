
import scipy.io as sio

from scipy.io import netcdf
filein = netcdf.netcdf_file('sabgom_grd_H.nc','r')
import numpy as np

import utils

#    { 'mask_rho','mask_psi','mask_u','mask_v','h','pm','pn','f','angle'};
mask_rho = filein.variables['mask_rho']
mask_rho = utils.mk_array(mask_rho.shape,mask_rho[:,:])

mask_psi = filein.variables['mask_psi']
mask_psi = utils.mk_array(mask_psi.shape,mask_psi[:,:])

mask_u = filein.variables['mask_u']
mask_u = utils.mk_array(mask_u.shape,mask_u[:,:])

mask_v = filein.variables['mask_v']
mask_v = utils.mk_array(mask_v.shape,mask_v[:,:])

h = filein.variables['h']
h = utils.mk_array(h.shape,h[:,:])

pm = filein.variables['pm']
pm = utils.mk_array(pm.shape,pm[:,:])

pn = filein.variables['pn']
pn = utils.mk_array(pn.shape,pn[:,:])

f = filein.variables['f']
f = utils.mk_array(f.shape,f[:,:])

angle = filein.variables['angle']
angle = utils.mk_array(angle.shape,angle[:,:])

#  varlist = {'x_rho','y_rho','x_u','y_u','x_v','y_v','x_psi','y_psi'};
x_rho = filein.variables['x_rho']
x_rho = utils.mk_array(x_rho.shape,x_rho[:,:])

y_rho = filein.variables['y_rho']
y_rho = utils.mk_array(y_rho.shape,y_rho[:,:])

x_u = filein.variables['x_u']
x_u = utils.mk_array(x_u.shape,x_u[:,:])

y_u = filein.variables['y_u']
y_u = utils.mk_array(y_u.shape,y_u[:,:])

x_v = filein.variables['x_v']
x_v = utils.mk_array(x_v.shape,x_v[:,:])

y_v = filein.variables['y_v']
y_v = utils.mk_array(y_v.shape,y_v[:,:])

x_psi = filein.variables['x_psi']
x_psi = utils.mk_array(x_psi.shape,x_psi[:,:])

y_psi = filein.variables['y_psi']
y_psi = utils.mk_array(y_psi.shape,y_psi[:,:])

#    { 'lon_rho','lat_rho','lon_psi','lat_psi',...
#    'lon_v','lat_v','lon_u','lat_u'};
lon_rho = filein.variables['lon_rho']
lon_rho = utils.mk_array(lon_rho.shape,lon_rho[:,:])

lat_rho = filein.variables['lat_rho']
lat_rho = utils.mk_array(lat_rho.shape,lat_rho[:,:])

lon_psi = filein.variables['lon_psi']
lon_psi = utils.mk_array(lon_psi.shape,lon_psi[:,:])

lat_psi = filein.variables['lat_psi']
lat_psi = utils.mk_array(lat_psi.shape,lat_psi[:,:])

lon_v = filein.variables['lon_v']
lon_v = utils.mk_array(lon_v.shape,lon_v[:,:])

lat_v = filein.variables['lat_v']
lat_v = utils.mk_array(lat_v.shape,lat_v[:,:])

lon_u = filein.variables['lon_u']
lon_u = utils.mk_array(lon_u.shape,lon_u[:,:])

lat_u = filein.variables['lat_u']
lat_u = utils.mk_array(lat_u.shape,lat_u[:,:])


sio.savemat('sabgom_grd.mat', {'mask_rho':mask_rho,'mask_psi':mask_psi,'mask_u':mask_u,'mask_v':mask_v,'h':h,'pm':pm,'pn':pn,'f':f,'angle':angle,'x_rho':x_rho,'y_rho':y_rho,'x_u':x_u,'y_u':y_u,'x_v':x_v,'y_v':y_v,'x_psi':x_psi,'y_psi':y_psi,'lon_rho':lon_rho,'lat_rho':lat_rho,'lon_psi':lon_psi,'lat_psi':lat_psi,'lon_v':lon_v,'lat_v':lat_v,'lon_u':lon_u,'lat_u':lat_u})


