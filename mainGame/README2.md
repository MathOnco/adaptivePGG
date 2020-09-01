Using these four files, we can run and analyze the game, generating plots, recording branching and extinction events, and comparing equilibrium frequency of defectors to their observed frequency.

First, compile the C++ file "adaptiveDynamics.cpp"

Then, the command line input is as follows: 
```
bash callLoop_adaptiveDynamics.sh defaultParams.txt #popsize #maxGen #recordInt #loops #saveParams?
```
Where #popsize is the desired population size, #maxGen is the desired number of generations, #recordInt is how often the C++ code records the traits to the outfile (analyzed in matlab), #loops is the desired number of simulations to run with identical inputs, #saveParams is set to 1 to save the parameter file and 0 to not save. 

An example command line input, running one simulation of a population of 500 individuals for 100,000 generations and recording every 100 generations, would be:
```
bash callLoop_adaptiveDynamics.sh defaultParams.txt 500 100000 100 1 1
```
