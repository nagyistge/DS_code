% this script is for child_FT and child_BT seed which have more than one ROIs

clear
clc
close all

ROImaskGroup='child_BT'
numSub=23;
dataDir=['/home2/data/Projects/workingMemory/groupAnalysis/CWAS/46sub/followup/'];
figDir='/home2/data/Projects/workingMemory/figs/CWAS/46sub/CWAS_followup/scatterplot/';
if strcmp(ROImaskGroup, 'child_BT')
    numSeed=2
    groupList={'child_BT', 'adoles_BT'};
elseif strcmp(ROImaskGroup, 'child_FT')
    numSeed=4
    groupList={'child_FT', 'adoles_FT'};
end

for j=1:length(groupList)
    group=char(groupList{j})
    npFile=load(['/home2/data/Projects/workingMemory/data/CWAS23', group, 'NP.mat'])
    npData=npFile.([group, 'NP']);
        DS=npData(:, 3); % the FTNP and BTNP are saved in separate model
    fullBrainFC=load([dataDir, 'correlDSAndFullBrainFC/standFullBrainFC_', ROImaskGroup, 'Mask_', group, '_subgroup.txt']);
        
    for i=1:numSeed
        seed=num2str(i)      
              covariates=npData(:, 4:6);  
        [R p]=corrcoef(fullBrainFC(:, i), DS);
        [RHO,PVAL] = partialcorr(fullBrainFC(:, i), DS, covariates);
                
        figure(1)
        scatter(fullBrainFC(:,i), DS)
        lsline
        axis([-0.2 1.2 4 20])
         %saveas(figure(1), [figDir, ROImaskGroup, 'Mask_', group, 'Subgroup_ROI', seed, '.png'])
        
        figure(2)
        [R1 p1]=corrcoef(fullBrainFC(1:end-1, i), DS(1:end-1));
        covariates1=npData(1:end-1, 4:6);
        [RHO1,PVAL1] = partialcorr(fullBrainFC(1:end-1, i), DS(1:end-1), covariates1)
        scatter(fullBrainFC(1:end-1, i), DS(1:end-1))
        lsline
        axis([0 0.6 4 20])
         %saveas(figure(2), [figDir, ROImaskGroup, 'Mask_', group, 'Subgroup_ROI', seed, 'wo.png'])
        
         R1List(i,j)=R1(1,2);
        RHO1List(i,j)=RHO1;
        p1List(i,j)=p(1,2);
        PVAL1List(i,j)=PVAL;
    end
           figure
        boxplot(fullBrainFC, 'whisker', 3)
        figure
        boxplot(DS, 'whisker', 3)
end
