function plot_adaptiveDynamicsContour(productionFile,neighborhoodSizeFile,...
    genMax,popsize, recordInt, matlabFigure1, matlabFigure2,...
    matlabFigure3, matlabFigure4, branchFile)
tic

%This function captures all the matlab commands we would want for adaptive
%dynamics purposes, allowing us to trigger ON and OFF options (next lines)

%The following sets which we want to activate (1=On, 0=Off)
    %plotProNs ON will plot (Pro vs Ns, Ns vs gen, and Pro vs gen)
    plotProNs=1;
    plotContour=1;
    
    %recordBranchingStart ON will record (to txt file) where branching occurs,
    %write it to an outfile ("branchFile") and mark on production plot where
    %it thinks branching occurred.
    recordBranchingStart = 1;
        %proBranchTolStart sets the threshold for where branching hass
        %successfully occurred.
        proBranchTolStart=0.1;
        
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
genAdj = round(genMax/recordInt);

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
    pstarDefect = NaN(genAdj-1,1);
    eqFreqDefect = NaN(genAdj-1,1);
    defectPro = zeros(genAdj-1,1);
    defectNs = zeros(genAdj-1,1);
    coopPro = zeros(genAdj-1,1);
    coopNs = zeros(genAdj-1,1);
    %pstar4Avg = NaN(genAdj-1,1);

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
               
        end
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
            [~,centersNS] = kmeans(neighborhoodSize(i,:)',2);
            plotPt1Coop=[max(centers) min(centersNS)]
            plotPt1Defect=[min(centers) max(centersNS)]
            i
            
            
            %Record adjusted gen at branch pt
            j=i;
            
            %set yes to 1 to indicate that branching has occurred
            yes = 1
            break
        end
    end

    if yes>0
        
        %If branching occurs, write it into branchFile
        fileID = fopen(branchFile,'a+');
        fprintf(fileID, '%f\t', branchingPoint);
        fclose(fileID);
        
        %Find pstar average and standard deviation for stabilized generations,
        %if there are any
        avgPstarExist=0;
        %Make sure starting index is less than genAdj-1
        startIndex=branchingPoint(1)/recordInt+30000/recordInt;
        if startIndex>(genAdj-1)
            startIndex=genAdj-5000;
        end
        
        if sum(pstarDefect(startIndex:genAdj-1)>0)>0
        
            %There was an equilibrium pstar for a time, so we should record the
            %average
            avgPstarExist=1;
        
            %Find average and sd, to be written to txt file
            avgPstar = nanmean(pstarDefect(startIndex:genAdj-1));
            sdPstar = nanstd(pstarDefect(startIndex:genAdj-1));
        end
            
        if avgPstarExist>0
            %write the avg pstar Info into the branchFile without overwriting
            fileID = fopen(branchFile,'a+');
            fprintf(fileID, '%f\t%f\t', avgPstar, sdPstar);
            fclose(fileID);
        end
        
        if recordExtinction>0
            
            %Evaluate if branching is lost at any point after which it
            %occurs
            plotPt2Coop=0;
            plotPt3Coop=0;
            plotPt4Coop=0;
            for l=j:genAdj-1
                
                %Run k-means again
                [~, centers2] = kmeans(productionTraits(l,:)',2);
                [~,centers2NS]=kmeans(neighborhoodSize(l,:)',2);
                
                if(max(centers2)>.5 & plotPt2Coop==0)
                    plotPt2Coop=[max(centers2) min(centers2NS)]
                    plotPt2Defect=[min(centers2) max(centers2NS)] 
                    l
                end
                
                if(max(centers2)>.75 & plotPt3Coop==0)
                    plotPt3Coop=[max(centers2) min(centers2NS)]
                    plotPt3Defect=[min(centers2) max(centers2NS)] 
                    l
                end
                
                if(max(centers2)>.95 & plotPt4Coop==0)
                    plotPt4Coop=[max(centers2) min(centers2NS)]
                    plotPt4Defect=[min(centers2) max(centers2NS)]
                    l
                end
                
                if l==genAdj-1
                    plotPt5Coop=[max(centers2) min(centers2NS)]
                    plotPt5Defect=[min(centers2) max(centers2NS)]
                    l
                end
                
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
    omega=2;
    
    %Production vs. Neighborhood size plot
    figure(1);
    hold on
    
    if plotContour>0
        x = linspace(0.0001,.9999,50);
        y = linspace(1.6,80,50);
        for i=1:50
            for j=1:50
                if (y(j)>plotPt1Coop(2))
                    Z(j,i)=pstarFunction2V(x(i),y(j),plotPt1Coop(1),plotPt1Coop(2));
                else 
                    Z(j,i)= nan;
                end
            end
        end
        colormap hsv
        contourf(x,y,Z,linspace(0.01,1,40))
        colorbar
    end
    
    %set nmax to 80 to restrict window of ns plot
    n_max=80;
    
    %Give n some initial value to avoid syms error
    n=40;

    %loop to find zeroes of selection gradient over (x,ns) space
    for i=1:200
        Zeroes(1,i)=Root(alpha,beta,sigma,kappa,omega,x_axis(1,i));
    end
    
    [~,x_minimum]=min(Zeroes);
    
    %Initialize colormap to color depending on time/gen
    %mycmap=zeros(popsize,3);
    
    %This plots more quickly if we take or files which have popsize rows
    %and genAdj columns, so loop through popsize and assign color (custom
    %RGB)
    %for k=1:popsize
    %plot(production_needs_reshaping,neighborhood_needs_reshaping,...
    %    'o','MarkerSize',1,'Color','k');

        %mycmap(k,:)=[.8-.8*k/popsize k/popsize .7];
    %end
    
    %Assign dark green to the "final" row of the colormap so it appears on
    %the legend. Make sure it is thick enough (1-2% of colorbar)
    %thickness = round((popsize+50)/100.0);
    %for i=1:thickness
    %    mycmap(popsize-thickness+i,:)=[0 .5 0];
    %end
    
    %Create the legend for the colorbar
    %colormap(mycmap);
    %c = colorbar('Ticks',[0,.5,1],...
    %     'TickLabels',{'0',sprintf('%.2e',genMax/2),sprintf('%.2e',genMax)});
    %c.Label.String = 'Generation';
    
    %Plot the dashed and solid lines indicating eq. pts. and stability
    plot(x_axis(1:100),Zeroes(1:100),'Color','black','LineWidth',4)
    plot(x_axis(100:x_minimum),Zeroes(100:x_minimum),'Color','black','LineWidth',4)
    plot(x_axis(x_minimum:200),Zeroes(x_minimum:200),'Color','black','LineStyle','--',...
        'LineWidth',4)
    
    %plot current gen of cooperators in green
    plot(plotPt1Coop(1),plotPt1Coop(2),'.','MarkerSize',40,'Color',[0 .5 0])
    %plot current gen of defectors in black
    plot(plotPt1Defect(1),plotPt1Defect(2),'.','MarkerSize',40,'Color','k')
    
    %limit the y axis
    ylim([0 n_max])
    
    %labels
    set(gca,'fontsize',16);
    hold off
    
    
    %Production vs. Neighborhood size plot
    figure(2);
    hold on
    
    if plotContour>0
        x = linspace(0.0001,.9999,50);
        y = linspace(1.6,80,50);
        for i=1:50
            for j=1:50
                Z(j,i)=pstarFunction2V(x(i),y(j),plotPt2Coop(1),plotPt2Coop(2));
            end
        end
        colormap hsv
        caxis manual
        caxis([0 1]);
        contourf(x,y,Z,linspace(0.01,1,40))
        colorbar
    end
    
    %set nmax to 80 to restrict window of ns plot
    n_max=80;
    
    %Give n some initial value to avoid syms error
    n=40;

    %loop to find zeroes of selection gradient over (x,ns) space
    for i=1:200
        Zeroes(1,i)=Root(alpha,beta,sigma,kappa,omega,x_axis(1,i));
    end
    
    [~,x_minimum]=min(Zeroes);
    
    
    %plot current gen of cooperators in green
    plot(plotPt2Coop(1),plotPt2Coop(2),'.','MarkerSize',40,'Color',[0 .5 0])
    %plot current gen of defectors in black
    plot(plotPt2Defect(1),plotPt2Defect(2),'.','MarkerSize',40,'Color','k')
    
    %Plot the dashed and solid lines indicating eq. pts. and stability
    plot(x_axis(1:100),Zeroes(1:100),'Color','black','LineWidth',4)
    plot(x_axis(100:x_minimum),Zeroes(100:x_minimum),'Color','black','LineWidth',4)
    plot(x_axis(x_minimum:200),Zeroes(x_minimum:200),'Color','black','LineStyle','--',...
        'LineWidth',4)
    
    %limit the y axis
    ylim([0 n_max])
    
    %labels
    set(gca,'fontsize',16);
    hold off
    
    %Production vs. Neighborhood size plot
    figure(3);
    hold on
    
    if plotContour>0
        x = linspace(0.0001,.9999,50);
        y = linspace(1.6,80,50);
        for i=1:50
            for j=1:50
                Z(j,i)=pstarFunction2V(x(i),y(j),plotPt3Coop(1),plotPt3Coop(2));
            end
        end
        colormap hsv
        caxis manual
        caxis([0 1]);
        contourf(x,y,Z,linspace(0.01,1,40))
        colorbar
    end
    
    %set nmax to 80 to restrict window of ns plot
    n_max=80;
    
    %Give n some initial value to avoid syms error
    n=40;

    %loop to find zeroes of selection gradient over (x,ns) space
    for i=1:200
        Zeroes(1,i)=Root(alpha,beta,sigma,kappa,omega,x_axis(1,i));
    end
    
    [~,x_minimum]=min(Zeroes);
    
    
    %plot current gen of cooperators in green
    plot(plotPt3Coop(1),plotPt3Coop(2),'.','MarkerSize',40,'Color',[0 .5 0])
    %plot current gen of defectors in black
    plot(plotPt3Defect(1),plotPt3Defect(2),'.','MarkerSize',40,'Color','k')
    
    %Plot the dashed and solid lines indicating eq. pts. and stability
    plot(x_axis(1:100),Zeroes(1:100),'Color','black','LineWidth',4)
    plot(x_axis(100:x_minimum),Zeroes(100:x_minimum),'Color','black','LineWidth',4)
    plot(x_axis(x_minimum:200),Zeroes(x_minimum:200),'Color','black','LineStyle','--',...
        'LineWidth',4)
    
    %limit the y axis
    ylim([0 n_max])
    
    %labels
    set(gca,'fontsize',16);
    hold off
    
    %Production vs. Neighborhood size plot
    figure(4);
    hold on
    
    if plotContour>0
        x = linspace(0.0001,.9999,50);
        y = linspace(1.6,80,50);
        for i=1:50
            for j=1:50
                Z(j,i)=pstarFunction2V(x(i),y(j),plotPt4Coop(1),plotPt4Coop(2));
            end
        end
        colormap hsv
        caxis manual
        caxis([0 1]);
        contourf(x,y,Z,linspace(0.01,1,40))
        colorbar
    end
    
    %set nmax to 80 to restrict window of ns plot
    n_max=80;
    
    %Give n some initial value to avoid syms error
    n=40;

    %loop to find zeroes of selection gradient over (x,ns) space
    for i=1:200
        Zeroes(1,i)=Root(alpha,beta,sigma,kappa,omega,x_axis(1,i));
    end
    
    [~,x_minimum]=min(Zeroes);
    
    
    %plot current gen of cooperators in green
    plot(plotPt4Coop(1),plotPt4Coop(2),'.','MarkerSize',40,'Color',[0 .5 0])
    %plot current gen of defectors in black
    plot(plotPt4Defect(1),plotPt4Defect(2),'.','MarkerSize',40,'Color','k')
    
    %Plot the dashed and solid lines indicating eq. pts. and stability
    plot(x_axis(1:100),Zeroes(1:100),'Color','black','LineWidth',4)
    plot(x_axis(100:x_minimum),Zeroes(100:x_minimum),'Color','black','LineWidth',4)
    plot(x_axis(x_minimum:200),Zeroes(x_minimum:200),'Color','black','LineStyle','--',...
        'LineWidth',4)
    
    %limit the y axis
    ylim([0 n_max])
    
    %labels
    set(gca,'fontsize',16);
    hold off
    
    %Production vs. Neighborhood size plot
    figure(5);
    hold on
    
    if plotContour>0
        x = linspace(0.0001,.9999,50);
        y = linspace(1.6,80,50);
        for i=1:50
            for j=1:50
                Z(j,i)=pstarFunction2V(x(i),y(j),plotPt5Coop(1),plotPt5Coop(2));
            end
        end
        colormap hsv
        caxis manual
        caxis([0 1]);
        contourf(x,y,Z,linspace(0.01,1,40))
        colorbar
    end
    
    %set nmax to 80 to restrict window of ns plot
    n_max=80;
    
    %Give n some initial value to avoid syms error
    n=40;

    %loop to find zeroes of selection gradient over (x,ns) space
    for i=1:200
        Zeroes(1,i)=Root(alpha,beta,sigma,kappa,omega,x_axis(1,i));
    end
    
    [~,x_minimum]=min(Zeroes);
    
    
    %plot current gen of cooperators in green
    plot(plotPt5Coop(1),plotPt5Coop(2),'.','MarkerSize',40,'Color',[0 .5 0])
    %plot current gen of defectors in black
    plot(plotPt5Defect(1),plotPt5Defect(2),'.','MarkerSize',40,'Color','k')
    
    %Plot the dashed and solid lines indicating eq. pts. and stability
    plot(x_axis(1:100),Zeroes(1:100),'Color','black','LineWidth',4)
    plot(x_axis(100:x_minimum),Zeroes(100:x_minimum),'Color','black','LineWidth',4)
    plot(x_axis(x_minimum:200),Zeroes(x_minimum:200),'Color','black','LineStyle','--',...
        'LineWidth',4)
    
    %limit the y axis
    ylim([0 n_max])
    
    set(gca,'fontsize',16);
    hold off

    %Production Plot
    figure(6);
    hold on
    
    %Plot production Traits
    x_axis=linspace(1,genAdj,genAdj);
    x_axis=repelem(x_axis,popsize);
    
    %flatten production Traits 
    plotProFlat=reshape(productionTraits.',1,[]);
    
    scatter(x_axis,plotProFlat,...
        20,'filled','MarkerFaceAlpha',1/50,'MarkerFaceColor','k',...
        'MarkerEdgeColor','none')
    
    %plot(productionTraits, '.', 'Color', 'k')
    
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
    
end


%If we plot, save figures according to files given in fn. input
if plotProNs>0
    fig=figure(1);
    fig.PaperPositionMode = 'auto';
    fig_pos = fig.PaperPosition;
    fig.PaperSize = [fig_pos(3)+.01 fig_pos(4)-.01];
    print(fig,'contourplot1','-dpdf','-bestfit');
    
    fig=figure(2);
    fig.PaperPositionMode = 'auto';
    fig_pos = fig.PaperPosition;
    fig.PaperSize = [fig_pos(3)+.01 fig_pos(4)-.01];
    print(fig,'contourplot2','-dpdf','-bestfit');
    
    fig=figure(3);
    fig.PaperPositionMode = 'auto';
    fig_pos = fig.PaperPosition;
    fig.PaperSize = [fig_pos(3)+.01 fig_pos(4)-.01];
    print(fig,'contourplot3','-dpdf','-bestfit');
    
    fig=figure(4);
    fig.PaperPositionMode = 'auto';
    fig_pos = fig.PaperPosition;
    fig.PaperSize = [fig_pos(3)+.01 fig_pos(4)-.01];
    print(fig,'contourplot4','-dpdf','-bestfit');
    
    fig=figure(5);
    fig.PaperPositionMode = 'auto';
    fig_pos = fig.PaperPosition;
    fig.PaperSize = [fig_pos(3)+.01 fig_pos(4)-.01];
    print(fig,'contourplot5','-dpdf','-bestfit');
    
    fig = figure(6);
    fig.PaperPositionMode = 'auto';
    fig_pos = fig.PaperPosition;
    fig.PaperSize = [fig_pos(3) fig_pos(4)];
    print(fig,matlabFigure2,'-dpdf','-bestfit');

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
        beta = 5; sigma = 2; kappa = .5; omega = 2;
        
        fitness = (1+exp(sigma))./(1+exp(sigma-beta.*(y+x.*(n-1))./n)) - ...
            kappa.*tanh(y/(1-y)).^omega;
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
function quiverArray=VecField(xCoop,nCoop,numXvecs,numYvecs,popsize)
    
    Ywindow = linspace(1.6,80,numYvecs);
    Xwindow = linspace(0,.99,numXvecs);
    for i=1:numXvecs
        for j=1:numYvecs
            
            xDefect = Xwindow(i);
            nDefect = Ywindow(j);
            
            dxRaw = invasionFitness(xDefect+.005, nDefect, xCoop, xDefect, ...
                nDefect, popsize) - invasionFitness(xDefect,nDefect,xCoop,...
                xDefect, nDefect, popsize);
            dnRaw = invasionFitness(xDefect, nDefect+.2, xCoop, xDefect, ...
                nDefect, popsize) - invasionFitness(xDefect,nDefect,xCoop,...
                xDefect, nDefect, popsize);
            
            norm = (dxRaw.^2 + dnRaw.^2).^(.5);
            dx(i,j) = dxRaw/norm;
            dn(i,j) = dnRaw/norm;
            fullArray(i,j) = [Xwindow(i) Ywindow(j) dx(i,j) dn(i,j)];
        end
    end
    
    quiverArray = fullArray;
   
    function invFit=invasionFitness(v, nv, xCoop, nCoop, xDefect,nDefect,...
        popsize)
        nV = round (nv);
        
        payoff=0;
        
        for i=0:(n-1)
            payoff = payoff + hygepdf(i,popsize-1,round(popsize-pstar*popsize)-1,...
                nV-1)*payoff(v,(xDefect*(nV-1-i)+xCoop*i)/(nV-1),nV);
        end
        
        avgPayoff = payoffDefect(xDefect,xCoop,nDefect,pstarFn(xCoop,...
                xDefect, nCoop, nDefect, popsize));
        
        invFit = payoff-avgPayoff;
    end
            
            
    function fitnessDefect = payoffDefect(xDefect,xCoop, nDefect,pstar,popsize)
        n = round(nDefect);
        payment=0;
            
        for i=0:(n-1)
            payment = payment+hygepdf(i,popsize-1,round(popsize-pstar*popsize)-1,...
                n-1)*payoff(xDefect,(xDefect*(n-1-i)+xCoop*i)/(n-1),n);
        end
            
        fitnessDefect = payment;
            
    end

end
function Zero=Root(alpha,beta,sigma,kappa,omega,x)
    syms n  
    Zero=double(vpasolve(alpha*beta*exp(sigma-beta*x)*(1+exp(sigma))/...
        ((1+exp(sigma-beta*x))^2*n)...
        -kappa*omega*(1/(1-x)+x/(1-x)^2)*sech(x/(1-x))^2*tanh(x/(1-x))^(omega-1)==0,n));
end
