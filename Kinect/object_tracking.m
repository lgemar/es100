%% Load the video objects
clear all
colorVid = videoinput('kinect',1); 
depthVid = videoinput('kinect',2);

%% Set Kinect Properties
disp('Setting acquisition properties...')
NUM_FRAMES = 100; 
colorVid.FramesPerTrigger = NUM_FRAMES;
depthVid.FramesPerTrigger = NUM_FRAMES;
triggerconfig([colorVid depthVid],'manual');

%% Start the color and depth device. 
disp('Starting the Kinect...')
% This begins acquisition, but does not start logging of acquired data.
start([colorVid depthVid]);

% Trigger the devices to start logging of data.
trigger([colorVid depthVid]);

%% Acquire the video into memory
disp('Acquiring the data into memory...'); 
while(colorVid.FramesAcquired ~= NUM_FRAMES || depthVid.FramesAcquired ~= NUM_FRAMES)
    pause(.1); 
end
[rgb_frames, ts1, rgb_metaData] = getdata(colorVid, NUM_FRAMES);
[depth_frames, ts2, depth_metaData] = getdata(depthVid, NUM_FRAMES);
stop([colorVid depthVid]);

%% Set up the object tracker
rgb_frame = rgb_frames(:, :, :, 1); 
disp('Setting up the object tracker...')
hsv_image = rgb2hsv(rgb_frame); 
shapeInserter = vision.ShapeInserter('BorderColor','Custom','CustomBorderColor',[1 0 0]);
tracker = vision.HistogramBasedTracker;
picfig = figure; imshow(rgb_frame); title('Bounding Box');
objectRegion=round(getPosition(imrect));
initializeObject(tracker, hsv_image(:, :, 1), objectRegion)

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
