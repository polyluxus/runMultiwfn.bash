%chk=nitrogen.df-bp86svp.chk
#P BP86/def2SVP/W06 DenFit scf(xqc,MaxConventionalCycle=500) int(ultrafinegrid) 
gfinput gfoldprint iop(6/7=3) symmetry(loose) geom=allcheck guess(read,only) 
output=wfn

nitrogen.df-bp86svp.wfn

