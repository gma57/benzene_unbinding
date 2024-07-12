#!/bin/bash
set -x

TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

ln -sv $WEST_SIM_ROOT/common_files/bound_new.prmtop .
ln -sv $WEST_SIM_ROOT/common_files/reference.pdb .
ln -sv $WEST_SIM_ROOT/bstates/calculateSASA.py .
CUR_DIR=$WEST_STRUCT_DATA_REF
RMSD=$(mktemp)
DIST=$(mktemp)

COMMAND="         parm bound_new.prmtop\n"
COMMAND="$COMMAND trajin $CUR_DIR/bstate.ncrst\n"
COMMAND="$COMMAND reference reference.pdb \n"
COMMAND="$COMMAND autoimage \n"
COMMAND="$COMMAND strip :WAT,Na+,Cl- \n"
COMMAND="$COMMAND nativecontacts mindist :1 :2-118 out $DIST \n"
COMMAND="$COMMAND rms reference :6-115 \n"
COMMAND="$COMMAND rms reference @1-8,10,12,13,15,17-19,22,24-26,29 nofit out $RMSD \n"
COMMAND="$COMMAND go\n"

echo $WEST_STRUCT_DATA_REF

echo -e $COMMAND | $CPPTRAJ #> /dev/null
cat $DIST | tail -n +2 | awk '{print $4}' > dist.txt
#rm dist.dat

echo $WEST_STRUCT_DATA_REF
python calculateSASA.py $CUR_DIR/bstate.ncrst null.dat bound_new.prmtop
cat $RMSD | tail -n +2 | awk {'print $2'} > rmsd.txt
paste sasa.dat rmsd.txt dist.txt | awk {'print $1 , $2 , $3'} > $WEST_PCOORD_RETURN
paste sasa.dat rmsd.txt dist.txt | awk {'print $1 , $2 , $3'} > $CUR_DIR/test.dat

#cat $WEST_STRUCT_DATA_REF/pcoord.init > $WEST_PCOORD_RETURN 

cp $WEST_SIM_ROOT/common_files/bound_new.prmtop $WEST_TRAJECTORY_RETURN
cp $CUR_DIR/bstate.ncrst $WEST_TRAJECTORY_RETURN

cp $WEST_SIM_ROOT/common_files/bound_new.prmtop $WEST_RESTART_RETURN
cp $CUR_DIR/bstate.ncrst $WEST_RESTART_RETURN/parent.ncrst

