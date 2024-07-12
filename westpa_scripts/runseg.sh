#!/bin/bash

if [ -n "$SEG_DEBUG" ] ; then
  set -x
  env | sort
fi

cd $WEST_SIM_ROOT
mkdir -pv $WEST_CURRENT_SEG_DATA_REF
cd $WEST_CURRENT_SEG_DATA_REF

ln -sv $WEST_SIM_ROOT/common_files/bound_new.prmtop .
ln -sv $WEST_SIM_ROOT/common_files/reference.pdb .
ln -sv $WEST_SIM_ROOT/common_files/ired.prmtop .
ln -sv $WEST_SIM_ROOT/bstates/cpptraj_s2.in .
ln -sv $WEST_SIM_ROOT/bstates/calculateSASA.py .

#echo $WEST_PARENT_DATA_REF

if [ "$WEST_CURRENT_SEG_INITPOINT_TYPE" = "SEG_INITPOINT_CONTINUES" ]; then
  sed "s/RAND/$WEST_RAND16/g" $WEST_SIM_ROOT/common_files/md.in > md.in
  ln -sv $WEST_PARENT_DATA_REF/seg.ncrst ./parent.ncrst
elif [ "$WEST_CURRENT_SEG_INITPOINT_TYPE" = "SEG_INITPOINT_NEWTRAJ" ]; then
  sed "s/RAND/$WEST_RAND16/g" $WEST_SIM_ROOT/common_files/md.in > md.in
  ln -sv $WEST_PARENT_DATA_REF/bstate.ncrst ./parent.ncrst
fi

export CUDA_DEVICES=(`echo $CUDA_VISIBLE_DEVICES_ALLOCATED | tr , ' '`)
export CUDA_VISIBLE_DEVICES=${CUDA_DEVICES[$WM_PROCESS_INDEX]}

echo "RUNSEG.SH: CUDA_VISIBLE_DEVICES_ALLOCATED = " $CUDA_VISIBLE_DEVICES_ALLOCATED
echo "RUNSEG.SH: WM_PROCESS_INDEX = " $WM_PROCESS_INDEX
echo "RUNSEG.SH: CUDA_VISIBLE_DEVICES = " $CUDA_VISIBLE_DEVICES

$PMEMD  -O -i md.in   -p bound_new.prmtop -c parent.ncrst \
           -r seg.ncrst -x seg.nc      -o seg.log    -inf seg.nfo

COMMAND="         parm bound_new.prmtop\n"
COMMAND="$COMMAND trajin $WEST_CURRENT_SEG_DATA_REF/parent.ncrst\n"
COMMAND="$COMMAND trajin $WEST_CURRENT_SEG_DATA_REF/seg.nc\n"
COMMAND="$COMMAND reference reference.pdb \n"
COMMAND="$COMMAND autoimage \n"
COMMAND="$COMMAND strip :WAT,Na+,Cl- \n"
COMMAND="$COMMAND rms reference :6-115 \n"
COMMAND="$COMMAND rms :2-118 reference out rmsd_overall.dat nofit \n"
COMMAND="$COMMAND rms :2-118 reference perres perresout rmsd_perres.dat range 2-118 nofit \n"
COMMAND="$COMMAND rms :14,16,20,22,45,48,49,57,60,61,64,70,72,75,77,87,89,105,107,109,12,25,29,33,35,40,91,92@CA reference out rmsdpocket.dat nofit \n"
#COMMAND="$COMMAND nativecontacts :1 :2-118 writecontacts native-contacts.dat resout resout.dat \n" #contactpdb contactspdb.pdb \n"
COMMAND="$COMMAND trajout ired.nc\n"
COMMAND="$COMMAND go\n"

echo -e $COMMAND | $CPPTRAJ
cat rmsd_perres.dat | tail -n +2 | awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}' > $WEST_RMSDRES_RETURN
cat rmsdpocket.dat | tail -n +2 | awk '{print $2}' > $WEST_RMSDPOCKET_RETURN
cat rmsd_overall.dat | tail -n +2 | awk '{print $2}' > $WEST_RMSD_RETURN

rm rmsd_perres.dat rmsdpocket.dat rmsd_overall.dat


cpptraj -i cpptraj_s2.in >& cpptraj.out
cat iredout_s2 | tail -n +2 | awk '{print $2}' > s2
cat s2 s2 s2 s2 s2 s2 s2 s2 s2 s2 s2 > $WEST_ORD_RETURN


python $WEST_SIM_ROOT/common_files/get_coord.py
cp coord.npy $WEST_COORD_RETURN
rm coord.npy


RMSD=$(mktemp)
COMMAND="         parm bound_new.prmtop\n"
COMMAND="$COMMAND trajin $WEST_CURRENT_SEG_DATA_REF/parent.ncrst\n"
COMMAND="$COMMAND trajin $WEST_CURRENT_SEG_DATA_REF/seg.nc\n"
COMMAND="$COMMAND reference reference.pdb \n"
COMMAND="$COMMAND autoimage \n"
COMMAND="$COMMAND strip :WAT,Na+,Cl- \n"
COMMAND="$COMMAND nativecontacts mindist :1 :2-118 out dist.dat \n"
COMMAND="$COMMAND rms reference :6-115 \n"
COMMAND="$COMMAND rms reference @1-8,10,12,13,15,17-19,22,24-26,29 nofit out $RMSD \n"
COMMAND="$COMMAND go\n"

echo -e $COMMAND | $CPPTRAJ
cat dist.dat | tail -n +2 | awk '{print $4}' > dist.txt
rm dist.dat


python calculateSASA.py $WEST_CURRENT_SEG_DATA_REF/parent.ncrst $WEST_CURRENT_SEG_DATA_REF/seg.nc bound_new.prmtop
cat $RMSD | tail -n +2 | awk {'print $2'} > rmsd.txt
paste sasa.dat rmsd.txt dist.txt | awk {'print $1 , $2 , $3'} > $WEST_PCOORD_RETURN
paste sasa.dat rmsd.txt dist.txt | awk {'print $1 , $2 , $3'}
rm sasa.dat rmsd.txt dist.txt

cat sasa_per_res.dat > $WEST_SASAR_RETURN
rm sasa_per_res.dat 

## calculation of distance matrix

COMMAND="         parm bound_new.prmtop\n"
COMMAND="$COMMAND trajin $WEST_CURRENT_SEG_DATA_REF/seg.ncrst\n"
COMMAND="$COMMAND matrix :2-118&!@H= out dist_matrix_heavy.dat \n"
COMMAND="$COMMAND go\n"

echo -e $COMMAND | $CPPTRAJ





cp bound_new.prmtop $WEST_TRAJECTORY_RETURN
cp seg.nc $WEST_TRAJECTORY_RETURN

cp bound_new.prmtop $WEST_RESTART_RETURN
cp seg.ncrst $WEST_RESTART_RETURN/parent.ncrst

cp seg.log $WEST_LOG_RETURN

rm $RMSD $DIST bound_new.prmtop reference.pdb
