clear all;
% 120815
% Processing on ABIDA Project

% Initiate the settings.
% 1. Project Dir
ProjectDir ='/home/data/HeadMotion_YCG/YAN_Work/ABIDEProject';%
AutoDataProcessParameter.DataProcessDir=[ProjectDir,filesep,'Processing'];



%% 2. Set Path
addpath /home/data/HeadMotion_YCG/YAN_Program/mdmp
addpath /home/data/HeadMotion_YCG/YAN_Program
addpath /home/data/HeadMotion_YCG/YAN_Program/TRT
addpath /home/data/HeadMotion_YCG/YAN_Program/DPARSF_V2.2PRE_120905
addpath /home/data/HeadMotion_YCG/YAN_Program/spm8
[ProgramPath, fileN, extn] = fileparts(which('DPARSFA_run.m'));
Error=[];
addpath([ProgramPath,filesep,'Subfunctions']);
[SPMversion,c]=spm('Ver');
SPMversion=str2double(SPMversion(end));

% 3. Set Common used variable
BrainMaskFile_MNISpace_REST = '/home/data/HeadMotion_YCG/YAN_Program/REST_V1.8PRE_120905/mask/BrainMask_05_61x73x61.img';
load('/home/data/HeadMotion_YCG/YAN_Work/HeadMotion_YCG/Dosenbach_Science_160ROIs_Center.mat');


ExampleFunc = '/home/data/HeadMotion_YCG/YAN_Work/ABIDEProject/Processing/ExampleFunc.nii.gz';


%% 3. DARTEL template stored ID
%TemplateDir_SubID='sub4143';%





%% 4. Subject ID

load /home/data/HeadMotion_YCG/YAN_Work/ABIDEProject/ABIDE_884Info_Yang.mat
SubID=ABIDE_884Info(2:end,1);
for i=1:length(SubID)
    SubID{i}=['00',num2str(SubID{i})];
end

AutoDataProcessParameter.SubjectID=SubID;
AutoDataProcessParameter.SubjectNum=length(AutoDataProcessParameter.SubjectID);

IQ=ABIDE_884Info(2:end,6);
IQ=cell2mat(IQ);
Dx=ABIDE_884Info(2:end,3);
Dx=cell2mat(Dx);
Dx(Dx==2)=-1; %Control: -1; ASD: +1
Age=cell2mat(ABIDE_884Info(2:end,4));
Sex=cell2mat(ABIDE_884Info(2:end,5));
Site=cell2mat(ABIDE_884Info(2:end,2));



WantedSubMatrix=ones(length(SubID),1);


%%%4.1 Exclude Pitt 2 & Caltech
NoBadSite=ones(length(SubID),1);
NoBadSite(Site==12)=0;%Pitt 2
NoBadSite(Site==3)=0;%Caltech

WantedSubMatrix=WantedSubMatrix.*NoBadSite;

%%%4.2 Exclude subjects that are not in ABIDE released data any more.
ExcludeSubIndexNoIRB = [616,617,618,620,629,633];
ExcludeSubIndexNoT1 = [25,26,34,35,36,37,58,85]; % UCLA subjects without anat images
ExcludeSubIndexTP8 = [647];
%ExcludeSubIndexBadNormalization = [545,649]; % 0050420  0050422 (were excluded before, but not bad now.)
%ExcludeSubIndexNoresults = [421,198,212,323];   %'0050135'    '0050216'    '0050209'    '0051017'

ExcludeSubIndex = [ExcludeSubIndexTP8,ExcludeSubIndexNoIRB,ExcludeSubIndexNoT1];

SUBID_DEBUG=SubID;
WantedSubMatrix(ExcludeSubIndex)=0;



%%%4.3. Deal With Age
AgeRange = [1 100];
%AgeRange = [7 14];

AgeTemp = (Age>=AgeRange(1)) .* (Age<=AgeRange(2));
WantedSubMatrix = WantedSubMatrix.*AgeTemp;

% %%%4.4 Deal with bad coverage
load /home/data/HeadMotion_YCG/YAN_Work/ABIDEProject/SubIDBadCover_Yang.mat
BadCoverTemp=ones(length(SubID),1);
for i=1:length(SubID)
    for j=1:length(SubIDBadCover)
        if strcmpi(SubID{i},SubIDBadCover{j})
            BadCoverTemp(i)=0;
        end
    end
end

WantedSubMatrix=WantedSubMatrix.*BadCoverTemp;

WantedSubIndex = find(WantedSubMatrix);


IQ=IQ(WantedSubIndex);
Dx=Dx(WantedSubIndex);
Age=Age(WantedSubIndex);
Sex=Sex(WantedSubIndex);
Site=Site(WantedSubIndex);
SubID=SubID(WantedSubIndex);

MeanFD=MeanFD(WantedSubIndex);

%% % 4.4. Deal with head motion
MeanFDTemp = MeanFD<(mean(MeanFD)+2*std(MeanFD));

%%%reset MeanFD
WantedSubMatrix = ones(length(MeanFDTemp),1);
WantedSubMatrix = WantedSubMatrix.*MeanFDTemp;


WantedSubIndex = find(WantedSubMatrix);


IQ=IQ(WantedSubIndex);
Dx=Dx(WantedSubIndex);
Age=Age(WantedSubIndex);
Sex=Sex(WantedSubIndex);
Site=Site(WantedSubIndex);
SubID=SubID(WantedSubIndex);

MeanFD=MeanFD(WantedSubIndex);


SiteCov=[];
SiteIndex = unique(Site);
for i=1:length(SiteIndex)-1
    SiteCov(:,i) = Site==SiteIndex(i);
end

AllCov = [Dx,Age,IQ,MeanFD,SiteCov,ones(length(Dx),1)];




%%%

GroupAnalysisOutDir = '/home/data/HeadMotion_YCG/YAN_Work/ABIDEProject/Results/GroupAnalysis/AllSubject763ComCor_noScrub';

%% %%%%%
%Group Analysis for ALFF.

mkdir([GroupAnalysisOutDir,filesep,'ALFF']);
OutputName=[GroupAnalysisOutDir,filesep,'ALFF',filesep,'ALFF']

%Test if all the subjects exist
FileNameSet=[];
for i=1:length(SubID)
    if ~(strcmpi(SubID{i},'0050155') || strcmpi(SubID{i},'0050165'))
        FileName = ['/home2/data/Projects/ABIDE_CPAC_test/SinkDirNoscrubRerun/pipeline_0/',SubID{i},'_session_1/alff_Z_to_standard_smooth/_scan_rest_1_rest/_csf_threshold_0.98/_gm_threshold_0.7/_wm_threshold_0.98/_compcor_ncomponents_5_selector_pc10.linear1.wm0.global0.motion1.quadratic0.gm0.compcor1.csf0/_hp_0.009/_lp_0.1/_fwhm_6/residual_maths_ps_maths_roi_maths_maths_warp_maths.nii.gz'];
    else
        FileName = ['/home2/data/Projects/ABIDE_CPAC_test/SinkDirNoscrubRerun/pipeline_0/',SubID{i},'_session_1/alff_Z_to_standard_smooth/_scan_rest_2_rest/_csf_threshold_0.98/_gm_threshold_0.7/_wm_threshold_0.98/_compcor_ncomponents_5_selector_pc10.linear1.wm0.global0.motion1.quadratic0.gm0.compcor1.csf0/_hp_0.009/_lp_0.1/_fwhm_6/residual_maths_ps_maths_roi_maths_maths_warp_maths.nii.gz'];
    end
    
    if ~exist(FileName,'file')
        disp(SubID{i})
    else
        FileNameSet{i,1}=FileName;
    end
end


%%Regression Analysis
%y_GroupAnalysis_Image(FileNameSet,AllCov,OutputName,'');

%% Make Intersection Mask
%%[DependentVolume,VoxelSize,theImgFileList, Header] =rest_to4d(FileNameSet);

%rest_WriteNiftiImage(squeeze(all(DependentVolume,4)),Header,[OutputName,'_IntersectionMask','.nii']);

%rest_WriteNiftiImage(squeeze(sum(DependentVolume~=0,4)),Header,[OutputName,'_IntersectionMaskCount','.nii']);


%%% Check Mask

% BinarizedMaskAll=(DependentVolume~=0);

%y_Write4DNIfTI(BinarizedMaskAll,Header,[OutputName,'_BinarizedMaskAll','.nii']);

%BinarizedMaskSum=sum(BinarizedMaskAll,4);

 
% mask 790.
%Mask790=BinarizedMaskSum>790;

% rest_WriteNiftiImage(squeeze(all(Mask790,4)),Header,[OutputName,'_IntersectionMask_790','.nii']);
% 
% 
% VoxelNumberOverlapWithMask790=[];
% DiceCoefficients=[];
% 
% for ii=1:size(BinarizedMaskAll,4)
% 
%     Temp = BinarizedMaskAll(:,:,:,ii)+Mask790;
% 
%     
% 
%     VoxelNumberOverlapWithMask790(ii)=length(find(Temp==2));
% 
%     VoxelNumberUnion(ii)=length(find(Temp >= 1));
%     
% 
% end
% 
%  
% 
% VoxelNumberInMask790 = length(find(Mask790));
% 
%  
% 
% VoxelPercentOverlapWithMask790 = VoxelNumberOverlapWithMask790/VoxelNumberInMask790;

%DiceCoefficients =VoxelNumberOverlapWithMask790./VoxelNumberUnion;

%length(find(DiceCoefficients<(mean(DiceCoefficients)-2*std(DiceCoefficients))));

% length(find(VoxelPercentOverlapWithMask790<(mean(VoxelPercentOverlapWithMask790)-2*std(VoxelPercentOverlapWithMask790))))
% 
% SubIDBadCover=SubID(find(VoxelPercentOverlapWithMask790<(mean(VoxelPercentOverlapWithMask790)-2*std(VoxelPercentOverlapWithMask790))));

%% %%%%%
%Group Analysis for fALFF.

mkdir([GroupAnalysisOutDir,filesep,'fALFF']);
OutputName=[GroupAnalysisOutDir,filesep,'fALFF',filesep,'fALFF'];


%Test if all the subjects exist
FileNameSet=[];
for i=1:length(SubID)
    if ~(strcmpi(SubID{i},'0050155') || strcmpi(SubID{i},'0050165'))
        FileName = ['/home2/data/Projects/ABIDE_CPAC_test/SinkDirNoscrubRerun/pipeline_0/',SubID{i},'_session_1/falff_Z_to_standard_smooth/_scan_rest_1_rest/_csf_threshold_0.98/_gm_threshold_0.7/_wm_threshold_0.98/_compcor_ncomponents_5_selector_pc10.linear1.wm0.global0.motion1.quadratic0.gm0.compcor1.csf0/_hp_0.009/_lp_0.1/_fwhm_6/residual_maths_ps_maths_roi_maths_maths_maths_warp_maths.nii.gz'];
    else
        FileName = ['/home2/data/Projects/ABIDE_CPAC_test/SinkDirNoscrubRerun/pipeline_0/',SubID{i},'_session_1/falff_Z_to_standard_smooth/_scan_rest_2_rest/_csf_threshold_0.98/_gm_threshold_0.7/_wm_threshold_0.98/_compcor_ncomponents_5_selector_pc10.linear1.wm0.global0.motion1.quadratic0.gm0.compcor1.csf0/_hp_0.009/_lp_0.1/_fwhm_6/residual_maths_ps_maths_roi_maths_maths_maths_warp_maths.nii.gz'];
    end
    
    if ~exist(FileName,'file')
        disp(SubID{i})
    else
        FileNameSet{i,1}=FileName;
    end
end

%y_GroupAnalysis_Image(FileNameSet,AllCov,OutputName,'');

%%
%Group Analysis for DC.

mkdir([GroupAnalysisOutDir,filesep,'DC']);
NodeName={'binarize';'weighted'};

for iNodeName= 1:length(NodeName)
    OutputName=[GroupAnalysisOutDir,filesep,'DC',filesep,'DC_',NodeName{iNodeName}],

    %Test if all the subjects exist
    FileNameSet=[];
    for i=1:length(SubID)
        if ~(strcmpi(SubID{i},'0050155') || strcmpi(SubID{i},'0050165'))
            FileName = ['/home2/data/Projects/ABIDE_CPAC_test/SinkDirNoscrubRerun/sym_links/pipeline_0/_compcor_ncomponents_5_linear1.motion1.compcor1.CSF_0.98_GM_0.7_WM_0.98/',SubID{i},'_session_1/scan_rest_1_rest/centrality/mask_Group_IntersectionMask_95_Grey_3mm/bandpass_freqs_0.009.0.1/fwhm_6/degree_centrality_',NodeName{iNodeName},'_maths_maths.nii.gz'];
         
        else
            FileName = ['/home2/data/Projects/ABIDE_CPAC_test/SinkDirNoscrubRerun/sym_links/pipeline_0/_compcor_ncomponents_5_linear1.motion1.compcor1.CSF_0.98_GM_0.7_WM_0.98/',SubID{i},'_session_1/scan_rest_2_rest/centrality/mask_Group_IntersectionMask_95_Grey_3mm/bandpass_freqs_0.009.0.1/fwhm_6/degree_centrality_',NodeName{iNodeName},'_maths_maths.nii.gz'];
        end
    
        if ~exist(FileName,'file')
            disp(SubID{i})
        else
           FileNameSet{i,1}=FileName;
        end
    end


    %%Regression Analysis
    %y_GroupAnalysis_Image(FileNameSet,AllCov,OutputName,'');
    yang_residual_gen_image.m(FileNameSet,AllCov,OutputName,'')

end

%% %%%%%
%Group Analysis for VMHC.

mkdir([GroupAnalysisOutDir,filesep,'VMHC']);
OutputName=[GroupAnalysisOutDir,filesep,'VMHC',filesep,'VMHC']


%Test if all the subjects exist
FileNameSet=[];
for i=1:length(SubID)
    if ~(strcmpi(SubID{i},'0050155') || strcmpi(SubID{i},'0050165'))
        FileName = ['/home2/data/Projects/ABIDE_CPAC_test/SinkDirNoscrubRerun/pipeline_0/',SubID{i},'_session_1/vmhc_z_score_stat_map/_scan_rest_1_rest/_csf_threshold_0.98/_gm_threshold_0.7/_wm_threshold_0.98/_compcor_ncomponents_5_selector_pc10.linear1.wm0.global0.motion1.quadratic0.gm0.compcor1.csf0/_bandpass_freqs_0.009.0.1/_fwhm_6/bandpassed_demeaned_filtered_maths_warp_3dTcor_3dc_3dc.nii.gz'];
    else
        FileName = ['/home2/data/Projects/ABIDE_CPAC_test/SinkDirNoscrubRerun/pipeline_0/',SubID{i},'_session_1/vmhc_z_score_stat_map/_scan_rest_2_rest/_csf_threshold_0.98/_gm_threshold_0.7/_wm_threshold_0.98/_compcor_ncomponents_5_selector_pc10.linear1.wm0.global0.motion1.quadratic0.gm0.compcor1.csf0/_bandpass_freqs_0.009.0.1/_fwhm_6/bandpassed_demeaned_filtered_maths_warp_3dTcor_3dc_3dc.nii.gz'];
    end
    
    if ~exist(FileName,'file')
        disp(SubID{i})
    else
        FileNameSet{i,1}=FileName;
    end
end

%y_GroupAnalysis_Image(FileNameSet,AllCov,OutputName,'');


%%%%%%%
%Group Analysis for ReHo.

mkdir([GroupAnalysisOutDir,filesep,'ReHo']);
OutputName=[GroupAnalysisOutDir,filesep,'ReHo',filesep,'ReHo'];


%Test if all the subjects exist
FileNameSet=[];
for i=1:length(SubID)
    if ~(strcmpi(SubID{i},'0050155') || strcmpi(SubID{i},'0050165'))
        FileName = ['/home2/data/Projects/ABIDE_CPAC_test/SinkDirNoscrubRerun/pipeline_0/',SubID{i},'_session_1/reho_Z_to_standard_smooth/_scan_rest_1_rest/_csf_threshold_0.98/_gm_threshold_0.7/_wm_threshold_0.98/_compcor_ncomponents_5_selector_pc10.linear1.wm0.global0.motion1.quadratic0.gm0.compcor1.csf0/_bandpass_freqs_0.009.0.1/_fwhm_6/ReHo_maths_warp_maths.nii.gz'];
        %if ~exist(FileName,'file')
        %    FileName = ['/home2/data/Projects/ABIDE_CPAC_test/SinkDirNoscrubRerun/pipeline_0/',SubID{i},'/reho/scan_id_rest_1/scan_id_anat_1/csf_threshold_0.4/gm_threshold_0.2/wm_threshold_0.66/nc_5/selector_1.6.7/threshold_1/bandpass_freqs_0.009.0.1/scrubbed_False/fwhm_6/ReHo_Z_fn2standard_smooth.nii.gz'];
        %end
    else
        FileName = ['/home2/data/Projects/ABIDE_CPAC_test/SinkDirNoscrubRerun/pipeline_0/',SubID{i},'_session_1/reho_Z_to_standard_smooth/_scan_rest_2_rest/_csf_threshold_0.98/_gm_threshold_0.7/_wm_threshold_0.98/_compcor_ncomponents_5_selector_pc10.linear1.wm0.global0.motion1.quadratic0.gm0.compcor1.csf0/_bandpass_freqs_0.009.0.1/_fwhm_6/ReHo_maths_warp_maths.nii.gz'];
    end
    
    if ~exist(FileName,'file')
        disp(SubID{i})
    else
        FileNameSet{i,1}=FileName;
    end
end

%y_GroupAnalysis_Image(FileNameSet,AllCov,OutputName,'');




%%%%%%%
%Group Analysis for SCA.

mkdir([GroupAnalysisOutDir,filesep,'SCA']);
OutputName=[GroupAnalysisOutDir,filesep,'SCA',filesep,'SCA'];


SeedSet={  'dMPFC';  'PCC';  'PHC';  'pIPL';  'Rsp'; 'TPJ'; 'aMPFC'; }; % took  'HF'; 'TempP'; 'LTC'; 'vMPFC' out of analysis because some subjects failed this.

for iSeed=1:length(SeedSet)
    
    
    OutputName=[GroupAnalysisOutDir,filesep,'SCA',filesep,'SCA_',SeedSet{iSeed}],
    
    %Test if all the subjects exist
    FileNameSet=[];
    for i=1:length(SubID)
        if ~(strcmpi(SubID{i},'0050155') || strcmpi(SubID{i},'0050165'))
            FileName = ['/home2/data/Projects/ABIDE_CPAC_test/SinkDirNoscrubRerun/pipeline_0/',SubID{i},'_session_1/sca_seed_Z_to_standard_smooth/_scan_rest_1_rest/_csf_threshold_0.98/_gm_threshold_0.7/_wm_threshold_0.98/_compcor_ncomponents_5_selector_pc10.linear1.wm0.global0.motion1.quadratic0.gm0.compcor1.csf0/_bandpass_freqs_0.009.0.1/_mask_',SeedSet{iSeed},'/_fwhm_6/_sca_seed_Z_to_standard_smooth_00/z_score_warp_maths.nii.gz'];
            %if ~exist(FileName,'file')
            %    FileName = ['/home2/data/Projects/ABIDE_CPAC_test/SinkDirNoscrubRerun/pipeline_0/',SubID{i},'sca_seed_Z_to_standard_smooth/_scan_rest_1_rest/_csf_threshold_0.98/_gm_threshold_0.7/_wm_threshold_0.98/_compcor_ncomponents_5_selector_pc10.linear1.wm0.global0.motion1.quadratic0.gm0.compcor1.csf0/_bandpass_freqs_0.009.0.1/_mask_',SeedSet{iSeed},'/_fwhm_6/_sca_seed_Z_to_standard_smooth_00/z_score_warp_maths.nii.gz'];
            %end
        else
            FileName = ['/home2/data/Projects/ABIDE_CPAC_test/SinkDirNoscrubRerun/pipeline_0/',SubID{i},'_session_1/sca_seed_Z_to_standard_smooth/_scan_rest_2_rest/_csf_threshold_0.98/_gm_threshold_0.7/_wm_threshold_0.98/_compcor_ncomponents_5_selector_pc10.linear1.wm0.global0.motion1.quadratic0.gm0.compcor1.csf0/_bandpass_freqs_0.009.0.1/_mask_',SeedSet{iSeed},'/_fwhm_6/_sca_seed_Z_to_standard_smooth_00/z_score_warp_maths.nii.gz'];
        end
      
        if ~exist(FileName,'file')
            disp(SubID{i})
        else
            FileNameSet{i,1}=FileName;
        end
    end
    
    
    %y_GroupAnalysis_Image(FileNameSet,AllCov,OutputName,'');
    
end






%%%%%%%
%Group Analysis for SCA Striatum.

mkdir([GroupAnalysisOutDir,filesep,'SCAStriatum']);
OutputName=[GroupAnalysisOutDir,filesep,'SCAStriatum',filesep,'SCA'];


SeedSet={'VSi_L_2mm';'VSi_R_2mm';'DC_L_2mm';'dcP_L_2mm';'drP_L_2mm';'vrP_L_2mm';'VSs_L_2mm';'DC_R_2mm';'dcP_R_2mm';'drP_R_2mm';'vrP_R_2mm';'VSs_R_2mm'};


for iSeed=1:length(SeedSet)
    
    
    OutputName=[GroupAnalysisOutDir,filesep,'SCA',filesep,'SCA_',SeedSet{iSeed}]
    
    %Test if all the subjects exist
    FileNameSet=[];
    for i=1:length(SubID)
        if ~(strcmpi(SubID{i},'0050155') || strcmpi(SubID{i},'0050165'))
            FileName = ['/home2/data/Projects/ABIDE_CPAC_test/SinkDirNoscrubRerun/pipeline_0/',SubID{i},'_session_1/sca_seed_Z_to_standard_smooth/_scan_rest_1_rest/_csf_threshold_0.98/_gm_threshold_0.7/_wm_threshold_0.98/_compcor_ncomponents_5_selector_pc10.linear1.wm0.global0.motion1.quadratic0.gm0.compcor1.csf0/_bandpass_freqs_0.009.0.1/_mask_',SeedSet{iSeed},'/_fwhm_6/_sca_seed_Z_to_standard_smooth_00/z_score_warp_maths.nii.gz'];
            %if ~exist(FileName,'file')
            %    FileName = ['/home2/data/Projects/ABIDE_CPAC_test/SinkDirNoscrubRerun/pipeline_0/',SubID{i},'sca_seed_Z_to_standard_smooth/_scan_rest_1_rest/_csf_threshold_0.98/_gm_threshold_0.7/_wm_threshold_0.98/_compcor_ncomponents_5_selector_pc10.linear1.wm0.global0.motion1.quadratic0.gm0.compcor1.csf0/_bandpass_freqs_0.009.0.1/_mask_',SeedSet{iSeed},'/_fwhm_6/_sca_seed_Z_to_standard_smooth_00/z_score_warp_maths.nii.gz'];
            %end
        else
            FileName = ['/home2/data/Projects/ABIDE_CPAC_test/SinkDirNoscrubRerun/pipeline_0/',SubID{i},'_session_1/sca_seed_Z_to_standard_smooth/_scan_rest_2_rest/_csf_threshold_0.98/_gm_threshold_0.7/_wm_threshold_0.98/_compcor_ncomponents_5_selector_pc10.linear1.wm0.global0.motion1.quadratic0.gm0.compcor1.csf0/_bandpass_freqs_0.009.0.1/_mask_',SeedSet{iSeed},'/_fwhm_6/_sca_seed_Z_to_standard_smooth_00/z_score_warp_maths.nii.gz'];
        end
        
        if ~exist(FileName,'file')
            disp(SubID{i})
        else
            FileNameSet{i,1}=FileName;
        end
    end
    
    
    %y_GroupAnalysis_Image(FileNameSet,AllCov,OutputName,'');
    
end
