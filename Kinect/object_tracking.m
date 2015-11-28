%% Load the video objects
clear all
K = Kinect(); 

%% Record video with the Kinect
disp('Setting acquisition properties...')
disp('Starting the Kinect...')
K.startAcq(100);

%% Acquire the video into memory
disp('Acquiring the data into memory...'); 
while(colorVid.FramesAcquired ~= NUM_FRAMES || depthVid.FramesAcquired ~= NUM_FRAMES)
    pause(.1); 
end
[rgb_frames, ts1, rgb_metaData] = getdata(colorVid, NUM_FRAMES);
[depth_frames, ts2, depth_metaData] = getdata(depthVid, NUM_FRAMES);
stop([colorVid depthVid]);

%% Set up the object tracker
disp('Setting up the object tracker...')
tracker = initializeTracker(rgb_frames(:, :, :, 1));

%% Compute the position vs time
disp('Computing the position vs time...'); 
[x, y, d] = positionVsTime(depth_frames, rgb_frames, tracker); 

%% Plot the data
disp('Plotting the data...'); 
figure(1) 
plot(d); title('Depth vs time'); xlabel('Sample number'); ylabel('Pixel depth'); 

%% Compute the mean and the variance of the depth data
% format long
% m = mean(d); 
% s = std(d); 

%% Compute the average x,y,z position for centroid calculations
xavg = mean(x); 
yavg = mean(y);
davg = mean(d); 

centroid = [xavg, davg, yavg]
