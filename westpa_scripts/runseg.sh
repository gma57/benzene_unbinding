#!/bin/bash

if [ -n "$SEG_DEBUG" ] ; then
  set -x
  env | sort
fi

cd $WEST_SIM_ROOT
mkdir -pv $WEST_CURRENT_SEG_DATA_REF
cd $WEST_CURRENT_SEG_DATA_REF

sed "s/RAND/$WEST_RAND16/g" $WEST_SIM_ROOT/common_files/md.in > md.in
#ln -sv $WEST_SIM_ROOT/common_files/T4_Benz_hmass.prmtop .
ln -sv $WEST_SIM_ROOT/common_files/reference.pdb .

#if [ "$WEST_CURRENT_SEG_INITPOINT_TYPE" = "SEG_INITPOINT_CONTINUES" ]; then
#  sed "s/RAND/$WEST_RAND16/g" $WEST_SIM_ROOT/common_files/md.in > md.in
#  ln -sv $WEST_PARENT_DATA_REF/seg.ncrst ./parent.ncrst
#elif [ "$WEST_CURRENT_SEG_INITPOINT_TYPE" = "SEG_INITPOINT_NEWTRAJ" ]; then
#  sed "s/RAND/$WEST_RAND16/g" $WEST_SIM_ROOT/common_files/md.in > md.in
#  ln -sv $WEST_PARENT_DATA_REF/bstate.ncrst ./parent.ncrst
#fi

export CUDA_DEVICES=(`echo $CUDA_VISIBLE_DEVICES_ALLOCATED | tr , ' '`)
export CUDA_VISIBLE_DEVICES=${CUDA_DEVICES[$WM_PROCESS_INDEX]}

echo "RUNSEG.SH: CUDA_VISIBLE_DEVICES_ALLOCATED = " $CUDA_VISIBLE_DEVICES_ALLOCATED
echo "RUNSEG.SH: WM_PROCESS_INDEX = " $WM_PROCESS_INDEX
echo "RUNSEG.SH: CUDA_VISIBLE_DEVICES = " $CUDA_VISIBLE_DEVICES

$PMEMD  -O -i md.in   -p T4_Benz_hmass.prmtop -c parent.ncrst \
           -r seg.ncrst -x seg.nc      -o seg.log    -inf seg.nfo

RMSD=$(mktemp)
COMMAND="         parm T4_Benz_hmass.prmtop\n"
COMMAND="$COMMAND trajin $WEST_CURRENT_SEG_DATA_REF/parent.ncrst\n"
COMMAND="$COMMAND trajin $WEST_CURRENT_SEG_DATA_REF/seg.nc\n"
COMMAND="$COMMAND reference reference.pdb \n"
COMMAND="$COMMAND autoimage \n"
COMMAND="$COMMAND strip :WAT,Na+,Cl- \n"
COMMAND="$COMMAND align :1-164@CA,C,N,O reference \n"
COMMAND="$COMMAND nativecontacts mindist :165 :1-164 out dist.dat \n"
COMMAND="$COMMAND symmrmsd reference :BNZ@/C nofit out $RMSD \n"
COMMAND="$COMMAND go\n"

echo -e $COMMAND | $CPPTRAJ

cat dist.dat | tail -n +2 | awk '{print $4}' > dist.txt
rm dist.dat
cat $RMSD | tail -n +2 | awk {'print $2'} > rmsd.txt
paste rmsd.txt dist.txt | awk {'print $1 , $2'} > $WEST_PCOORD_RETURN
rm rmsd.txt dist.txt

cp T4_Benz_hmass.prmtop $WEST_TRAJECTORY_RETURN
cp seg.nc $WEST_TRAJECTORY_RETURN

cp T4_Benz_hmass.prmtop $WEST_RESTART_RETURN
cp seg.ncrst $WEST_RESTART_RETURN/parent.ncrst

cp seg.log $WEST_LOG_RETURN

rm $RMSD $DIST T4_Benz_hmass.prmtop reference.pdb
