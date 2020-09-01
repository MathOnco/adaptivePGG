import math as math
import numpy as np
import scipy as scipy
from scipy import special
from numpy import linalg
import matplotlib as mpl
import matplotlib.pyplot as plt
from scipy.stats import hypergeom
from scipy.stats import binom

#This function will calculate how many generations we expect before extinction
def function(popsize, B):

    #Define Equilibrium # of defectors (D) given equilbirium frequency B
    D=popsize*B

    #Convert D to an integer (rounding down)
    Dminus=int(D)

    #Pre-allocate the transition matrices
    TransitionMatrix1=np.zeros([popsize+1,popsize+1])
    TransitionMatrix2=np.zeros([popsize+1,popsize+1])

    #Gaining Defectors
    #Start with the case where defectors are more fit bc they 
    # are less frequent (0 to Dminus inclusive).
    #Let m equal the number of defectors in current and
    #n equal the number of defectors in next gen.
    for m in range(Dminus+1):

        #Define the binomial dist. which tells us how many cooperators select defectors
        if (m > 0):

            rv = binom(popsize-m, m/(popsize-1))

        #If we have all cooperators (m=0), then zero probability of switching to defectors
        else:
            rv=binom(1,0)

        #For each starting state m, calculate probabilities for the next state n
        for n in range(m,popsize+1):

            #The binomial dist. tell us the probability of gaining n-m defectors
            TransitionMatrix1[m,n]= rv.pmf(n-m)


    #Losing Defectors
    #Now defectors are more frequent then eq. and will be lost
    for m in range ((Dminus+1),popsize+1):

        #Define the binomial distribution which will tell us the probability
        #of 'x' defectors switching to cooperators
        if (m < popsize):
            rv = binom(m,(popsize-m)/(popsize-1))
        #If we have popsize defectors, we should stay in that state
        else:
            rv = binom(1,0)

        #Run through possible next generation # defectors 'n'
        for n in range(m+1):

            #Gaining 
            TransitionMatrix2[m,n] = rv.pmf(m-n)

    #Pre-allocate the final transition Matrix, TM as the element-wise sum of the two
    TM=np.zeros([popsize+1,popsize+1])
    #iterate through rows 
    for i in range(popsize+1):    
        # iterate through columns 
        for j in range(popsize+1): 
            #Add the elements
            TM[i][j] = TransitionMatrix2[i][j] + TransitionMatrix1[i][j]


    #Now we only want the surviving matrix and not the whole thing, cut out 0th and popsize rows (absorbing)
    Surviving=np.zeros([popsize-1,popsize-1])
    for i in range(popsize-1):
        for j in range(popsize-1):
            Surviving[i][j] = TM[(i+1)][(j+1)]

    #outputTM = np.zeros([popsize+1,popsize+1])
    #for i in range(popsize-1):
    #    for j in range(popsize-1):
    #        outputTM[i][j]=Surviving[i][j]
    
    #for i in range(popsize-1,popsize+1):
    #    for j in range(popsize-1,popsize+1):
    #        outputTM[i][j]=TM[(i-popsize+1)*popsize][(j-popsize+1)*popsize]
    
    #Optionally print the full transition matrix
    #s = [[str(e) for e in row] for row in TM]
    #lens = [max(map(len, col)) for col in zip(*s)]
    #fmt = '\t'.join('{{:{}}}'.format(x) for x in lens)
    #table = [fmt.format(*row) for row in s]
    #print ('\n'.join(table))

    identity=np.identity(popsize-1)

    expval=np.sum(np.linalg.inv(identity-Surviving),axis=1)

    N=np.linalg.inv(identity-Surviving)
    #print(N)
    #print(expval)

    #Pre-allocate R
    R=np.zeros([popsize-1,2])

    #Make R, showing probabilities of becoming absorbed from each position
    for i in range(popsize-1):
        for j in range(2):
            R[i][j]=TM[i+1][j*popsize]
    #print(R)
    #print(TM[1][popsize])
    #print(np.matmul(N,R))
    #print(expval)

    #Return the mean of expected gens from all non-absorbing starting points
    return(np.mean(expval))


#Test
print(function(100, 0.175028))

#Optionally, Make Plot
#x_axis=np.linspace(10,1000,50)
#y_axis=np.zeros(50)
#for i in range(50):
#    y_axis[i]=function(int(np.round(x_axis[i])))

#plt.plot(x_axis, y_axis)
#plt.title("Expected Number of Gen.'s to Extinction")
#plt.xlabel("Population Size")
#plt.ylabel("Generations")
#plt.show()