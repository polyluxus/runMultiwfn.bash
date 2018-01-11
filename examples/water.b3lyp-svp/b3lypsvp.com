#P B3LYP/def2SVP
opt(MaxCycle=100) scf(xqc,MaxConventionalCycle=500) 
int(ultrafinegrid)
gfinput gfoldprint iop(6/7=3)
symmetry(loose)

Water B3LYP/def2-SVP

0 1
 O     0.000000     0.000000     0.000000
 H     0.000000     0.000000     0.950000
 H     0.895670     0.000000    -0.316663

