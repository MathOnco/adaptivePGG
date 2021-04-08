function overlaidPlot(proFile1, proFile2, proFile3, proFile4, proFile5, proFile6)

%Set the params you use
popsize=1000;
recordInt=100;
genMax=60000;

% Close all plots
close all;

%adjust the max of the arrays according to "recordInt", which is how often
%the output is recorded (tells us how many gens we skip in C++ code)
genAdj = round(genMax/recordInt);

% Open the files, read data and close
fileID = fopen(proFile1);
production_needs_reshaping1 = fread(fileID,[genAdj popsize],'double');
fclose(fileID);

fileID = fopen(proFile2);
production_needs_reshaping2 = fread(fileID,[genAdj popsize],'double');
fclose(fileID);

fileID = fopen(proFile3);
production_needs_reshaping3 = fread(fileID,[genAdj popsize],'double');
fclose(fileID);

fileID = fopen(proFile4);
production_needs_reshaping4 = fread(fileID,[genAdj popsize],'double');
fclose(fileID);

fileID = fopen(proFile5);
production_needs_reshaping5 = fread(fileID,[genAdj popsize],'double');
fclose(fileID);

fileID = fopen(proFile6);
production_needs_reshaping6 = fread(fileID,[genAdj popsize],'double');
fclose(fileID);

%Reshape the matrix so that it is in the right format
production_matrix1=reshape(production_needs_reshaping1,[popsize genAdj]);
productionTraits1=production_matrix1';

production_matrix2=reshape(production_needs_reshaping2,[popsize genAdj]);
productionTraits2=production_matrix2';

production_matrix3=reshape(production_needs_reshaping3,[popsize genAdj]);
productionTraits3=production_matrix3';

production_matrix4=reshape(production_needs_reshaping4,[popsize genAdj]);
productionTraits4=production_matrix4';

production_matrix5=reshape(production_needs_reshaping5,[popsize genAdj]);
productionTraits5=production_matrix5';

production_matrix6=reshape(production_needs_reshaping6,[popsize genAdj]);
productionTraits6=production_matrix6';

%Production Plot
    figure(1);
    hold on
    
    %Make data into x y axis format
    x_axis=linspace(1,genMax,genAdj);
    x_axis=repelem(x_axis,popsize);
    
    %flatten production Traits 
    plotProFlat1=reshape(productionTraits1.',1,[]);
    plotProFlat2=reshape(productionTraits2.',1,[]);
    plotProFlat3=reshape(productionTraits3.',1,[]);
    plotProFlat4=reshape(productionTraits4.',1,[]);
    plotProFlat5=reshape(productionTraits5.',1,[]);
    plotProFlat6=reshape(productionTraits6.',1,[]);
    
    transparency=1/50;
    size=3;
    
    scatter(x_axis,plotProFlat1,...
        size,'filled','MarkerFaceAlpha',transparency,'MarkerFaceColor','#a6cee3',...
        'MarkerEdgeColor','none')
    scatter(x_axis,plotProFlat3,...
        size,'filled','MarkerFaceAlpha',transparency,'MarkerFaceColor','#e31a1c',...
        'MarkerEdgeColor','none')
    scatter(x_axis,plotProFlat6,...
        size,'filled','MarkerFaceAlpha',transparency,'MarkerFaceColor','#b2df8a',...
        'MarkerEdgeColor','none')
    scatter(x_axis,plotProFlat2,...
        size,'filled','MarkerFaceAlpha',transparency,'MarkerFaceColor','#1f78b4',...
        'MarkerEdgeColor','none')
    scatter(x_axis,plotProFlat4,...
        size,'filled','MarkerFaceAlpha',transparency,'MarkerFaceColor','#33a02c',...
        'MarkerEdgeColor','none')
    scatter(x_axis,plotProFlat5,...
        size,'filled','MarkerFaceAlpha',transparency,'MarkerFaceColor','#fb9a99',...
        'MarkerEdgeColor','none')

    
    xlabel("Generations",'FontSize',12,'FontWeight','bold')
    ylabel('Production','FontSize',12,'FontWeight','bold')
    box on
    hold off
    
    fig=figure(1);
    fig.PaperPositionMode = 'auto';
    fig_pos = fig.PaperPosition;
    fig.PaperSize = [fig_pos(3)+.01 fig_pos(4)-.01];
    print(fig,'overlayPlot','-dpdf','-bestfit');
end
