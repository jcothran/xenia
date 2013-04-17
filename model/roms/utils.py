import numpy as np

def mk_array(shape,data2):
  #print "mk_array %s %s" % (shape, len(shape))

  if len(shape) == 1:
    #print "mk_1"
    data1 = np.ones( (1,shape[0]) )

  if len(shape) == 2:
    #print "mk_2"
    data1 = np.ones( (1,shape[0],shape[1]) )

  if len(shape) == 3:
    #print "mk_3"
    data1 = np.ones( (1,shape[0],shape[1],shape[2]) )

  if len(shape) == 4:
    #print "mk_4"
    data1 = np.ones( (1,shape[0],shape[1],shape[2],shape[3]) )

  data1[0] = data2

  return data1

