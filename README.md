# adaptivePGG
C++ code developed to study the emergence of dimorphic populations in nonlinear public good games

The command line input for running the game follows this sequence:

bash file, params file, popsize, maxGen, recording Interval (how often the traits are copied to the outfile so how many generations are skipped), # of times to run C++ code (for quantifying branching/extinction behavior), save Figure (1 or 0), save parameters (1 or 0)

An example of a typical command line input, running a population of 150 individuals for 1 million generations recording the traits every 500 generations would be:

bash callLoop_adaptiveDynamics.sh blah.txt 150 1000000 500 1 1 1

Within the bash file "callLoop_adaptiveDynamics.sh", the user can specify the matlab file in order to generate certain outputs.

For example, the matlab file, "plot_adaptiveDynamicsContour", generates the contour plots shown in figure 4.
