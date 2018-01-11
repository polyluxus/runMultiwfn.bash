7   // Population (This sample file performs a couple of population analyses)
1   //   Hirshfeld
1   //     use built-in sphericals
n   //     save to file
2   //   Voronoi
1   //     use built-in sphericals
n   //     save to file (does overwrite)
5   //   Mulliken
1   //     population analysis
y   //     decompose to MO contribution
y   //     save to file (does overwrite)
0   //   Return to Main Menu
17  //   Basin analysis (The following part perform QTAIM charges)
1   //     generate grid data
1   //     electron density
2   //     medium grid
7   //     AIM Charge
2   //     most accurate
1   //     electron density
-10 //     return to Main Menu

