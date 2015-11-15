function [ N, RGB, RGBts, DEPTH, DEPTHts ] = readKinectData( fileID )
%readKinectData Given an acquisition ID, read back the vid and metadata
%  OUTPUTS: 
%  N = number of frames
%  RBG = rbg video data
%  D = depth video data
%  RGBMeta = RGB metadata
%  DMeta = Depth metadata

% Read the rgb video data
v1 = VideoReader([fileID, '_rgb', '.mj2']);
v2 = VideoReader([fileID, '_depth', '.mj2']);
rgb_video = read(v1); 
depth_video = read(v2); 

% Read in the metadata to memory
rgb_table = readtable([fileID, '_rgb_metadata', '.csv']); 
depth_table = readtable([fileID, '_depth_metadata', '.csv']); 

% Grab the sec time stamps
rgb_ts = table2array(rgb_table(:, 5)) * 60 + table2array(rgb_table(:, 6)); 
depth_ts = table2array(depth_table(:, 5)) * 60 + table2array(depth_table(:, 6)); 

% Find the starting time
start_time = max(rgb_ts(1, 1), depth_ts(1, 1)); 
end_time = min(rgb_ts(end, 1), depth_ts(end, 1)); 

% Assume that the rgb video started first
rgbIDX = [find(rgb_ts <= start_time, 1, 'last'), find(rgb_ts >= end_time, 1, 'first')]; 
depthIDX = [find(depth_ts <= start_time, 1, 'last'), find(depth_ts >= end_time, 1,   'first')];

% Index into the data sets and return
N = rgbIDX(2) - rgbIDX(1);  
RGB = rgb_video(:, :, :, rgbIDX(1):rgbIDX(2)); 
RGBts = rgb_ts(rgbIDX(1):rgbIDX(2)); 
DEPTH = depth_video(:, :, :, rgbIDX(1):rgbIDX(2)); 
DEPTHts = depth_ts(depthIDX(1):depthIDX(2)); 
end

