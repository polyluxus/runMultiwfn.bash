2   // Topology (This demo file runs a QTAIM analysis.)
2   //   Search from nuclei
3   //   Serach between nuclei
4   //   Search between triads of nuclei
5   //   Search between quads of nuclei
8   //   Generate paths 
9   //   Generate paths
-5  //   Export all paths
4   //     create paths.txt (to read in for additional runs)
6   //     create paths.pdb (to visualise)
0   //     return to previous menu (topology)
-4  //   Export all critical points
4   //     create CPs.text
6   //     create CPs.pdb
0   //     return to previous menu
7   //   Print information on critical points
0   //     All found CPs
-10 //   Return to Main Menu
100 // Other functions
2   //   Export coordinates/ wavefunction
1   //     Export geometry as pdb file
geom.pdb
0   //   Return to Main Menu
4   // Output properties in a plane (Only with graphical support.)
3   //   Laplacian
2   //   Contour
500,500
0   //   Extend plane [Bohr]
6.0 
4   //   Choose Atoms
1,2,3
-8  //   Switch to angstrom
6   //   Interbasin paths
0   //   save graph
-5  //   Return to Main Menu

