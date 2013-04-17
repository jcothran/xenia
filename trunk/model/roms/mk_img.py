import numpy as np   
import matplotlib  
# Force matplotlib to not use any Xwindows backend.
matplotlib.use('Agg')

import matplotlib.pyplot as plt  

data = np.loadtxt('test2.csv', delimiter=',')

#x, y = dat[:,0], dat[:,1]

#heatmap, xedges, yedges = np.histogram2d(x, y, bins=50)  
#extent = [xedges[0], xedges[-1], yedges[0], yedges[-1]]  
#plt.clf()  
#plt.imshow(heatmap, extent=extent)  
#plt.show() 

data=np.flipud(data)
#data=np.fliplr(data)
sp=plt.subplot(111,aspect=1.)
sp.imshow(data)

plt.savefig('great.png') 
