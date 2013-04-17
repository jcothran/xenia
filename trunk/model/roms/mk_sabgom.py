#note: this script assumes mk_sabgom_grd.py has already been run once to create the necessary sabgom_grd.mat file for matlab/octave processing in later steps

import scipy.io as sio
from pydap.client import open_url

import numpy as np

import utils

import os
import sys
fc_offset = int(sys.argv[1])
depth= sys.argv[2]
print fc_offset
print depth

import subprocess
#sys.exit(0) #debug

dataset = open_url('http://omgsrv1.meas.ncsu.edu:8080/thredds/dodsC/fmrc/sabgom/SABGOM_Forecast_Model_Run_Collection_best.ncd')

###############################################################################################################
#### get sabgom data and save to .mat file 

#note: the utils.mk_array was done to get around an issue I was having with my numpy array getting trash values in savemat unless I wrapped the matrix within a 'singleton' dimension
# so (320,440) becomes (1,320,440) and then matrix squeezed here and in matlab to give the original (320,440) matrix

#obs vars
temp = dataset['temp']
#temp = temp[1,:,:,:]
temp = temp[fc_offset,:,:,:]
temp = utils.mk_array(temp.shape,temp)

salt = dataset['salt']
salt = salt[fc_offset,:,:,:]
salt = utils.mk_array(salt.shape,salt)

u = dataset['u']
u = u[fc_offset,:,:,:]
u = utils.mk_array(u.shape,u)

v = dataset['v']
v = v[fc_offset,:,:,:]
v = utils.mk_array(v.shape,v)

chl = dataset['chlorophyll']
chl = chl[fc_offset,:,:,:]
chl = utils.mk_array(chl.shape,chl)

phy = dataset['phytoplankton']
phy = phy[fc_offset,:,:,:]
phy = utils.mk_array(phy.shape,phy)

zoo = dataset['zooplankton']
zoo = zoo[fc_offset,:,:,:]
zoo = utils.mk_array(zoo.shape,zoo)


#support vars
um = dataset['mask_u']
um = um[:,:]
um = utils.mk_array(um.shape,um)

vm = dataset['mask_v']
vm = vm[:,:]
vm = utils.mk_array(vm.shape,vm)

ang = dataset['angle']
ang = ang[:,:]
ang = utils.mk_array(ang.shape,ang)

theta_s = dataset['theta_s']
theta_b = dataset['theta_b']
Tcline = dataset['Tcline']

Cs_r = dataset['Cs_r']
Cs_r = Cs_r[:]
Cs_r = utils.mk_array(Cs_r.shape,Cs_r)

hc = dataset['hc']

sio.savemat('sabgom.mat', {'temp':temp,'salt':salt,'u':u, 'v':v, 'chl':chl, 'phy':phy, 'zoo':zoo, 'um':um, 'vm':vm, 'ang':ang, 'theta_s':theta_s[0],'theta_b':theta_b[0],'Tcline':Tcline[0],'Cs_r':Cs_r,'hc':hc[0]})

#mat_contents = sio.loadmat('sabgom.mat')
#print mat_contents

###############################################################################################################
#### run octave to eval/create var.csv output which is the grid field for the given timestep and depth  

var_list = [temp,salt,chl,phy,zoo]
var_str_list = ['temp','salt','chl','phy','zoo']

for var,var_str in zip(var_list,var_str_list):

  if depth != '0' and depth != '-999': #middle model layers
    
    DEVNULL = open(os.devnull, 'w')
    #normally in the below function, junk1 = the forecast nc file and junk2 = forecast H grid, but we have pre-processed and hardcoded these as .mat referenced files
    subprocess.call(["octave","--eval", "roms_zslice('junk1','"+var_str+"',0,"+depth+",'junk2')"], stdout=DEVNULL, stderr=subprocess.STDOUT)

  elif depth == '0' or depth == '-999': #surface, bottom layers

    depth_index = 35
    if depth == '-999':
      depth_index = 0

    var = np.squeeze(var) #squeeze var now that we've already passed created .mat file
    #print var.shape
    np.savetxt(var_str+".csv", var[depth_index], delimiter=",")

#swap depth_name for file labels
depth_name = depth
if depth == '0':
  depth_name = 'surface'
elif depth == '-999':
  depth_name = 'bottom'


###############################################################################################################
#### make test1.csv(var,lon,lat) for shapefile 

lon_rho = dataset['lon_rho']
lon_rho = lon_rho[:,:]

lat_rho = dataset['lat_rho']
lat_rho = lat_rho[:,:]

#print lon_rho[0][0]
#print lat_rho[0][0]

data_temp = np.loadtxt('temp.csv', delimiter=',')
data_salt = np.loadtxt('salt.csv', delimiter=',')
data_chl = np.loadtxt('chl.csv', delimiter=',')
data_phy = np.loadtxt('phy.csv', delimiter=',')
data_zoo = np.loadtxt('zoo.csv', delimiter=',')

fileout = open('test1.csv', 'w')

fileout.write("temp,salt,chl,phy,zoo,lon,lat\n")

for x in range(0,320): #magic number - 320 is our grid width
  for y in range(0,440): #magic number - 440 is our grid height
    #if x > 315: #debug
    #  print "%s:%s:%s,%s,%s,%s\n" % (x,y,data_temp[x][y],data_salt[x][y],lon_rho[x][y],lat_rho[x][y])
    fileout.write("%s,%s,%s,%s,%s,%s,%s\n" % (data_temp[x][y],data_salt[x][y],data_chl[x][y],data_phy[x][y],data_zoo[x][y],lon_rho[x][y],lat_rho[x][y]))

fileout.close()

#replace our NaN with 0 for shapefile generation  
import fileinput
for line in fileinput.FileInput("test1.csv",inplace=1):
  line = line.replace("nan","0.0")
  print line,


###############################################################################################################
#### determine forecast datetime filename label 

time = dataset['time']
#time = time[:]
time_units = time.units
time_base = time_units.split()[2]

print time_base
print time[fc_offset]

fc_time = str(int(time[fc_offset][0]))

p = subprocess.Popen(["date", "--date="+time_base+" +"+fc_time+" hours", "+%Y%m%d%H"], stdout=subprocess.PIPE)
datetime, err = p.communicate()
datetime = datetime.rstrip()
print datetime

###############################################################################################################
#### make output shapefile 

import csv
from shapely.geometry import Point, mapping
from fiona import collection

schema = { 'geometry': 'Point', 'properties': { 'temp': 'float', 'salt': 'float', 'chl': 'float', 'phy': 'float', 'zoo':'float' } }
with collection(
    datetime+"_"+depth_name+".shp", "w", "ESRI Shapefile", schema) as output:
    with open('test1.csv', 'rb') as f:
        reader = csv.DictReader(f)
        for row in reader:
            point = Point(float(row['lon']), float(row['lat']))
            output.write({
                'properties': {
                    'temp': row['temp'],
                    'salt': row['salt'],
                    'chl': row['chl'],
                    'phy': row['phy'],
                    'zoo': row['zoo']
                },
                'geometry': mapping(point)
            })



#datetime = '2013041605' #debug
#error - below command kept adding newlines to args
#p = subprocess.Popen(["/usr/bin/zip", "shapefiles/"+datetime+"_"+depth+".zip", datetime+"_"+depth+".*"], stdout=subprocess.PIPE)
#err = p.communicate()
#print err

cmd = 'zip shapefiles/'+datetime+'_'+depth_name+'.zip '+datetime+'_'+depth_name+'.*'
os.system(cmd)
cmd = 'zip shapefiles/'+datetime+'_'+depth_name+'.zip some.prj'
os.system(cmd)
cmd = 'rm '+datetime+'_'+depth_name+'.*'
os.system(cmd)


