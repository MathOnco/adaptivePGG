# adaptivePGG
C++ code developed to study the emergence of dimorphic populations in nonlinear public good games (PGG).

Within the "mainGame" folder, files and instructions for running the PGG are available. 

The "initBranch" folder provides files to allow the game to proceed in a slightly different manner. Instead of seeding a monomorphic population, we seed two subpopulations (cooperators and defectors), and prohibit mutation. Then, it becomes possible to make predictions on the expected number of generations until extinction of a subpopulation.

Corresponding pre-print:
https://www.biorxiv.org/content/10.1101/2020.08.30.274399v1

# Figure 1
overlaidPlot.m allows the user to re-create figure 1B after simulating results from the main game and recording those results in various txt files.

# Figure 2
Individual simulations can be run with information provided in mainGame folder. 

# Figure 3
A and B require several simulations of identical mainGame inputs to generate probabilities of extinction and branching. D-F show equilibrium frequency plots of single simulations of mainGame. 3C shows both transition matrix and simulated results of initBranch game, with two subpopulations seeded and mutations prohibited.

# Figure 4
vectorFieldPlot.m is a script which generates the vector field shown in each panel of figure 4. The user must enter the cooperator traits (production, ns) in order to generate the vector field for the defector subpopulation, which only exists for traits which are favored to maintain heterogeneity. plot_adaptiveDynamicsContour.m is a function that can be run with the mainGame to generate the contour plot of expected defector frequency given the location in trait space of the defector and cooperator subpopulation. The output of these two files was overlaid to create figure 4.
