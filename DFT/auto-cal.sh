#!/bin/bash
# date:2024-4-15
#自动计算最佳剥离电荷密度
run_jb=$(grep "当前脚本进程号" nohup.out | awk '{print $2}')
kill -9 $run_jb
sleep 10s
cp nohup.out nohup.out.old
cp error-auto.log error-auto.log.old
cat /dev/null >  error-auto.log
cat /dev/null > nohup.out
######输出当前运行的脚本的进程号####
echo "当前脚本进程号" $$
ps -aef | grep auto-cal.sh 
######标记正在运行的结构########
#file_name=$(basename `pwd`)
#echo $file_name >> ../../result_file/run-structure.txt    ####
######标记正在运行的结构########

#########最高电荷密度与电子数#####
cd 0.0

#####检查原子数，少于10个原子就扩胞
 while !(grep finish date.log) ###感叹号逻辑取反
 do
 sleep 10m
 done

vaspkit << EOF
411
1
EOF
total_atomnum=$(cat POSCAR_REV |wc -l)
if [ $total_atomnum -le 18 ];then
vaspkit << EOF
401
1
2 2 1
EOF
cp SC221.vasp POSCAR
rm POTCAR date.log
cp  ../../../cal-lib/INCAR .
elec_total=$(vaspkit < vk | grep "Total Valence Electrons" | awk '{print $4}')
sed -i "s/NELECT=/NELECT=$elec_total/g" INCAR
elec_total=$(printf "%.0f" `echo $elec_total`)
 if [ $elec_total -le 300 ];then ####更换计算核数和并行数
   sed -i "s/NCORE=4/NCORE=4/g" INCAR
   sed -i "s/ntasks-per-node=32/ntasks-per-node=32/g" vasp.pbs
 elif [ $elec_total -le 500 ];then
   sed -i "s/NCORE=4/NCORE=6/g" INCAR
   sed -i "s/ntasks-per-node=32/ntasks-per-node=48/g" vasp.pbs
 else 
   sed -i "s/NCORE=4/NCORE=8/g" INCAR
   sed -i "s/ntasks-per-node=32/ntasks-per-node=64/g" vasp.pbs
 fi
qsub vasp.pbs
echo  total atom $total_atomnum -8
else
rm POTCAR
elec_total=$(vaspkit < vk | grep "Total Valence Electrons" | awk '{print $4}')
elec_total=$(printf "%.0f" `echo $elec_total`)
 if [ $elec_total -le 300 ];then ####更换计算核数和并行数
   sed -i "s/NCORE=4/NCORE=4/g" INCAR
   sed -i "s/ntasks-per-node=32/ntasks-per-node=32/g" vasp.pbs
 elif [ $elec_total -le 500 ];then
   sed -i "s/NCORE=4/NCORE=6/g" INCAR
   sed -i "s/ntasks-per-node=32/ntasks-per-node=48/g" vasp.pbs
 else
   sed -i "s/NCORE=4/NCORE=8/g" INCAR
   sed -i "s/ntasks-per-node=32/ntasks-per-node=64/g" vasp.pbs
echo "total_atomnum more than 10"
fi
fi

xx_b=$(printf "%.4f" `awk 'NR==3{print $1}' POSCAR`)
xy_b=$(printf "%.4f" `awk 'NR==3{print $2}' POSCAR`)
yx_b=$(printf "%.4f" `awk 'NR==4{print $1}' POSCAR`)
yy_b=$(printf "%.4f" `awk 'NR==4{print $2}' POSCAR`)
sur_area_before=$(echo "($xx_b*$yy_b)-($xy_b*$yx_b)" | bc)
elec_max=$(printf "%.4f" `echo "$sur_area_before*0.4"|bc`)
count_max=$(printf "%.0f" `echo "$elec_max*10"|bc`)
count_max=$(printf "%.0f" `echo "$count_max/5"|bc`) ####取5的倍数
count_max=$(printf "%.0f" `echo "$count_max*5"|bc`)
echo "max elec  $count_max"

cd ..
#########最高电荷密度与电子数#####
######步长0.5计算#########
for ((count_num=0; count_num<=$count_max; count_num=$count_num+5))
do
sleep 10s
elec_num=$(printf "%.1f" `echo "scale=1;$count_num/10"|bc`) ###转换成小数
 while !(grep finish $elec_num/date.log) ###感叹号逻辑取反
 do
 sleep 10m
 done
######输出笛卡尔坐标#####
cd $elec_num
vaspkit << EOF
411
1
EOF
vaspkit << EOF
411
2
EOF

########输出优化前后的剥离距离######
elec_num_x10=$(echo $elec_num*10| bc)
elec_num_x10=$(printf "%.0f" $elec_num_x10)
if [ $elec_num_x10 -eq 0 ];then  ###避免在0的时候减为负数
   awk '{print $3}' POSCAR_REV > z-pos.txt #打印第三列
   tail -n +9 z-pos.txt > z-pos1.txt # 输出 c轴坐标
   cat z-pos1.txt | sort -n > z-pos2.txt #排序
   min_pos=$(head -3 z-pos2.txt | tail -1 | tr -d $'\r')
   max_pos=$(tail -3 z-pos2.txt | head -1 | tr -d $'\r')
   dis_pos=$(echo $max_pos-$min_pos| bc)
   echo $dis_pos
else
 elec_num_qyg=$(echo $elec_num-0.5| bc)
 elec_num_qyg=$(printf "%.1f" $elec_num_qyg) ###防止出现.5而进入不了文件夹
 cd ../$elec_num_qyg ####进入上一个计算步骤，防止在同一个步骤中多次优化剥离小于10埃，而总剥离大于10埃
   awk '{print $3}' POSCAR_REV > z-pos.txt #打印第三列
   tail -n +9 z-pos.txt > z-pos1.txt # 输出 c轴坐标
   cat z-pos1.txt | sort -n > z-pos2.txt #排序
   min_pos=$(head -3 z-pos2.txt | tail -1 | tr -d $'\r')
   max_pos=$(tail -3 z-pos2.txt | head -1 | tr -d $'\r')
   dis_pos=$(echo $max_pos-$min_pos| bc)
   echo $dis_pos
 cd ../$elec_num   ####回到当前步骤，防止在同一个步骤中多次优化剥离小于10埃，而总剥离大于10埃
fi
   
   awk '{print $3}' POSCAR_REV > z-pos.txt #打印第三列
   tail -n +9 z-pos.txt > z-pos1.txt # 输出 c轴坐标  输出z-pos1以供计算力是时候使用 统计原子个数
 
  
   awk '{print $3}' CONTCAR_REV > z-con.txt #打印第三列
   tail -n +9 z-con.txt > z-con1.txt # 输出 c轴坐标
   cat z-con1.txt | sort -n > z-con2.txt #排序
   min_con=$(head -3 z-con2.txt | tail -1 | tr -d $'\r')
   max_con=$(tail -3 z-con2.txt | head -1 | tr -d $'\r')
   dis_con=$(echo $max_con-$min_con| bc)
   echo $dis_con

   dis_boli=$(echo $dis_con-$dis_pos| bc)
   dis_boli=$(printf "%.0f" $dis_boli)
#######输出优化前后的剥离距离#########
cd ..

 if ( grep "reached required accuracy"  $elec_num/runvasp.log ); then #检测计算成功没
   cd $elec_num
   elec_next=$(printf "%.1f" `echo "scale=1;$elec_num+0.5"|bc`)
   if [ $dis_boli -ge 10 ];then ###检测是否剥离
      cd ..
      break 3
   elif [ $count_num -eq $count_max ];then
     cd  ..
     file_name=$(basename `pwd`)
     echo "$file_name cal max $count_max  $elec_num  FORCE" >> ../../result_file/0.1-cal/out.txt
     exit
   elif (ls ..|grep -w  $elec_next) ;then ####断点续算
      cd ..
      echo "Breakpoint continuation cal $elec_next"
   else
#     elec_next=$(printf "%.1f" `echo "scale=1;$elec_num+0.5"|bc`)
     mkdir ../$elec_next    
     cp INCAR CONTCAR vk vasp.pbs ../$elec_next
     cd ../$elec_next ; cp CONTCAR POSCAR
     rm POTCAR
     elec_total=$(vaspkit < vk | grep "Total Valence Electrons" | awk '{print $4}')
     elec_old=$(echo $elec_total-$elec_num| bc)
     elec_new=$(echo $elec_total-$elec_next| bc)
     sed -i "s/NELECT=$elec_old/NELECT=$elec_new/g" INCAR  ###替换电子数
     sed -i "s/IBRION =  1/IBRION =  2/g" INCAR   ###换回离子步算法
     qsub vasp.pbs
     cd ..
   fi 
   ######剥离检测程序######
   
 elif (grep -E  "CONTCAR|300 F="  $elec_num/runvasp.log);then    # #如果要续算
   #######检测是否剥离#####
   if [ $dis_boli -ge 10 ];then
      echo "exfoliate but optimization not completed $elec_num"
      echo "reached required accuracy"  >>  $elec_num/runvasp.log  ####人为输入计算完成提示
      count_num=$(echo $count_num-5|bc)
   else
      echo "Recalculation for $elec_num" >> error-auto.log
      cd $elec_num
      cp CONTCAR  POSCAR
      rm date.log
      qsub vasp.pbs
      count_num=$(echo $count_num-5|bc)                                      ###修改计算进度
      cd ..
   fi
   #######检测是否剥离#####
elif (grep -E  "Error EDDDAV"  $elec_num/runvasp.log);then ##出现多离子步无法收敛 更换牛顿算法
     cd $elec_num
     if [ `grep EDDDAV EDDDAV.log| wc -l` -ge 2 ];then
         exit
     fi
     echo EDDDAV >> EDDDAV.log
     cp CONTCAR  POSCAR
     sed -i "s/IBRION =  2/IBRION =  1/g" INCAR   ###更换离子步算法
     rm date.log
     qsub vasp.pbs
     count_num=$(echo $count_num-5|bc)
     #sed -i "s/IBRION =  1/IBRION =  2/g" INCAR   ###换回离子步算法
     cd ..
 else                                           # 如果出现其他情况 就直接停止计算
   file_name=$(basename `pwd`)
   echo "$file_name cal failed  $elec_num FORCE" >> ../../result_file/0.1-cal/out.txt
   exit
fi
done
######步长0.5计算

######步长0.1细化计算########
count_max=$(echo $count_num-1|bc)
count_num=$(echo $count_num-4|bc)
elec_num=$(printf "%.1f" `echo "scale=1;$count_num/10"|bc`) ###转换成小数
elec_last=$(printf "%.1f" `echo "scale=1;$elec_num-0.1"|bc`)
####判断细化计算第一个是否存在#####
if (ls | grep -w $elec_num) ;then ####断点续算
     #cd ..
     echo "Breakpoint continuation cal $elec_num"
else
     cd $elec_last
     mkdir ../$elec_num
     cp INCAR CONTCAR vk vasp.pbs ../$elec_num
     cd ../$elec_num; cp CONTCAR POSCAR
     rm POTCAR
     elec_total=$(vaspkit < vk | grep "Total Valence Electrons" | awk '{print $4}')
     elec_old=$(echo $elec_total-$elec_last| bc)
     elec_new=$(echo $elec_total-$elec_num | bc)
     sed -i "s/NELECT=$elec_old/NELECT=$elec_new/g" INCAR  ###替换电子数
     sed -i "s/IBRION =  1/IBRION =  2/g" INCAR   ###换回离子步算法
     qsub vasp.pbs
     cd ..
fi
######判断细化计算第一个是否存在######

for ((; count_num<=$count_max; count_num=$count_num+1))
do
sleep 10s
elec_num=$(printf "%.1f" `echo "scale=1;$count_num/10"|bc`) ###转换成小数
 while !(grep finish $elec_num/date.log) ###感叹号逻辑取反
 do
 sleep 10m
 done

######输出笛卡尔坐标#####
cd $elec_num
vaspkit << EOF
411
1
EOF
vaspkit << EOF
411
2
EOF

########输出优化前后的剥离距离######
 elec_num_qyg=$(echo $elec_num-0.1| bc)
 elec_num_qyg=$(printf "%.1f" $elec_num_qyg) ###防止出现.5而进入不了文件夹
 cd ../$elec_num_qyg ####进入上一个计算步骤，防止在同一个步骤中多次优化剥离小于10埃，而总剥离大于10埃
   awk '{print $3}' POSCAR_REV > z-pos.txt #打印第三列
   tail -n +9 z-pos.txt > z-pos1.txt # 输出 c轴坐标
   cat z-pos1.txt | sort -n > z-pos2.txt #排序
   min_pos=$(head -3 z-pos2.txt | tail -1 | tr -d $'\r')
   max_pos=$(tail -3 z-pos2.txt | head -1 | tr -d $'\r')
   dis_pos=$(echo $max_pos-$min_pos| bc)
   echo $dis_pos
 cd ../$elec_num

   awk '{print $3}' POSCAR_REV > z-pos.txt #打印第三列
   tail -n +9 z-pos.txt > z-pos1.txt # 输出 c轴坐标  输出z-pos1以供计算力是时候使用 统计原子个数

   awk '{print $3}' CONTCAR_REV > z-con.txt #打印第三列
   tail -n +9 z-con.txt > z-con1.txt # 输出 c轴坐标
   cat z-con1.txt | sort -n > z-con2.txt #排序
   min_con=$(head -3 z-con2.txt | tail -1 | tr -d $'\r')
   max_con=$(tail -3 z-con2.txt | head -1 | tr -d $'\r')
   dis_con=$(echo $max_con-$min_con| bc)
   echo $dis_con

   dis_boli=$(echo $dis_con-$dis_pos| bc)
   dis_boli=$(printf "%.0f" $dis_boli)
#######输出优化前后的剥离距离#########
cd ..

 if ( grep "reached required accuracy"  $elec_num/runvasp.log ); then #检测计算成功没
   cd $elec_num
   elec_next=$(printf "%.1f" `echo "scale=1;$elec_num+0.1"|bc`)
   if [ $dis_boli -ge 10 ];then ###检测是否剥离
      #cd ..
      #file_name=$(basename `pwd`) #####输出优化前后的面积####
      xx_b=$(printf "%.4f" `awk 'NR==3{print $1}' POSCAR`)
      xy_b=$(printf "%.4f" `awk 'NR==3{print $2}' POSCAR`)
      yx_b=$(printf "%.4f" `awk 'NR==4{print $1}' POSCAR`)
      yy_b=$(printf "%.4f" `awk 'NR==4{print $2}' POSCAR`)
      xx_a=$(printf "%.4f" `awk 'NR==3{print $1}' CONTCAR`)
      xy_a=$(printf "%.4f" `awk 'NR==3{print $2}' CONTCAR`)
      yx_a=$(printf "%.4f" `awk 'NR==4{print $1}' CONTCAR`)
      yy_a=$(printf "%.4f" `awk 'NR==4{print $2}' CONTCAR`)

      sur_area_before=$(echo "($xx_b*$yy_b)-($xy_b*$yx_b)" | bc)
      sur_area_after=$(echo "($xx_a*$yy_a)-($xy_a*$yx_a)" | bc)
      #######开始算受力#######
      mkdir force   ####利用0.0下的结构算受力
      cp ../0.0/{CONTCAR,vasp.pbs} force
      cp  ../../../cal-lib/{INCAR-st,vk} force
      cd force 
      cp INCAR-st INCAR
      cp CONTCAR POSCAR
      rm POTCAR
      elec_total=$(vaspkit < vk | grep "Total Valence Electrons" | awk '{print $4}') ####执行vk并输出电荷密度
      elec_new=$(echo $elec_total-$elec_num| bc)
      sed -i "s/NELECT=/NELECT=$elec_new/g" INCAR  ###替换电子数
      if (ls | grep  date.log);then  ###检查和提交任务
         echo "Breakpoint continuation cal force"
     else
         qsub vasp.pbs
     fi
      sleep 10s
       while !(grep finish date.log) ###等待单点能计算完成
       do
       echo "Wait for the calculation to complete, check every 10 minutes"
       sleep 10m
       done
######为force文件夹输出笛卡尔坐标
vaspkit << EOF
411
1
EOF
vaspkit << EOF
411
2
EOF
######为force文件夹输出笛卡尔坐标
      #######输force中的面积####
      xx_b=$(printf "%.4f" `awk 'NR==3{print $1}' POSCAR`)
      xy_b=$(printf "%.4f" `awk 'NR==3{print $2}' POSCAR`)
      yx_b=$(printf "%.4f" `awk 'NR==4{print $1}' POSCAR`)
      yy_b=$(printf "%.4f" `awk 'NR==4{print $2}' POSCAR`)
      xx_a=$(printf "%.4f" `awk 'NR==3{print $1}' CONTCAR`)
      xy_a=$(printf "%.4f" `awk 'NR==3{print $2}' CONTCAR`)
      yx_a=$(printf "%.4f" `awk 'NR==4{print $1}' CONTCAR`)
      yy_a=$(printf "%.4f" `awk 'NR==4{print $2}' CONTCAR`)

      sur_area_before=$(echo "($xx_b*$yy_b)-($xy_b*$yx_b)" | bc) ###这是是0电荷结构
     # sur_area_after=$(echo "($xx_a*$yy_a)-($xy_a*$yx_a)" | bc) ###前面算过就用前面的就是剥离前结构
      #######输force中的面积####

      awk '{print $3}' POSCAR_REV > z-pos.txt #打印第三列
      tail -n +9 z-pos.txt > z-pos1.txt # 输出 c轴坐标
      cat z-pos1.txt | sort -n > z-pos2.txt #排序
      awk '{print $3}' CONTCAR_REV > z-con.txt #打印第三列
      tail -n +9 z-con.txt > z-con1.txt # 输出 c轴坐标  force.py需要调用

      atom_num=$(awk 'END {print NR}' z-pos1.txt) ##输出原子个数
      atom_num=$(echo $atom_num+2 | bc)    ####包括了力表的前两行
      echo "atom num $atom_num"
      #######输出原子受力########
      grep -A $atom_num  -m 1 TOTAL-FORCE OUTCAR > f.dat #change atom_Nu +2
      sed -i '/TOTAL-FORCE/d' f.dat
      sed -i '/--/d' f.dat
      awk -F " " '{print $6}' f.dat > f.txt
      #######输出原子受力########
      ########算出上下层受力#####
      cp ../../../../cal-lib/force.py .
      /public/software/apps/anaconda3/5.2.0/bin/python3.6 force.py
      force_down=$(awk 'NR==1{print $1}' force.txt)
      force_up=$(awk 'NR==2{print $1}' force.txt)
      ########算出上下层受力####
      cd ../..    ####0.0力计算结束
      file_name=$(basename `pwd`)
      cp $elec_num/CONTCAR  ../../result_file/0.1-cal/$file_name
      echo "0.0 force"
      echo "$file_name  $sur_area_before  $sur_area_after  $elec_num  $force_down $force_up" >> ../../result_file/0.1-cal/out.txt
      break 3
   elif [ $count_num -eq $count_max ];then
      elec_num=$(printf "%.1f" `echo $elec_num+0.1| bc`) ###进入0.5步长的剥离结果
      cd ../$elec_num
      xx_b=$(printf "%.4f" `awk 'NR==3{print $1}' POSCAR`)
      xy_b=$(printf "%.4f" `awk 'NR==3{print $2}' POSCAR`)
      yx_b=$(printf "%.4f" `awk 'NR==4{print $1}' POSCAR`)
      yy_b=$(printf "%.4f" `awk 'NR==4{print $2}' POSCAR`)
      xx_a=$(printf "%.4f" `awk 'NR==3{print $1}' CONTCAR`)
      xy_a=$(printf "%.4f" `awk 'NR==3{print $2}' CONTCAR`)
      yx_a=$(printf "%.4f" `awk 'NR==4{print $1}' CONTCAR`)
      yy_a=$(printf "%.4f" `awk 'NR==4{print $2}' CONTCAR`)

      sur_area_before=$(echo "($xx_b*$yy_b)-($xy_b*$yx_b)" | bc)
      sur_area_after=$(echo "($xx_a*$yy_a)-($xy_a*$yx_a)" | bc)
      #######开始算受力#######
      mkdir force   ####利用0.0下的结构算受力
      cp ../0.0/{CONTCAR,vasp.pbs} force
      cp  ../../../cal-lib/{INCAR-st,vk} force
      cd force
      cp INCAR-st INCAR
      cp CONTCAR POSCAR
      rm POTCAR
      elec_total=$(vaspkit < vk | grep "Total Valence Electrons" | awk '{print $4}') ####执行vk并输出电荷密度
      elec_new=$(echo $elec_total-$elec_num| bc)
      sed -i "s/NELECT=/NELECT=$elec_new/g" INCAR  ###替换电子数
      if (ls | grep  date.log);then  ###检查和提交任务
         echo "Breakpoint continuation cal force"
     else
         qsub vasp.pbs
     fi
      sleep 10s
       while !(grep finish date.log) ###等待单点能计算完成
       do
       echo "Wait for the calculation to complete, check every 10 minutes"
       sleep 10m
       done
######为force文件夹输出笛卡尔坐标
vaspkit << EOF
411
1
EOF
vaspkit << EOF
411
2
EOF
######为force文件夹输出笛卡尔坐标
      #######输force中的面积####
      xx_b=$(printf "%.4f" `awk 'NR==3{print $1}' POSCAR`)
      xy_b=$(printf "%.4f" `awk 'NR==3{print $2}' POSCAR`)
      yx_b=$(printf "%.4f" `awk 'NR==4{print $1}' POSCAR`)
      yy_b=$(printf "%.4f" `awk 'NR==4{print $2}' POSCAR`)
      xx_a=$(printf "%.4f" `awk 'NR==3{print $1}' CONTCAR`)
      xy_a=$(printf "%.4f" `awk 'NR==3{print $2}' CONTCAR`)
      yx_a=$(printf "%.4f" `awk 'NR==4{print $1}' CONTCAR`)
      yy_a=$(printf "%.4f" `awk 'NR==4{print $2}' CONTCAR`)

      sur_area_before=$(echo "($xx_b*$yy_b)-($xy_b*$yx_b)" | bc) ###这是是0电荷结构
     # sur_area_after=$(echo "($xx_a*$yy_a)-($xy_a*$yx_a)" | bc) ###前面算过就用前面的就是剥离前结构
      #######输force中的面积####

      awk '{print $3}' POSCAR_REV > z-pos.txt #打印第三列
      tail -n +9 z-pos.txt > z-pos1.txt # 输出 c轴坐标
      cat z-pos1.txt | sort -n > z-pos2.txt #排序
      awk '{print $3}' CONTCAR_REV > z-con.txt #打印第三列
      tail -n +9 z-con.txt > z-con1.txt # 输出 c轴坐标  force.py需要调用

      atom_num=$(awk 'END {print NR}' z-pos1.txt) ##输出原子个数
      atom_num=$(echo $atom_num+2 | bc)    ####包括了力表的前两行
      echo "atom num $atom_num"
      #######输出原子受力########
      grep -A $atom_num  -m 1 TOTAL-FORCE OUTCAR > f.dat #change atom_Nu +2
      sed -i '/TOTAL-FORCE/d' f.dat
      sed -i '/--/d' f.dat
      awk -F " " '{print $6}' f.dat > f.txt
      #######输出原子受力########
      ########算出上下层受力#####
      cp ../../../../cal-lib/force.py .
      /public/software/apps/anaconda3/5.2.0/bin/python3.6  force.py
      force_down=$(awk 'NR==1{print $1}' force.txt)
      force_up=$(awk 'NR==2{print $1}' force.txt)
      ########算出上下层受力####
      cd ../..  ###0.0力计算结束
      file_name=$(basename `pwd`)
      cp $elec_num/CONTCAR  ../../result_file/0.1-cal/$file_name
      echo "0.0 force"
      echo "$file_name  $sur_area_before  $sur_area_after  $elec_num  $force_down $force_up" >> ../../result_file/0.1-cal/out.txt
      break 3
   elif (ls ..|grep -w $elec_next) ;then ####断点续算
      cd ..
      echo "Breakpoint continuation cal $elec_next"
   else
#     elec_next=$(printf "%.1f" `echo "scale=1;$elec_num+0.1"|bc`)
     mkdir ../$elec_next    
     cp INCAR CONTCAR vk vasp.pbs ../$elec_next
     cd ../$elec_next ; cp CONTCAR POSCAR
     rm POTCAR
     elec_total=$(vaspkit < vk | grep "Total Valence Electrons" | awk '{print $4}')
     elec_old=$(echo $elec_total-$elec_num| bc)
     elec_new=$(echo $elec_total-$elec_next| bc)
     sed -i "s/NELECT=$elec_old/NELECT=$elec_new/g" INCAR  ###替换电子数
     qsub vasp.pbs
     cd ..
   fi 
   ######剥离检测程序######
   
 elif (grep -E  "CONTCAR|300 F="  $elec_num/runvasp.log);then    # #如果要续算
   #######检测是否剥离#####
   if [ $dis_boli -ge 10 ];then
      echo "exfoliate but optimization not completed $elec_num"
      echo "reached required accuracy"  >>  $elec_num/runvasp.log  ####人为输入计算完成提示
      count_num=$(echo $count_num-1|bc)
   else 
      echo "Recalculation for $elec_num" >> error-auto.log
      cd $elec_num
      cp CONTCAR  POSCAR
      rm date.log
      qsub vasp.pbs 
      count_num=$(echo $count_num-1|bc)                                      ###修改计算进度
      cd ..
   fi
   #######检测是否剥离#####
  elif (grep -E  "Error EDDDAV"  $elec_num/runvasp.log);then ##出现多离子步无法收敛 更换牛顿算法
     cd $elec_num
     if [ `grep EDDDAV EDDDAV.log| wc -l` -ge 2 ];then
         exit
     fi
     echo EDDDAV >> EDDDAV.log
     cp CONTCAR  POSCAR
     sed -i "s/IBRION =  2/IBRION =  1/g" INCAR   ###更换离子步算法
     rm date.log
     qsub vasp.pbs
     count_num=$(echo $count_num-1|bc)
     #sed -i "s/IBRION =  1/IBRION =  2/g" INCAR   ###换回离子步算法
     cd ..
 else                                           # 如果出现其他情况 就直接停止计算
   file_name=$(basename `pwd`)
   echo "$file_name cal failed  $elec_num FORCE" >> ../../result_file/0.1-cal/out.txt
   exit
fi
done
######步长0.1细化计算######
sed -i "/$file_name/d" ../../result_file/0.1-cal/run-structure.txt
echo "Calculation completed"
