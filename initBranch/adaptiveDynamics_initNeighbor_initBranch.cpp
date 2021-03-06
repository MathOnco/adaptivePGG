/*
    adaptiveDynamics_initNeighbor_initBranch.cpp
    Author: Gregory Kimmel
    Date: 06/12/2019

    This file calculates the evolution of neighborhood size and production traits over generations,
    starting from a population with two separate branches.

    USAGE
        ./run_adaptiveDynamics <inputfile> <popsize> <genMax> <recordInt>
        <pTraitFile> <nsFile>

    INPUTS
        Read from terminal:
            inputfile:  File that contains fitness related parameters.
            popsize:    Size of the population.
            genMax:     The number of generations to run.
            recordInt:  How often the generations are recorded. 
            pTraitFile: File of doubles (length: popsize*genMax) which contains
                            the evolution of production trait over generations.
            nsFile:     File of doubles (length: popsize*genMax) which contains
                            the evolution of neighborhood size over generations.
        Read from input file:
            nMin:           Minimum neighborhood size.
            nMax:           Maximum neighborhood size.
            sigma:          Freq. indep. benefit parameter
            beta:           Freq. dep. benefit parameter
            alpha:          Growth rate
            kappa:          Cost at full production P = 1
            omega:             Shape parameter of cost function
            NSsigma:        Std. dev. of neighborhood size if mutation occurs
            Psigma:         Std. dev. of production trait if mutation occurs
            mutThreshold:   Threshold for mutation to occur
            N01:            The initial neighborhood size of the first branch
            N02:            The initial neighborhood size of the second branch
            stdevN0:        Std. dev. of N0
            P01:            The initial production trait of the first branch
            P01:            The initial production trait of the second branch
            stdevP0:        Std. dev. of P0
            verbosity:      Parameter which controls the output to terminal

    OUTPUTS
        Written to terminal if verbosity > 0:
            Initial population traits
        Written to terminal:
            The elapsed time
        Written to outfiles:
            productionTrait:    Array of doubles for production trait evolution
            neighborhoodSizes:  Array of doubles for neighborhood size evolution
                NOTE: both arrays are of size ((genMax/recordInt) x popsize)

 */


#include <cstdio>
#include <cstdlib>
#include <cstdbool>
#include <string>
#include <cmath>
#include <ctime>
#include <random>
#include <algorithm>
#include <vector>

#define ROW_COL_TO_INDEX(row, col, num_cols) (row*num_cols + col)

using namespace std;

// Details of the functions are found after main()
void initializePopulationTraits(int popsize, double nMin, double nMax,
double N01, double N02, double stdevN0, double P01, double P02, double stdevP0, 
double *neighborhoodSizes, double *productionTrait, int verbosity);

double payoff(double sigma, double beta, double alpha, double kappa, double omega,
double n, double p, double meanProductionTrait, int verbosity);

void runAdaptiveDynamics(int popsize, double nMin, double nMax, double sigma,
double beta, double alpha, double kappa, double omega, double NSsigma,
double Psigma, double *neighborhoodSizes, double *productionTrait, int genMax,
double mutThreshold, double *nsRecord, double *productionRecord, int recordInt, int verbosity);

int main(int argc, char* argv[])
{

    // Start the clock
    clock_t start = clock();

    // Check if correct usage is given
    if(argc != 7)
    {
        printf("./run_adaptiveDynamics <inputfile> <popsize> <genMax> <recordInt> <outfile1> <outfile2>\n");
        return -1;
    }

    // Open the input file.
    FILE* inputfile = fopen(argv[1], "r");

    // Check that the file can be opened
    if(!inputfile)
    {
        printf("Unable to open input file.\n");
        return -1;
    }

    // Initialize parameters
    double nMin, nMax, sigma, beta, alpha, kappa, omega, NSsigma, Psigma,
    mutThreshold, N01, N02, stdevN0, P01, P02, stdevP0;
    int verbosity;

    // Read from the input file
    if (fscanf(inputfile, "%lf", &nMin) != 1)
    {
        nMin = 1.0;
        printf("failed to read nMin. Using default value.\n");
    }
    if (fscanf(inputfile, "%lf", &nMax) != 1)
    {
        nMax = 80.0;
        printf("failed to read nMax. Using default value.\n");
    }
    if (fscanf(inputfile, "%lf", &sigma) != 1)
    {
        sigma = 2.0;
        printf("failed to read sigma. Using default value.\n");
    }
    if (fscanf(inputfile, "%lf", &beta) != 1)
    {
        beta = 5.0;
        printf("failed to read beta. Using default value.\n");
    }
    if (fscanf(inputfile, "%lf", &alpha) != 1)
    {
        alpha = 1.0;
        printf("failed to read alpha. Using default value.\n");
    }
    if (fscanf(inputfile, "%lf", &kappa) != 1)
    {
        kappa = 0.5;
        printf("failed to read kappa. Using default value.\n");
    }
    if (fscanf(inputfile, "%lf", &omega) != 1)
    {
        omega = 2.0;
        printf("failed to read omega. Using default value.\n");
    }
    if (fscanf(inputfile, "%lf", &NSsigma) != 1)
    {
        NSsigma = 0.2;
        printf("failed to read NSsigma. Using default value.\n");
    }
    if (fscanf(inputfile, "%lf", &Psigma) != 1)
    {
        Psigma = 0.005;
        printf("failed to read Psigma. Using default value.\n");
    }
    if (fscanf(inputfile, "%lf", &mutThreshold) != 1)
    {
        mutThreshold = 0.01;
        printf("failed to read mutThreshold. Using default value.\n");
    }
    if (fscanf(inputfile, "%lf", &N01) != 1)
    {
        N01 = 60.0;
        printf("failed to read N01. Using default value.\n");
    }
    if (fscanf(inputfile, "%lf", &N02) != 1)
    {
        N02 = 60.0;
        printf("failed to read N02. Using default value.\n");
    }
    if (fscanf(inputfile, "%lf", &stdevN0) != 1)
    {
        stdevN0 = 0.05;
        printf("failed to read stdevN0. Using default value.\n");
    }
    if (fscanf(inputfile, "%lf", &P01) != 1)
    {
        P01 = 0.5;
        printf("failed to read P01. Using default value.\n");
    }
    if (fscanf(inputfile, "%lf", &P02) != 1)
    {
        P02 = 0.5;
        printf("failed to read P02. Using default value.\n");
    }
    if (fscanf(inputfile, "%lf", &stdevP0) != 1)
    {
        stdevP0 = 0.05;
        printf("failed to read stdevP0. Using default value.\n");
    }
    if (fscanf(inputfile, "%d", &verbosity) != 1)
    {
        verbosity = 0;
        printf("failed to read verbosity. Using default value.\n");
    }

    // Close the input file.
    fclose(inputfile);

    // Population size
    int popsize = atoi(argv[2]);

    // Number of generations
    int genMax = atoi(argv[3]);

    //Recording Frequency Interval
    int recordInt = atoi(argv[4]);

    // Initialize the arrays to be filled
    double *neighborhoodSizes = new double [genMax*popsize];
    double *productionTrait = new double [genMax*popsize];

    //Initialize the output arrays
    double *nsRecord = new double [(genMax/recordInt)*popsize];
    double *productionRecord = new double [(genMax/recordInt)*popsize];

    // Initialize the population traits
    initializePopulationTraits(popsize, nMin, nMax, N01, N02, stdevN0, 
    P01, P02, stdevP0, neighborhoodSizes, productionTrait,verbosity);

    // run Adaptive dynamics
    runAdaptiveDynamics(popsize, nMin, nMax, sigma, beta, alpha, kappa,
    omega, NSsigma, Psigma, neighborhoodSizes, productionTrait, genMax, mutThreshold, 
    nsRecord, productionRecord, recordInt, verbosity);

    // Open the outputfiles.
    FILE* outfile1 = fopen(argv[5], "w");
    FILE* outfile2 = fopen(argv[6], "w");

    // Write traits to test file
    fwrite(productionRecord,sizeof(double),(popsize*(genMax/recordInt)),outfile1);
    fwrite(nsRecord,sizeof(double),(popsize*(genMax/recordInt)),outfile2);
    
    // Close the output file
    fclose(outfile1);
    fclose(outfile2);
    
    // Print the time and return.
    printf("Time elapsed: %g seconds\n", (float)(clock()-start)/CLOCKS_PER_SEC);

    // Free the memory
    delete[] neighborhoodSizes;
    delete[] productionTrait;
    delete[] nsRecord;
    delete[] productionRecord;

    return 0;
}

/*

    initializePopulationTraits

    This function initializes the individual traits of production and
    neighborhood size.

    INPUTS
        popsize - The size of the population
        nMin - the minimum neighborhood size (probably 1.0)
        nMax - the maximum neighborhood size
        N01 - the first branch initial neighborhood size
        N02 - the second branch initial neighborhood size
        stdevN0 - the initial spread in neighborhood size
        P01 - the first branch initial production
        P02 - the second branch initial production
        stdevP0 - the initial sread in production
        neighborhoodSizes - Array that contains an individuals neighborhood size
        productionTrait - Array that contains an individuals production trait
        verbosity - Determines the amount of output to the terminal

    OUTPUTS
        neighborhoodSizes and productionTrait initialized.
*/
void initializePopulationTraits(int popsize, double nMin, double nMax,
double N01, double N02, double stdevN0, double P01, double P02, double stdevP0, 
double *neighborhoodSizes, double *productionTrait, int verbosity)
{

    // Generate the random seed
    random_device rd;
    mt19937 rng(rd());

    // Generate the first branch distributions
    normal_distribution<double> NS_distribution(N01,N01*stdevN0);
    normal_distribution<double> prod_distribution(P01,P01*stdevP0);

    // Print information to terminal
    if (verbosity > 0)
        printf("Initial population traits:\n");

    // Initialize the population traits with a normal distribution using
    // values given by the user. 

    //First branch (half the population)
    for (int i = 0; i < 1*popsize/2; i++)
    {
        do
        
            neighborhoodSizes[i] = NS_distribution(rng);
         while (neighborhoodSizes[i]<nMin || neighborhoodSizes[i]>popsize);

        do
        {
            productionTrait[i] = prod_distribution(rng);
        } while (productionTrait[i]<0 || productionTrait[i]>1);
        
        if(verbosity > 0)
            printf("%g\t%g\n",neighborhoodSizes[i],productionTrait[i]);
    }

    // Generate the second branch distributions
    normal_distribution<double> NS2_distribution(N02,N02*stdevN0);
    normal_distribution<double> prod2_distribution(P02,P02*stdevP0);

    // Second branch (second half of the population)
    for (int i = (1*popsize/2); i < popsize; i++)
    {
        do
        
            neighborhoodSizes[i] = NS2_distribution(rng);
         while (neighborhoodSizes[i]<nMin || neighborhoodSizes[i]>popsize);

        do
        {
            productionTrait[i] = prod2_distribution(rng);
        } while (productionTrait[i]<0 || productionTrait[i]>1);
        
        if(verbosity > 0)
            printf("%g\t%g\n",neighborhoodSizes[i],productionTrait[i]);
    }
}

/*

    payoff

    This function calculates the payoff an individual has at a particular
    production value and neighborhood size

    INPUTS
        sigma - The freq-independent impact of the public good
        beta - The freq-dependent impact of the public good
        alpha - The growth rate
        kappa - The cost at maximum production
        omega - Shape parameter of the cost function
        n - Individual's neighborhood size
        p - Individual's production trait
        meanProductionTrait - Mean production of the public good in pop.
        verbosity - Determines the amount of output to the terminal

    OUTPUTS
        payoff = benefit - cost
*/
double payoff(double sigma, double beta, double alpha, double kappa, double omega, int n, double p, double meanProductionTrait, int verbosity)
{

    // The expected amount of public good perceived by the individual
    double expectedPublicGood = (p + (n-1)*meanProductionTrait)/n;

    // Benefit function
    double benefit = alpha*(1 + exp(sigma))/
    (1+exp(sigma-beta*expectedPublicGood));

    // Cost function
    double cost = kappa*pow(tanh(p/(1.0-p)),omega);

    // Payoff function
    return benefit - cost;

}

/*

    runAdaptiveDynamics

    This function runs adaptive dynamics of popsize individuals through genMax
    generations.

    INPUTS
        popsize -   The size of the population
        nMin -      The minimum neighborhood size (probably 1.0)
        nMax -      The maximum neighborhood size
        sigma -     The freq-independent impact of the public good
        beta -      The freq-dependent impact of the public good
        alpha -     The growth rate
        kappa -     The cost at maximum production
        omega -        Shape parameter of the cost function
        NSsigma -   The std dev of the neighborhood size when mutated
        Psigma -    The std dev of the production trait when mutated
        neighborhoodSizes - Array that contains an individuals neighborhood size
        productionTrait - Array that contains an individuals production trait
        genMax -    The number of generations to run the simulation
        mutThreshold -  The probability of mutation
        verbosity - Determines the amount of output to the terminal

    OUTPUTS
        neighborhoodSizes and productionTrait are filled.


*/
void runAdaptiveDynamics(int popsize, double nMin, double nMax, double sigma,
double beta, double alpha, double kappa, double omega, double NSsigma,
double Psigma, double *neighborhoodSizes, double *productionTrait, int genMax,
double mutThreshold, double *nsRecord, double *productionRecord, int recordInt, int verbosity)
{
    // Random seed
    random_device rd;
    mt19937 rng(rd());

    // Initialize the distribution to select a random individual
    // and the distribution to decide which event occurs
    uniform_int_distribution<int> uniInt(0,popsize-1);
    uniform_real_distribution<double> randReal(0.0,1.0);
    normal_distribution<double> perturbNS(0.0,NSsigma);
    normal_distribution<double> perturbProduction(0.0,Psigma);

    // Initialize random individual to play game against and meanProduction of
    // public good.
    int randIndividual, individual, opponent, offspring, i, k, individualNS;
    int nb, counter, neighbor, neighborStart, neighborInd;
    double meanProductionIndividual, meanProductionOpponent, payoffDiff, w, roll, changeNS, changeProduction;
    double maxPayoff, minPayoff, individualRounded;
    double benefit, cost, expectedPublicGood, mean, sum;
    
    //Make a 0 to popsize -1 int vector increasing by 1
    vector<int> indices;
    for (k=0; k<popsize; k++)
    {
        indices.push_back(k);
    }
    
    
    clock_t start = clock();

    //Assign Neighbors Randomly One Time
    int *NeighborIndex = new int [(popsize*(popsize-1))];
    
        for (nb = 0; nb < popsize; nb++)
        {  
            //printf("Next individual\n");
            //Shuffle
            shuffle(begin(indices), end(indices),rng);
            //for (k=0; k<popsize; k++)
            //{
            //    printf("%d\n",indices[k]);
            //}
            counter=0;
            
            //printf("%d\n",nb);
            for (k=0; k<(popsize); k++)
            {
                int check = indices[k];
               
                if (check==nb)
                    continue;
                else
                {
                    counter++;
                    NeighborIndex[ROW_COL_TO_INDEX(nb,(counter-1),(popsize-1))]=check;
                }
                
            }
            
        }   
     
    // Loop through generations
    for (int nGen = 0; nGen < genMax-1; nGen++)
    {
        //Print updates to terminal
        if (nGen==genMax/50||nGen==genMax/10||nGen==genMax/4||nGen==genMax/2||nGen==genMax*3/4)
        {
            printf("Update: we are at generation ");
            printf("%d", nGen);
            printf(" ");
            printf("Time elapsed from start: %g seconds\n", (float)(clock()-start)/CLOCKS_PER_SEC);
        }
        
        // Define the payoff of each individual in the generation (just using the mean excluding individual for sanity)
        double *fitness = new double [popsize];

        // Starting index for this gen.
        int startingIndex = ROW_COL_TO_INDEX(nGen,0,popsize); 

        // Loop through population, defining fitness of each ind.
        for (k = 0; k<popsize; k++)
        {
            sum=0.0;
            individualRounded = neighborhoodSizes[ROW_COL_TO_INDEX(nGen, k, popsize)]+.5;
            individualNS = (int)(individualRounded);
            //printf("Next individual\n");
            //i counts through the index of neighbors we previously assigned
            neighborStart = uniInt(rng);

            for (i = 0; i < individualNS-1; i++)
            { 
                neighborInd = (neighborStart+i)%(popsize-1);
                
                neighbor = NeighborIndex[ROW_COL_TO_INDEX(k,(neighborInd),(popsize-1))];
                //printf("Neighbor Index = %d\n", neighbor);
                sum += productionTrait[(neighbor+startingIndex)];
            }
            
            if (individualNS>1)
            {
                //printf("sum is %f\t ns-1 is %d\n", sum, (individualNS-1));
                mean=sum/(individualNS-1);
                //printf("mean is: %f\n", mean);
            }
            else
            {
                mean=0;
            }

            //Payoff Function
            fitness[k]= payoff(sigma, beta, alpha, kappa, omega, individualNS, productionTrait[ROW_COL_TO_INDEX(nGen, k, popsize)],
            mean, verbosity);

            double numCoop = productionTrait[ROW_COL_TO_INDEX(nGen, k, popsize)];
            
        }
        
        // The maximum and minimum fitness in that generation
        maxPayoff = *max_element(fitness + 0, fitness + popsize);
        minPayoff = *min_element(fitness + 0, fitness + popsize);
        
        // Loop through population
        for (i = 0; i < popsize; i++)
        {
            
            // Randomly select an individual to compete with
            do
            {
                randIndividual = uniInt(rng);
            } while (randIndividual == i);

            // Get the index of the individual and their opponent
            individual = ROW_COL_TO_INDEX(nGen,i,popsize);
            opponent = ROW_COL_TO_INDEX(nGen,randIndividual,popsize);
            
            //Look at payoff difference
            // payoff(opponent) - payoff(individual)
            payoffDiff = fitness[randIndividual]-fitness[i]; 

            // Normalizing the payoff difference. If the max payoff difference
            // is 0, we assume a 50-50 change to replace either individual.
            w = (maxPayoff-minPayoff>__DBL_EPSILON__)?
            payoffDiff/(maxPayoff-minPayoff):0.5;

            // We now roll to see whether the opponent will replace the 
            // individual in the game.
            roll = randReal(rng);

            // Index for the offspring
            // (NOTE: the () around first argument!)
            offspring = ROW_COL_TO_INDEX((nGen+1),i,popsize);

            // The parent is the individual
            if (w < roll)
            { 
                productionTrait[offspring] = productionTrait[individual];
                neighborhoodSizes[offspring] = neighborhoodSizes[individual];
            }
            else
            {
                productionTrait[offspring] = productionTrait[opponent];
                neighborhoodSizes[offspring] = neighborhoodSizes[opponent];
            }

            // Now we check for mutations: first up is neighborhood size
            roll = randReal(rng);

            // Mutation in neighborhood size
            if (roll < mutThreshold)
            {
                do
                {
                    changeNS = perturbNS(rng);
                } while (changeNS + neighborhoodSizes[offspring] < nMin ||
                changeNS + neighborhoodSizes[offspring] > popsize);

                neighborhoodSizes[offspring] += changeNS;

                if (neighborhoodSizes[offspring]>popsize)
                {
                    printf("Error: NS= ");
                    printf("%f\n", neighborhoodSizes[offspring]);
                }
            }
            
            // Check mutation for production trait
            roll = randReal(rng);

            // Mutation in production
            if (roll < mutThreshold)
            {
                do
                {
                    changeProduction = perturbProduction(rng);
                } while (changeProduction + productionTrait[offspring] < 0 ||
                changeProduction + productionTrait[offspring] > 1);

                productionTrait[offspring] += changeProduction;

            }
        }

        if (nGen % recordInt == 0)
        {
            int entryNumber = (nGen/recordInt);
            for(int k=0; k<popsize; k++)
            {
                productionRecord[ROW_COL_TO_INDEX(entryNumber, k, popsize)] = productionTrait[ROW_COL_TO_INDEX(nGen, k, popsize)];
                nsRecord[ROW_COL_TO_INDEX(entryNumber, k, popsize)] = neighborhoodSizes[ROW_COL_TO_INDEX(nGen, k, popsize)];
            }
        }
    }
}
