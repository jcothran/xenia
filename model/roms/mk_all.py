import os

import subprocess
import time

os.system("date")

#fc_offset_list = [-1,-3]
#depth_list = [5]
fc_offset_list = [-1,-3,-5,-7,-9,-11,-12]
depth_list = [0,5,10,20,30,40,50,100,1000,-999]

for fc_offset in fc_offset_list:
  print fc_offset
  fc_offset = str(fc_offset)
  for depth in depth_list:
    print depth
    depth = str(depth)

    #time.sleep(0.5)
    os.system("python mk_sabgom.py "+fc_offset+" "+depth)
    #subprocess.Popen("python mk_sabgom.py "+fc_offset+" "+depth, shell=True)
    #p = subprocess.Popen(["date", "--date="+time_base+" +"+fc_time+" hours", "+%Y%m%d%H"], stdout=subprocess.PIPE)
    #err = p.communicate()

os.system("date")
