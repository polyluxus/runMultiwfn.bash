#P BP86/def2TZVPP/W06
DenFit 
opt(MaxCycle=100) 
scf(xqc,MaxConventionalCycle=500) 
scrf(pcm,solvent=water)
EmpiricalDispersion=GD3BJ
int(ultrafinegrid)
gfinput gfoldprint iop(6/7=3)
symmetry(loose)

Water in water DF-BP86-D3(BJ)-PCM/def2-TZVPP

0 1
 O     0.000000     0.000000     0.000000
 H     0.000000     0.000000     0.950000
 H     0.895670     0.000000    -0.316663

