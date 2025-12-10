#!/home/zhanghonglin/opt/anaconda3/bin/python3
####导入库函数
import numpy
import os
from ase.io import read
from ase.io import write
from ase.build import surface
from ase import Atoms
from pymatgen.core.structure import Structure
from pymatgen.analysis.diffraction.xrd import XRDCalculator
#####
filenames = os.listdir("bulk")
os.chdir("bulk") ###进入bulk目录
for i in range(len(filenames)):
    new_fn = filenames[i].replace('(','_').replace(')','_') ###替换括号为_
    os.rename(filenames[i],new_fn)
os.chdir("..") 
#exit()
filenames = os.listdir("bulk")###重新加载文件名
for filename in filenames:
######查询晶面#####
   #filename = "Al.cif"
   os.chdir("bulk") ###进入bulk目录
   print(filename)
   bulk_atom=read(filename,format='cif') ####建表面模型时用的数据
   surname_i = filename.split('.')[0] + '.i' + '.cif' ####split是以点进行分割获取文件名 然后添加vasp后缀
   surname_d = filename.split('.')[0] + '.d' + '.cif' ####split是以点进行分割获取文件名 然后添加vasp后缀
   structure = Structure.from_file(filename)
   xrd_calc = XRDCalculator()
   pattern = xrd_calc.get_pattern(structure)
   os.chdir("../surface") ###进入sur目录
   #print("2*Theta Intensity hkl d_hkl(angstrom)")
   print_log = open("xrd.log",'w')
   for two_theta, intensity, hkls, d_hkl in zip(pattern.x, pattern.y, pattern.hkls, pattern.d_hkls):
       hkl_tuples = [hkl["hkl"] for hkl in hkls]
       for hkl in hkl_tuples:
           label = " ".join(map(str, hkl)) ####输出不包含括号和逗号 join是拼接
           print(f'{two_theta:.2f} {intensity:.2f} {label} {d_hkl:.3f}',file=print_log)
   print_log.close()
######查询晶面######

######读取xrd数据到数组并输出最弱的晶面
   xrd_all = numpy.loadtxt('xrd.log')
   ID_I_MAX = numpy.argmax(xrd_all[:,1])
   ID_D_MAX = numpy.argmax(xrd_all[:,-1])
   #print(I_MAX)
   #print(xrd_all.shape[1])
   #print(xrd_all) ##数组从0开始计数
   if 7 == xrd_all.shape[1]:
      hi = xrd_all[ID_I_MAX,2]
      ki = xrd_all[ID_I_MAX,3]
      li = xrd_all[ID_I_MAX,5]
      hd = xrd_all[ID_D_MAX,2]
      kd = xrd_all[ID_D_MAX,3]
      ld = xrd_all[ID_D_MAX,5]
   else:
      hi = xrd_all[ID_I_MAX,2]
      ki = xrd_all[ID_I_MAX,3]
      li = xrd_all[ID_I_MAX,4]
      hd = xrd_all[ID_D_MAX,2]
      kd = xrd_all[ID_D_MAX,3]
      ld = xrd_all[ID_D_MAX,4]
   hi = round(hi) ####取整
   ki = round(ki)
   li = round(li)
   hd = round(hd) ####取整
   kd = round(kd)
   ld = round(ld)
   print(filename,hi,ki,li,hd,kd,ld)

######
   sur_atom_i=surface(bulk_atom,(hi,ki,li),3,vacuum=20)
   sur_atom_d=surface(bulk_atom,(hd,kd,ld),3,vacuum=20)
   write(surname_i,sur_atom_i,format='cif')
   write(surname_d,sur_atom_d,format='cif')
   os.chdir("..") ###返回起始目录
#hkl_log.close()
