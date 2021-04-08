# adaptivePGG
C++ code developed to study the emergence of dimorphic populations in nonlinear public good games (PGG).

Within the "mainGame" folder, files and instructions for running the PGG are available. 

The "initBranch" folder provides files to allow the game to proceed in a slightly different manner. Instead of seeding a monomorphic population, we seed two subpopulations (cooperators and defectors), and prohibit mutation. Then, it becomes possible to make predictions on the expected number of generations until extinction of a subpopulation.

Corresponding pre-print:
https://www.biorxiv.org/content/10.1101/2020.08.30.274399v1

# Figure 1
overlaidPlot.m allows the user to re-create figure 1B after simulating results from the main game and recording those results in various txt files. The input would be six .txt files containing the production data. In the exampleData folder, we have uploaded the six production files used in our figure 1. 

# Figure 2
vectorFieldPlot.m is a script which generates the vector field shown in each panel of figure 2. The user must enter the cooperator traits (production, ns) in order to generate the vector field for the defector subpopulation, which only exists for traits which are favored to maintain heterogeneity. plot_adaptiveDynamicsContour.m is a function that can be run with the mainGame to generate the contour plot of expected defector frequency given the location in trait space of the defector and cooperator subpopulation. The vector field and contour plot were overlayed to create figure 2.

# Figure 3
Individual simulations can be run and plotted with information provided in mainGame folder.

# Figure 4
A and B require several simulations of identical mainGame inputs to generate probabilities of extinction and branching. A bash script to loop the simulations can be found in the mainGame folder. D-F show equilibrium frequency plots of single simulations of mainGame, which can be turned on in the plotAdaptiveDynamics.m file within the mainGame folder. 4C shows both transition matrix and simulated results of initBranch game, with two subpopulations seeded and mutations prohibited. Information for 4C can be found within the initBranch folder. 
