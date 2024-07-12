#!/usr/bin/env python

from __future__ import print_function
import enum
import mdtraj as md
import numpy as np

def calc_sasa(traj):
    # convert from Angstrom to nm for mdtraj compatibility
    radius=.14

    sasa = md.shrake_rupley(traj, probe_radius=radius, mode="residue")*10
    total_sasa = sasa.sum(axis=1)
    #print("Total SASA (Å^2): ", total_sasa)
    
    return total_sasa

def calc_sasa_per_res(traj):
    # convert from Angstrom to nm for mdtraj compatibility
    radius=.14

    sasa = md.shrake_rupley(traj, probe_radius=radius, mode="residue")*10
    #print(sasa)
    total_sasa = sasa.sum(axis=1)
#    print("Total SASA (Å^2): ", total_sasa)
    
    return sasa

if __name__ == "__main__":
    from sys import argv
    
    #    outfile = argv[1]
    
    trajfile1 = argv[1]
    trajfile2 = argv[2]
    topfile = argv[3]
    
    if topfile:
        traj1 = md.load(trajfile1, top=topfile)
        traj2 = md.load(trajfile2, top=topfile)
    else:
        traj1 = md.load(trajfile1)
        traj2 = md.load(trajfile2)
        
    traj3 = traj1+traj2
        
        
    protein_sel = traj3.top.select ('resid 13 15 19 21 44 47 48 56 59 60 63 69 71 74 76 86 88 104 106 108 11 24 28 32 34 39 90 91')
    protein_traj = traj3.atom_slice (protein_sel)
    

    ss = calc_sasa(protein_traj)
    ss_res = calc_sasa_per_res(protein_traj)
       
    np.savetxt("sasa.dat", ss, fmt="%.3f")
    np.savetxt("sasa_per_res.dat", ss_res, fmt="%.3f")
    
