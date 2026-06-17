%% TS_Initialize with specified parameters to exclude figure generation

clear;
clc;

load('.\AllP_AllCases.mat');

% Initialize hctsa analysis with  specified beVocal parameter


TS_Init('AllP_AllCases.mat',[],[],[false,false,false]);