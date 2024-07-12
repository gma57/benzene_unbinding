#!/usr/bin/env python

from __future__ import print_function
import enum
import mdtraj as md
import numpy as np

def calc_sasa(traj):
    # convert from Angstrom to nm for mdtraj compatibility
    radius=.14
    
    protein_sel = traj.top.select ('resid 13 15 19 21 44 47 48 56 59 60 63 69 71 74 76 86 88 104 106 108 11 24 28 32 34 39 90 91')
    protein_traj = traj.atom_slice (protein_sel)   ##[-1]

    sasa = md.shrake_rupley(protein_traj, probe_radius=radius, mode="atom")*10
    total_sasa = sasa.sum(axis=1)
    #print("Total SASA (Å^2): ", total_sasa * 10**2)
    
    return total_sasa

if __name__ == "__main__":
    from sys import argv

    outfile = argv[1]
    trajfile1 = argv[2]
    topfile = argv[3]

    if topfile:
        traj1 = md.load(trajfile1, top=topfile)
    else:
        traj1 = md.load(trajfile1)

    dists = calc_sasa(traj1)
    np.savetxt(outfile, dists, fmt="%.3f")

