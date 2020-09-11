close all; clear all

NumHorz=20;
NumVert=20;

finaldx=zeros(NumVert, NumHorz);
finaldn=zeros(NumVert, NumHorz);
xCoop=.9978;
nCoop=1.2163;

for i=1:NumHorz
    for j=1:NumVert
        h=10^(-3);
        x=linspace(.02,.99,NumHorz);
        n=linspace(1.6,79,NumVert);
        
        dx= (invasionFitness(x(i)+h, n(j),xCoop, nCoop, x(i),n(j),150)-...
            invasionFitness(x(i), n(j),xCoop, nCoop, x(i),n(j),150))/h;
        
        dn = (invasionFitness(x(i), n(j)+1,xCoop, nCoop, x(i),n(j),150)-...
            invasionFitness(x(i), n(j),xCoop, nCoop, x(i),n(j),150))/1;
        
        if isnan(dx)
            dx=0;dn=0;
        end
        
        finaldx(i,j)=dx;
        finaldn(i,j)=dn*40;
    end
end

x=reshape(repelem(x,NumVert),NumHorz,NumVert)';
n=reshape(repelem(n,NumHorz),NumHorz,NumVert)./80;

headWidth = 8;
headLength = 8;
LineLength = 0.001;

%figure(1);
%hold on
%quiver(x,n,finaldx, finaldn)
%axis([0 1 0 1])
%set(gca,'color','none')
%hold off


%quiver plots
figure(1);
hq = quiver(x,n,finaldx, finaldn);           %get the handle of quiver
title('Regular Quiver plot','FontSize',16);

%get the data from regular quiver
U = hq.UData;
V = hq.VData;
X = hq.XData;
Y = hq.YData;

%right version (with annotation)
figure(2);
%hold on;
for ii = 1:length(X)
    for ij = 1:length(X)
        
        arrowMagnitude = ((U(ii,ij)/max(max(abs(U))))^2 + ...
            (V(ii,ij)/max(max(abs(V))))^2)/2;

        headWidth = 5;
        if U(ii,ij)==0
            ah = annotation('arrow',...
                'headStyle','cback1','HeadLength',0,'HeadWidth',0);
        else
            ah = annotation('arrow',...
                'headStyle','cback1','HeadLength',headLength,'HeadWidth',headWidth,...
                'Color',[.9-.9*(arrowMagnitude)^.2 .9-.9*(arrowMagnitude)^.2...
                .9-.9*(arrowMagnitude)^.2]);
        end
        set(ah,'parent',gca);
        set(ah,'position',[X(ii,ij) Y(ii,ij) LineLength*U(ii,ij) LineLength*V(ii,ij)]);

    end
end
axis([0 1 0 1])
set(gca,'YTickLabel',[],'YTick',[],'XTickLabel',[], 'fontsize', 16);
box on
%axis off;

fig=figure(2);
    fig.PaperPositionMode = 'auto';
    fig_pos = fig.PaperPosition;
    fig.PaperSize = [fig_pos(3)+.01 fig_pos(4)-.01];
    print(fig,'tranpsarentPlot','-dpdf','-bestfit');
    
   


function invFit = invasionFitness(v, nv, xCoop, nCoop, xDefect, nDefect, popsize)
    
    %first find p*
    pstar = pstarFn(xCoop, xDefect, nCoop, nDefect, popsize);
    
    if (pstar<1 && pstar>0)
        %Then find the invasion fitness of a mutant with traits v, nv
        n = round(nv);
        payment=0;
            
        for i=0:(n-1)
            payment = payment+hygepdf(i,popsize-1,round(popsize-pstar*popsize)-1,...
                n-1)*payoff(v,(xDefect*(n-1-i)+xCoop*i)/(n-1),n);
        end
            
        fitnessMutant = payment;
    
        %Then find the avg payoff of the rest of the population
        avgPayoff = payoffDefect(xDefect,xCoop, nDefect,pstar,popsize);
    
        %return the difference
        invFit = fitnessMutant-avgPayoff;
    else
        invFit = 0;
    end
    
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
%Define the actual payoff function
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
