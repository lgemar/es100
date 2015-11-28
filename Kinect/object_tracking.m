%% Load the video objects
K = Kinect(); 

%% Record video with the Kinect
disp('Setting acquisition properties...')
NUM_FRAMES = 100; 
disp('Starting the Kinect...')
K.startAcq(NUM_FRAMES);

%% Acquire the video into memory
disp('Acquiring the data into memory...'); 
[rgb_frames, depth_frames] = K.getFrames(NUM_FRAMES);

K.stopAcq();

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
