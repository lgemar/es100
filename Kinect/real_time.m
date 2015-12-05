%% Variables of interest
N = 1000; 

% Acquire data into memory before logging it
colorVid = videoinput('kinect',1); 
depthVid = videoinput('kinect',2);

% Set Kinect Properties
set([colorVid depthVid], 'FramesPerTrigger', 1);
set([colorVid depthVid], 'TriggerRepeat', Inf);
triggerconfig([colorVid depthVid], 'manual');

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
t = 0;
ttrig = 0; 
while(1)
    % Extend the time array
	if(i > 1)
        t = [t toc(t0)];
        if( (ttrig - t(end)) > 1 )
            trigger([colorVid depthVid]); 
            % Get the data
            rgb_frame = getdata(colorVid); depth_frame = getdata(depthVid);
            % Find the bounding box for the selected object
            [x1, x2, x3] = findPosition(rgb_frame, depth_frame, tracker); 
            toc(t0)
        end
    end
end

%% 
stop([colorVid depthVid]);
delete(colorVid)
delete(depthVid)
clear colorVid
clear depthVid
