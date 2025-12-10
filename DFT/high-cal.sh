#!/bin/sh
##用于批量自动计算二维材料的临界剥离电荷密度，搭配auto-cal.sh使用
##2023.7.3
cp high-cal0.1.log high-cal0.1.log.old
#cp error-auto.log error-auto.log.old
#cat /dev/null >  error-auto.log
cat /dev/null > high-cal0.1.log
run_task=2 ####允许进行的任务数
#####清理保存日志#####
while (ls structure | grep vasp );do
#echo yes
run_num=$(qstat | grep auto-boli | wc -l) 
 while [ $run_num -ge $run_task ]   ### 统计正在进行的任务数,确定是否暂停
 do
 echo $run_num
 sleep 1h
 run_num=$(qstat | grep auto-boli | wc -l)
 done


  for  struc  in  $( ls structure | grep vasp | head -n 2);do #####将材料移入计算文件夹准备开始计算
  # echo $str
  mkdir calculate/$struc
  mkdir calculate/$struc/0.0
  mv structure/$struc  calculate/$struc/0.0
  ####拷贝计算文件###
  cp cal-lib/{vasp.pbs,INCAR,vk} calculate/$struc/0.0
  cp cal-lib/auto-cal.sh  calculate/$struc
  cd calculate/$struc/0.0
  cp $struc POSCAR
  rm POTCAR
  elec_total=$(vaspkit < vk | grep "Total Valence Electrons" | awk '{print $4}')  
  sed -i "s/NELECT=/NELECT=$elec_total/g" INCAR
  qsub vasp.pbs
  cd ..
  nohup ./auto-cal.sh &>> nohup.out &  ### &>>重定向输出 防止都输出在这个脚本中
  cd ../..
  ######标记正在运行的结构########
  echo "$struc $(date) " >> result_file/0.1-cal/run-structure.txt    ####删除由 auto-cal.sh 控制
  ######标记正在运行的结构########
  sleep 10s
  done

sleep 30s

done

echo "Calculation completed"


