###原子上下层受力计算#######
import numpy as np #numpy简写为np

atom_z_initial=np.loadtxt('./z-con1.txt')
#atom_z_reorder=np.loadtxt('./z-con2.txt')
atom_z_initial=np.around(atom_z_initial,decimals=4)
#atom_z_initial=list(atom_z_initial)
#atom_z_reorder=np.around(atom_z_reorder,decimals=4)
#atom_z_initial=list(atom_z_initial)
atom_force=np.loadtxt('./f.txt')
atom_force=np.around(atom_force,decimals=3)
#atom_force=list(atom_force)
#print(atom_z_initial)
#print(atom_force)
atom_num=len(atom_force)
atom_num_half=atom_num/2
if atom_num%2==0:  ###判断是奇数还是偶数个原子
    atom_num_down=round(atom_num_half)+1
    atom_num_up=round(atom_num_half)+1
else:
    atom_num_down=round(atom_num_half)
    atom_num_up=round(atom_num_half)+1
print(atom_num_half,atom_num_down,atom_num_up)
atom_z_force=np.vstack((atom_z_initial,atom_force))
atom_z_force=np.around(atom_z_force,decimals=3)
#print(atom_z_force)
atom_z_force=atom_z_force[:,atom_z_force[0,:].argsort()]
atom_z_force=list(atom_z_force)
print(atom_z_force)
force_down=sum(atom_z_force[1][0:atom_num_down])
force_up=sum(atom_z_force[1][atom_num_up:])
with open('./force.txt','w+') as force_file: ##打开文件，覆写完成后回自动关闭
     print(force_down,file=force_file)
     print(force_up,file=force_file)

