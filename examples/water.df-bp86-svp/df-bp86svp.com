#P BP86/def2SVP/W06
DenFit 
opt(MaxCycle=100) scf(xqc,MaxConventionalCycle=500) 
int(ultrafinegrid)
gfinput gfoldprint iop(6/7=3)
symmetry(loose)
pop=full pop=nbo6

Local Min Search (Sing)

0 1
 O     0.000000     0.000000     0.000000
 H     0.000000     0.000000     0.950000
 H     0.895670     0.000000    -0.316663

