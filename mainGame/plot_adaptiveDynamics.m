function plot_adaptiveDynamics(productionFile,neighborhoodSizeFile,...
    genMax,popsize, recordInt, matlabFigure1, matlabFigure2,...
    matlabFigure3, matlabFigure4, branchFile)
tic

%This function captures all the matlab commands we would want for adaptive
%dynamics purposes, allowing us to trigger ON and OFF options (next lines)

%The following sets which we want to activate (1=On, 0=Off)
    %plotProNs ON will plot (Pro vs Ns, Ns vs gen, and Pro vs gen)
    plotProNs=1;
    
    %recordBranchingStart ON will record where branching occurs,
    %write it to an outfile ("branchFile") and mark on production plot where
    %it thinks branching occurred.
    recordBranchingStart = 1;
        %proBranchTolStart sets the threshold for where branching has
        %successfully occurred.
        proBranchTolStart=0.2;
        
    %recordExtinction ON will record the generation that we lose branching
    %(to txt file), and mark on the plot where we lost branching
    recordExtinction = 1;
        %proBranchTol divided by 2 will be used as the tolerance to decide this
    
    %calculatePlotPstar ON will plot pstar (theoretical and actual)
    %whenever branching is triggered
    calculatePlotPstar = 1; 
        % Set the tolerance to trigger branching for the pstar. 
        proBranchTolPstar = 0.05;

% Close all plots
close all;

%adjust the max of the arrays according to "recordInt", which is how often
%the output is recorded (tells us how many gens we skip in C++ code)
genAdj = genMax/recordInt;

% Open the files, read data and close
fileID = fopen(productionFile);
production_needs_reshaping = fread(fileID,[genAdj popsize],'double');
fclose(fileID);
fileID = fopen(neighborhoodSizeFile);
neighborhood_needs_reshaping = fread(fileID,[genAdj popsize],'double');
fclose(fileID);

%Reshape the matrix so that it is in the right format
production_matrix=reshape(production_needs_reshaping,[popsize genAdj]);
neighborhood_matrix=reshape(neighborhood_needs_reshaping,[popsize genAdj]);
productionTraits=production_matrix';
neighborhoodSize=neighborhood_matrix';

%calculate PlotPstar, defined above, tells us if we want to calculate the
%actual and theoretical pstar values and plot them.
if calculatePlotPstar>0
    
    %Pre-allocate 
    pstarCoop = zeros(genAdj-1,1);
    pstarDefect = linspace(-1,-1, genAdj-1);
    eqFreqDefect = linspace(-1,-1, genAdj-1);
    defectPro = zeros(genAdj-1,1);
    defectNs = zeros(genAdj-1,1);
    coopPro = zeros(genAdj-1,1);
    coopNs = zeros(genAdj-1,1);
    pstar4Avg = NaN(genAdj-1,1);

    %Find where branching first occurs
    for i=1:(genAdj-1)
        
        %kmeans
        [~, centersN] = kmeans(neighborhoodSize(i,:)',2);
        [~, centersX] = kmeans(productionTraits(i,:)',2);
    
        %record mean positions of the two branches
        defectPro(i) = min(centersX);
        defectNs(i) = max(centersN);
        coopPro(i) = max(centersX);
        coopNs(i) = min(centersN);
    
        %condition at which we say branching occurs (set at beginning of file)
        if coopPro(i)-defectPro(i) >proBranchTolPstar
        
            %Now that branching has occurred, find actual pstar
            pstarCoop(i) = sum(neighborhoodSize(i,:) < (defectNs(i)+coopNs(i))/2)/popsize;
            pstarDefect(i) = sum(neighborhoodSize(i,:) > (defectNs(i)+coopNs(i))/2)/popsize;
        
            %Find the theoretical pstar
            %Find only sometimes, define how often with genSkip
            genSkip = 100.0;
            if(ceil(i/genSkip) == floor(i/genSkip))
                
                eqFreqDefect(i) = pstarFn(coopPro(i), defectPro(i), coopNs(i),...
                    defectNs(i),popsize);
               
            end
            
            %Find if Pstar has stabilized. To do this, need a sample of
            %Pstars around the current index, and need to make sure they
            %are above zero.
            if (i-100)<1
                minIndex = 1;
                maxIndex = i;
                midIndex = mean([minIndex maxIndex]);
            else
                minIndex = i-100;
                maxIndex = i;
                midIndex = mean([minIndex maxIndex]);
            end
            
            %Now find pstar mean variation from those two samples
            PstarVarTol = 0.001;
            if (abs(nanmean(pstarDefect(midIndex:maxIndex))-nanmean(pstarDefect(minIndex:midIndex))) < PstarVarTol &&...
                    pstarDefect(i)>0)
                
                %Record the pstar at "stabilized" points
                pstar4Avg(i) = pstarDefect(i);
            end      
        end
    end
    
    %Find pstar average and standard deviation for stabilized generations,
    %if there are any
    %avgPstarExist will indicate if we want to record the average and sd
    %pstar or if it didn't have enough generations to really count
    avgPstarExist=0;
    if length(find(1-isnan(pstar4Avg)))>0
        
        %There was an equilibrium pstar for a time, so we should record the
        %average
        avgPstarExist=1;
        
        %Find average and sd, to be written to txt file
        avgPstar = nanmean(pstar4Avg);
        sdPstar = nanstd(pstar4Avg);
    end
end

%set extinct to zero (it will stay zero if extinction doesn't happen
extinct=0;

%Only run this section if recordBranchingStart is on. This will create and
%write to/add to an output file recording the generation and production at
%which branching occurs
if recordBranchingStart>0
    
    yes=0;
    
    for i=1:genAdj
        [~, centers] = kmeans(productionTraits(i,:)',2);
        
        %proBranchTol set at beginning of file. Default = 0.1
        if abs(centers(1)-centers(2)) > proBranchTolStart
            
            %save branching point for plotting
            branchingPoint = [(i-1)*recordInt, mean(centers)];
            
            %Record adjusted gen at branch pt
            j=i;
            
            %set yes to 1 to indicate that branching has occurred
            yes = 1;
            break
        end
    end

    if yes>0
        
        %If branching occurs, write it into branchFile
        fileID = fopen(branchFile,'a+');
        fprintf(fileID, '%f\t', branchingPoint);
        fclose(fileID);
            
        if avgPstarExist>0
            %write the avg pstar Info into the branchFile without overwriting
            fileID = fopen(branchFile,'a+');
            fprintf(fileID, '%f\t%f\t', avgPstar, sdPstar);
            fclose(fileID);
        end
        
        if recordExtinction>0
            
            %Evaluate if branching is lost at any point after which it
            %occurs
            for l=j:genAdj-1
                
                %Run k-means again
                [~, centers2] = kmeans(productionTraits(l,:)',2);
                
                if abs(centers2(1)-centers2(2)) < (proBranchTolStart/10)
                    
                    %record extinction gen and defector production at extinction
                    extinctionPoint = [(l-1)*recordInt, max(centers2)];
                    
                    %write the extinction point into the branchFile without overwriting
                    fileID = fopen(branchFile,'a+');
                    fprintf(fileID, '%f\t%f\n', extinctionPoint);
                    fclose(fileID);
                    
                    %record that extinction occured so we know to plot it
                    extinct = 1;
                    break
                    
                end
            end
            
            %If no extinction occurs, write no extinction in txt file
            if extinct==0
                
                %write No extinction into txt file
                fileID = fopen(branchFile,'a+');
                fprintf(fileID, 'NoExtinction\n');
                fclose(fileID);
                
            end
        end
    else
        %If branching doesn't occur, there are two possibilities
        %All cooperator -> "NoBranching"
        if (centers(1)>.9)
            %write "NoBranching" into the branchFile without overwriting
            fileID = fopen(branchFile,'a+');
            fprintf(fileID, 'NoBranching\n');
            fclose(fileID);
        %Or we didn't run long enough to find final fate
        else
            %write "Undetermined" into the branchFile without overwriting
            fileID = fopen(branchFile,'a+');
            fprintf(fileID, 'Undetermined\n');
            fclose(fileID);
        end
        
    end       
end


%Decide if we want to plot the three usual plots (Pro vs Ns, Ns vs gens,
%Pro vs gens)
if plotProNs>0
    %Solve for zeroes in selection gradient over the region we care about
    Zeroes=zeros(1,100);
    %Can't make x=1 or else we get a NaN output and an error
    x_axis=[linspace(.001,.38288,100) linspace(.383,.99,100)];
    
    %Default parameters
    alpha=1;
    sigma=2;
    beta=5;
    kappa=.5;
    mu=2;
    
    %set nmax to 100 to restrict window of ns plot
    n_max=100;
    
    %Give n some initial value to avoid syms error
    n=40;

    %loop to find zeroes of selection gradient over (x,ns) space
    for i=1:200
    Zeroes(1,i)=Root(alpha,beta,sigma,kappa,mu,x_axis(1,i));
    end
    
    [~,x_minimum]=min(Zeroes);

    %Production vs. Neighborhood size plot
    figure(1);
    hold on;
    
    %Initialize colormap to color depending on time/gen
    mycmap=zeros(popsize,3);
    
    %This plots more quickly if we take or files which have popsize rows
    %and genAdj columns, so loop through popsize and assign color (custom
    %RGB)
    for k=1:popsize
        plot(production_needs_reshaping(:,k),neighborhood_needs_reshaping(:,k),...
        'o','MarkerSize',1,'Color',[.8-.8*k/popsize k/popsize .7]);

        mycmap(k,:)=[.8-.8*k/popsize k/popsize .7];
    end
    
    %Assign dark green to the "final" row of the colormap so it appears on
    %the legend. Make sure it is thick enough (1-2% of colorbar)
    thickness = round((popsize+50)/100.0);
    for i=1:thickness
        mycmap(popsize-thickness+i,:)=[0 .5 0];
    end
    
    %Create the legend for the colorbar
    colormap(mycmap);
    c = colorbar('Ticks',[0,.5,1],...
         'TickLabels',{'0',sprintf('%.2e',genMax/2),sprintf('%.2e',genMax)});
    c.Label.String = 'Generation';
    
    %plot final gen in green
    plot(productionTraits((genAdj-1),:),neighborhoodSize((genAdj-1),:),'.','MarkerSize',30,'Color',[0 .5 0])
    
    %Plot the dashed and solid lines indicating eq. pts. and stability
    plot(x_axis(1:100),Zeroes(1:100),'Color','black','LineWidth',4)
    plot(x_axis(100:x_minimum),Zeroes(100:x_minimum),'Color','black','LineWidth',4)
    plot(x_axis(x_minimum:200),Zeroes(x_minimum:200),'Color','black','LineStyle','--',...
        'LineWidth',4)
    
    %limit the y axis
    ylim([0 200])
    hold off;
    
    %labels
    xlabel('Production trait'); ylabel('Neighborhood size');
    title('Adaptive Dynamics Simulation');
    set(gca,'fontsize',16);

    %Production Plot
    figure(2);
    hold on
    
    %Plot production Traits
    plot(productionTraits, '.', 'Color', 'k')
    
    %If turned on and branching occurs, plot a red X where branching occurs
    if (recordBranchingStart>0 && yes>0)
        plot(branchingPoint(1)/recordInt, branchingPoint(2), 'x', 'Color', ...
            'red','MarkerSize', 20)
    end
    
    %If turned on and extinction occurs, plot a blue X where extinction
    %occurs
    if (recordExtinction>0 && extinct>0)
        plot(extinctionPoint(1)/recordInt, extinctionPoint(2), 'x', 'Color', ...
            'blue', 'MarkerSize', 20)
    end
    
    xlabel(sprintf("Generations (%d's)", recordInt))
    ylabel('Production')
    hold off
    
    %Plot Neighborhood Size
    figure(3);
    plot(neighborhoodSize,'.','Color','k')
    %xlabel(sprintf("Generations (%d's)", recordInt))
    %ylabel('Neighborhood Size')
end

%Only make pstar plot if "calculatePlotPstar" set to >0
if calculatePlotPstar>0
    figure(4);
    hold on
    
    %Plot the actual frequency of defectors 'pstarDefect'
    plot(pstarDefect,'x','Color','k')
    #plot(pstar4Avg, 'x', 'Color', 'blue')
    
    %Plot the theoretical frequency
    plot(eqFreqDefect,'x', 'Color','red')
    title("Red is the theoretical p*, black is actual.")
    ylabel('Fraction of Defectors')
    xlabel(sprintf("Generations (%d's)", recordInt))
    axis([0 genAdj-1 0 1])
    hold off
end

%If we plot, save figures according to files given in fn. input
if plotProNs>0
    fig=figure(1);
    fig.PaperPositionMode = 'auto';
    fig_pos = fig.PaperPosition;
    fig.PaperSize = [fig_pos(3)+.01 fig_pos(4)-.01];
    print(fig,matlabFigure1,'-dpdf','-bestfit');
    
    fig = figure(2);
    fig.PaperPositionMode = 'auto';
    fig_pos = fig.PaperPosition;
    fig.PaperSize = [fig_pos(3) fig_pos(4)];
    print(fig,matlabFigure2,'-dpdf','-bestfit');
    
    fig = figure(3);
    fig.PaperPositionMode = 'auto';
    fig_pos = fig.PaperPosition;
    fig.PaperSize = [fig_pos(3) fig_pos(4)];
    print(fig,matlabFigure3,'-dpdf','-bestfit');
end
    
%Only plot and save pstar is "calculatePlotPstar" set to nonzero
if calculatePlotPstar>0
    fig = figure(4);
    fig.PaperPositionMode = 'auto';
    fig_pos = fig.PaperPosition;
    fig.PaperSize = [fig_pos(3) fig_pos(4)];
    print(fig,matlabFigure4,'-dpdf','-bestfit');
end

toc
    
end
function eqFreq = pstarFn(xCoop, xDefect, nCoop, nDefect, popsize)
    
    %Set tolerance for pstar calculation
    tol=10^(-4);
        
    %Set initial boundary
    leftPstar=0;
    rightPstar=1;
       
    %Find sign of each function at the boundary
    leftPayoff = payoffDiff(xCoop,xDefect,nCoop,nDefect, leftPstar, popsize);
    rightPayoff = payoffDiff(xCoop,xDefect,nCoop,nDefect, rightPstar, popsize);
       
    %If they're the same sign, we don't have a pstar between 0 and 1. Print
    %to terminal because we are only checking for areas where branches
    %exist
    if(leftPayoff==rightPayoff)
       eqFreq = NaN;
       return;
    end
        
    %Use while loop to calculate the pstar
    while (rightPstar-leftPstar) > tol 
        
        %Find pstar midpoint
        midPstar = mean([leftPstar rightPstar]);
            
        %Find sign of payoff at midpoint
        midPayoff = payoffDiff(xCoop,xDefect,nCoop,nDefect, midPstar, popsize);
            
        %If the sign is the same as left, midpoint becomes left endpt. and
        %vice versa for right
        if midPayoff==leftPayoff
            leftPstar = midPstar;
        else
            rightPstar = midPstar;
        end
    end
           
    %Once we settle on a pstar and break while loop, assign eqFreq.
    eqFreq = mean([rightPstar leftPstar]);
        
        
    %Nested Functions
    %First, define the actual payoff function
    function fitness = payoff(y,x,n)
        beta = 5; sigma = 2; kappa = .5; mu = 2;
        
        fitness = (1+exp(sigma))./(1+exp(sigma-beta.*(y+x.*(n-1))./n)) - ...
            kappa.*tanh(y/(1-y)).^mu;
    end
        
    %define payoff function for ind that is Defector
    function fitnessDefect = payoffDefect(xDefect,xCoop, nDefect,pstar,popsize)
        n = round(nDefect);
        payment=0;
            
        for i=0:(n-1)
            payment = payment+hygepdf(i,popsize-1,round(popsize-pstar*popsize)-1,...
                n-1)*payoff(xDefect,(xDefect*(n-1-i)+xCoop*i)/(n-1),n);
        end
            
        fitnessDefect = payment;
            
    end
        
    %define payoff function for ind. that is a cooperator
    function fitnessCoop = payoffCoop(xCoop, xDefect, nCoop, pstar, popsize)
        
        n = round(nCoop);
        payment=0;
            
            
        if n>1
            for i=0:(n-1)
                payment = payment + hygepdf(i,popsize-1,round((1-pstar)*popsize-1),...
                    n-1)*payoff(xCoop,(xDefect*(n-1-i)+xCoop*i)/(n-1),n); 
            end
            fitnessCoop=payment;
        else
            fitnessCoop = payoff(xCoop,0,1);
        end
            
    end
    
    %Find sign of the payoff difference between coop and defect
    function diff = payoffDiff(xCoop,xDefect,nCoop,nDefect, pstar, popsize)
        diff = sign(payoffCoop(xCoop, xDefect, nCoop, pstar, popsize)-...
            payoffDefect(xDefect,xCoop, nDefect,pstar,popsize));
    end

end
function Zero=Root(alpha,beta,sigma,kappa,mu,x)
    syms n  
    Zero=double(vpasolve(alpha*beta*exp(sigma-beta*x)*(1+exp(sigma))/...
        ((1+exp(sigma-beta*x))^2*n)...
        -kappa*mu*(1/(1-x)+x/(1-x)^2)*sech(x/(1-x))^2*tanh(x/(1-x))^(mu-1)==0,n));
end
