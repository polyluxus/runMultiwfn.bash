%chk=df-bp86tzvpp.chk
#P BP86/def2TZVPP/W06 DenFit scf(xqc,MaxConventionalCycle=500) 
scrf(pcm,solvent=water) EmpiricalDispersion=GD3BJ int(ultrafinegrid) gfinput 
gfoldprint iop(6/7=3) symmetry(loose) geom=allcheck guess(read,only) output=wfx

df-bp86tzvpp.wfx

