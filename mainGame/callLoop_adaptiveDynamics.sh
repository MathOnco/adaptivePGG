#!/bin/bash

#   call_adaptiveDynamics.sh
#   Author:   Gregory Kimmel
#   Date:     06/13/19
#
# This bash script calls adaptiveDynamics.cpp to run with the user specified
# parameters. After this, we save all the parameters to a text file for viewing
# and call MATLAB to create plots showing the time series evolution as well as
# phase diagram (production,neighborhood size).
# 
# USAGE ./callCscript.sh temp seq initalState nTrials kf sigma verbosity saveParams
#
# OUTPUTS
#   To terminal:
#       The output of Gillespie (e.g. mean first passage time)
#   To output files:
#       Saves the distribution of times to the two output files
#


# Check to make sure correct number of arguments are given

if [ "$#" -ne 7 ]; then
  echo "Usage: ./call_adaptiveDynamics.sh <inputfile> <popsize> <genMax>\
 <recordInt> <loops> <saveFig> <saveParams>"
  exit 1
fi

inputfile=$1            # The name of the input file
popsize=$2              # population size
genMax=$3               # The maximum number of generations
recordInt=$4            # The number of generations between recording to production/ns files
loops=$5                # The number of trials to repeat
saveFig=$6              # Set to 1 to save fig or 0 to not
saveParams=$7           # Set to 1 to save the parameters and 0 to not

# Create output text files from popsize and genMax
num=1
productionFile=pop_${popsize}_nGens_${genMax}_production_v${num}.txt
neighborhoodSizeFile=pop_${popsize}_nGens_${genMax}_neighborhoodSize_v${num}.txt
matlabFigure1=provsns_pop_${popsize}_nGens_${genMax}_v${num}.pdf
matlabFigure2=production_pop_${popsize}_nGens_${genMax}_v${num}.pdf
matlabFigure3=ns_pop_${popsize}_nGens_${genMax}_v${num}.pdf
matlabFigure4=pstar_pop_${popsize}_nGens_${genMax}_v${num}.pdf
branchFile=pop_${popsize}_nGens_${genMax}_loops_${loops}_branchFile.txt

# Check to make sure the variables are correct:
# This checks that popsize is a number
if [[ -n ${popsize//[0-9,.,e]/} ]]; then
    echo "popsize should be a float."
    exit 2
fi
# This checks that genMax is a number
if [[ -n ${genMax//[0-9,.,e]/} ]]; then
    echo "genMax should be a float."
    exit 2
fi
# This checks that recordInt is an integer
if [[ -n ${recordInt//[0-9]/} ]]; then
    echo "recordInt should be an integer."
    exit 2
fi
# This checks that saveFig is 0 or 1
if [[ -n ${saveFig//[0,1]/} ]]; then
    echo "saveFig can only be 0 or 1."
    exit 2
fi
# This checks that saveParams is 0 or 1
if [[ -n ${saveParams//[0,1]/} ]]; then
    echo "saveParams can only be 0 or 1."
    exit 2
fi

loopNum=1
while [ $loopNum -le $loops ]
do
    # If output files don't exist, we create them. If they do, rename and create next version
    COUNTER=2
    if [[ ! -f "${productionFile}" ]]; then
        ./run_adaptiveDynamics ${inputfile} ${popsize} ${genMax} ${recordInt}\
        ${productionFile} ${neighborhoodSizeFile}
        parameterFile=paramsFor_${productionFile}
        if ((${saveParams} > 0)); then
            cp ${inputfile} ${parameterFile}
        fi
    else
        while [[ -f "${productionFile}" ]]; do
            productionFile=pop_${popsize}_nGens_${genMax}_production_v${COUNTER}.txt
            neighborhoodSizeFile=pop_${popsize}_nGens_${genMax}_neighborhoodSize_v${COUNTER}.txt
            matlabFigure1=provsns_pop_${popsize}_nGens_${genMax}_v${COUNTER}.pdf
            matlabFigure2=production_pop_${popsize}_nGens_${genMax}_v${COUNTER}.pdf
            matlabFigure3=ns_pop_${popsize}_nGens_${genMax}_v${COUNTER}.pdf
            matlabFigure4=pstar_pop_${popsize}_nGens_${genMax}_v${COUNTER}.pdf
            let COUNTER=COUNTER+1
        done
        parameterFile=paramsFor_${productionFile}
        if ((${saveParams} > 0)); then
        cp ${inputfile} ${parameterFile}
        fi
        ./run_adaptiveDynamics ${inputfile} ${popsize} ${genMax} ${recordInt}\
        ${productionFile} ${neighborhoodSizeFile}


        while false; do
            read -p "Files already exist. Do you wish to run the C++? " yn
            case $yn in
                [Yy]* ) while [[ -f "${productionFile}" ]]; do
                            productionFile=pop_${popsize}_nGens_${genMax}_production_v${COUNTER}.txt
                            neighborhoodSizeFile=pop_${popsize}_nGens_${genMax}_neighborhoodSize_v${COUNTER}.txt
                            matlabFigure1=provsns_pop_${popsize}_nGens_${genMax}_v${COUNTER}.pdf
                            matlabFigure2=production_pop_${popsize}_nGens_${genMax}_v${COUNTER}.pdf
                            matlabFigure3=ns_pop_${popsize}_nGens_${genMax}_v${COUNTER}.pdf
                            matlabFigure4=pstar_pop_${popsize}_nGens_${genMax}_v${COUNTER}.pdf
                            let COUNTER=COUNTER+1
                        done
                        parameterFile=paramsFor_${productionFile}
                        if ((${saveParams} > 0)); then
                            cp ${inputfile} ${parameterFile}
                        fi
                        ./run_adaptiveDynamics ${inputfile} ${popsize} ${genMax} ${recordInt}\
                        ${productionFile} ${neighborhoodSizeFile}
                        break;;
                [Nn]* ) echo "Plots (if you want them) will be created from most recent text files."
                        while [[ -f "${productionFile}" ]]; do
                            productionFile=pop_${popsize}_nGens_${genMax}_production_v${COUNTER}.txt
                            neighborhoodSizeFile=pop_${popsize}_nGens_${genMax}_neighborhoodSize_v${COUNTER}.txt
                            matlabFigure1=provsns_pop_${popsize}_nGens_${genMax}_v${COUNTER}.pdf
                            matlabFigure2=production_pop_${popsize}_nGens_${genMax}_v${COUNTER}.pdf
                            matlabFigure3=ns_pop_${popsize}_nGens_${genMax}_v${COUNTER}.pdf
                            matlabFigure4=pstar_pop_${popsize}_nGens_${genMax}_v${COUNTER}.pdf
                            let COUNTER=COUNTER+1
                        done
                        let COUNTER=COUNTER-2
                        productionFile=pop_${popsize}_nGens_${genMax}_production_v${COUNTER}.txt
                        neighborhoodSizeFile=pop_${popsize}_nGens_${genMax}_neighborhoodSize_v${COUNTER}.txt
                        matlabFigure1=provsns_pop_${popsize}_nGens_${genMax}_v${COUNTER}.pdf
                        matlabFigure2=production_pop_${popsize}_nGens_${genMax}_v${COUNTER}.pdf
                        matlabFigure3=ns_pop_${popsize}_nGens_${genMax}_v${COUNTER}.pdf
                        matlabFigure4=pstar_pop_${popsize}_nGens_${genMax}_v${COUNTER}.pdf
                        break;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    
    fi

    #Plot/record automatically
    /Applications/MATLAB_R2019b.app/bin/matlab -nodesktop -nosplash \
    -r "plot_adaptiveDynamics('${productionFile}',\
    '${neighborhoodSizeFile}',${genMax},${popsize},${recordInt},'${matlabFigure1}', \
    '${matlabFigure2}','${matlabFigure3}','${matlabFigure4}',\
    '${branchFile}');pause(5);exit;"

    ((loopNum++))
done

#Or choose to plot or not
while false; do
    read -p "Do you want to Plot?" yn
    case $yn in
        [Yy]* ) /Applications/MATLAB_R2019b.app/bin/matlab -nodesktop -nosplash \
                -r "plot_adaptiveDynamics('${productionFile}',\
                '${neighborhoodSizeFile}',${genMax},${popsize},${recordInt},'${matlabFigure1}', \
                '${matlabFigure2}','${matlabFigure3}','${matlabFigure4}','${branchFile}');pause(5);exit;"
                break;;
        [Nn]* ) echo "No Plots for you."
                break;;
        * ) echo "Please answer yes or no";;
    esac
done