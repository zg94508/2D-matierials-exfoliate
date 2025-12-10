#!/home/zhanghonglin/opt/anaconda3/bin/python3
####对表面原子多余的进行删除
import numpy
import os
from scipy.signal import argrelextrema
import scipy.signal as sg
from ase.io import read
from ase.io import write
from ase.build import surface
from ase import Atoms
#########
fenbu = numpy.array([0,0.0011,0.0044,0.01,0.0178,0.0278,0.04,0.0544,0.0711,0.09,0.1111,0.1344,0.16,0.1878,0.2178,0.25,0.2844,0.3211,0.36,0.4011,0.4444,0.49,0.5378,0.5878,0.64,0.6944,0.7511,0.81,0.8711,0.9344,1,0.9344,0.8711,0.81,0.7511,0.6944,0.64,0.5878,0.5378,0.49,0.4444,0.4011,0.36,0.3211,0.2844,0.25,0.2178,0.1878,0.16,0.1344,0.1111,0.09,0.0711,0.0544,0.04,0.0278,0.0178,0.01,0.0044,0.0011,0])
####关于z方向2次函数分布
filenames = os.listdir("surface")
#os.chdir("surface") ###进入bulk目录
###创建矩阵
filename_index = 0
zp_i_d = numpy.empty((len(filenames),2),dtype=object) ###创建存储原子z投影极小值和极大值比例的矩阵


for filename in filenames:
   os.chdir("surface") ###进入surface目录
   print(filename)
   sur_atom=read(filename,format='cif') ####建表面模型时用的数据
   surname = filename.split('.')[0] + '.' + filename.split('.')[1]  + '.vasp' ####split是以点进行分割获取文件名 然后添加vasp后缀
   print(surname,"first")
   os.chdir("../sur_last")
   num_atom = numpy.shape(sur_atom.positions)
   z_max = numpy.max(sur_atom.positions[:,2]) ####取第3列最大值  
   z_min = numpy.min(sur_atom.positions[:,2])
   z_max = round(z_max+3,1) ###保留小数点后一位
   z_min = round(z_min-3,1)
   z_d= round((z_max-z_min)*10)
#   print(z_max,z_min,z_d)
   labelx = 0 ####给下面的数组坐标计数
   z_p = numpy.zeros([z_d+1,2])
#   for i in numpy.linspace(z_min,z_max,z_d).round(1): ###这个会导致其中某些数字缺失，暂时解决不了
   for i in numpy.arange(z_min,z_max,0.1).round(1): ####普通的range不行 numpy的arange也不行因为是小数步长,不准确，目前只能只能让初始数组长度+1临时解决
#       print(labelx,i)
       z_p[labelx,0] = round(i,1)       
       labelx = labelx+1
   #####给数组赋值z坐标
    
   for i in range(num_atom[0]):
       zz = round(sur_atom.positions[i,2],1)
       lb = numpy.where(z_p[:,0] == zz )
       for n in range(61):
           z_p[lb[0]+n-31,1] = z_p[lb[0]+n-31,1]+fenbu[n] 
   zp_max = numpy.max(z_p[:,1])
   zp_max_index = numpy.array([])
   for i in range(1,len(z_p[:,1])-1):
       if (z_p[i,1] >= z_p[i-1,1] and z_p[i,1] >= z_p[i+1,1] ): ####这个是用来判断极值的，考虑到旁边与极值相等的情况
          ans = numpy.array([i])
          zp_max_index = numpy.concatenate((zp_max_index,ans))
   zp_maxok_index =  numpy.array([]) ###创建空数组 
   zp_max_index = zp_max_index.astype(int) ###转化为整型数组,索引不能有小数点
   for i in range(len(zp_max_index)):####比较局部极大值与最大值差
       if (z_p[zp_max_index[i],1] > zp_max*0.9):
          zp_max_index0 = numpy.array([zp_max_index[i]])
          zp_maxok_index = numpy.concatenate((zp_maxok_index,zp_max_index0))
   zp_maxok_index = zp_maxok_index.astype(int) ####转化为整型数组,索引不能有小数点

   if (zp_maxok_index[0] != zp_maxok_index[-1]):####防止编号相等而输出为空值
      zp_min = numpy.min(z_p[zp_maxok_index[0]:zp_maxok_index[-1],1]) ###局部最小值索引如果最小值大于最大值0.6就不输出vasp
      if (zp_min < zp_max*0.7 ):
         write(surname,sur_atom,format='vasp')     
         print(surname)

   os.chdir("../zp")
   zp_txt = filename.split('.')[0] + filename.split('.')[1]  + '.txt' ####split是以点进行分割获取文件名 然后添加txt后缀
   numpy.savetxt(zp_txt,z_p)
   zp_i_d[filename_index,0] = surname
   zp_i_d[filename_index,1] = zp_min/zp_max
   filename_index = filename_index+1
   os.chdir("..")
print(zp_i_d)
# os.chdir("sur_last") ###进入surface目录
# print(os.getcwd())
# for i in range(0,len(zp_i_d[:,0]),2):
#    print(i)
#    if (zp_i_d[i,1] > zp_i_d[i+1,1]):
#       if os.path.exists(zp_i_d[i,0]):  ###判断文件是否存在防止不存在而报错 只保留i类型或者d类型的结构
#          os.remove(zp_i_d[i,0])
#          print("删除",zp_i_d[i,0])
#    else:
#       if os.path.exists(zp_i_d[i+1,0]):
#          os.remove(zp_i_d[i+1,0])
#          print("删除",zp_i_d[i+1,0])
