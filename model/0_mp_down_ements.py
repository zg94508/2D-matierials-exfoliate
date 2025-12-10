import pymatgen.core as mg
API_KEY = 'xxx'#填入你的mp密钥
import itertools
import random
import numpy as np
from mp_api.client import MPRester
########导入库函数

num_type = 2 ###元素种类
num_rndom = 100 ###随机取样数

all_symbols = ["H", "Li", "Be","C", "N", "O", "Na", 
            "Mg", "Al", "Si", "P", "S", "K", "Ca", "Sc", "Ti",
            "V", "Cr", "Mn", "Fe", "Co", "Ni", "Cu", "Zn", "Ga", "Ge", "As",
            "Se", "Br", "Rb", "Sr", "Y", "Zr", "Nb", "Mo", "Tc", "Ru", 
            "Rh", "Pd", "Ag", "Cd", "In", "Sn", "Sb", "Te", "Cs", 
            "Ba", "La", "Ta", "W", "Re", "Os"]
complx = list(itertools.combinations(all_symbols, num_type)) ###多元化物

complx_picked=random.sample(complx,num_rndom)  #####随机抽样300种
#print(complx_picked)
#Ements = ["O","Ti"]
for Ements in complx_picked :
    with MPRester(API_KEY) as mpr:
         docs =  mpr.materials.summary.search(
              elements=Ements, fields=["material_id","formula_pretty","structure"]
         )
#material_id = docs[0].material_id
#structure   =  docs[0].structure
#print(material_id,structure)
    for idoc in docs[0:5:100]:  # 保存前10个结构到cif文件
        idoc.structure.to(idoc.formula_pretty+idoc.material_id+".cif")
