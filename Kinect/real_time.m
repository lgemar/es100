%% Variables of interest
N = 100; 

% Acquire data into memory before logging it
colorVid = videoinput('kinect',1); 
depthVid = videoinput('kinect',2);

% Set Kinect Properties
set([colorVid depthVid], 'FramesPerTrigger', 1);
set([colorVid depthVid], 'TriggerRepeat', Inf);
triggerconfig([colorVid depthVid], 'manual');

%% Set up accelerometer variables
addpath('..\Accelerometer')
com_port = 'COM8'; 
acqSize = 10000; 
GyroRate=zeros(3,acqSize);
Acc=zeros(3,acqSize);
A = Accelerometer(com_port); 
A = A.calibrate();

%% Start the color and depth device. This begins acquisition, but does not
% start logging of acquired data.
start([colorVid depthVid]);

% Trigger the devices to start logging of data.
trigger([colorVid depthVid]);

% Retrieve the acquired data
rgb_image = getdata(colorVid);

% Select the colored region to track
disp('Setting up the object tracker...')
tracker = initializeTracker(rgb_image);

%%
t0 = tic; 
t = 0; ttrig = 0; i = 0; 
while(i <= N)
% Extend the time array
    t = [t toc(t0)];
    if( (t(end) - ttrig) > 0.5 )
        trigger([colorVid depthVid]); i = i+1; 
        ttrig = t(end); 
        % Get the data
        rgb_frame = getdata(colorVid); depth_frame = getdata(depthVid);
        % Find the bounding box for the selected object
        [x1, x2, x3] = findPosition(rgb_frame, depth_frame, tracker); 
        toc(t0)
    end
    % Get the data
    D = A.getDataSample();
end

%% 
stop([colorVid depthVid]);
delete(colorVid)
delete(depthVid)
clear colorVid
clear depthVid
