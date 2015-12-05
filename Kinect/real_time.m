%% Variables of interest

% Sample rates, frequencies, and periods
N = 3; % Number of seconds for the acquisition
Tfk = 10; % Number of Kinect samples per second
Tfa = 300; % Number of accelerometer samples per second
Tsk = 1/Tfk; % Period for Kinect samples
Tsa = 1/Tfa; % Period for accelerometer samples

% Estimate the number of data points taken in the acquisition
NKnct = N * Tfk + 1; 
NAcc = N * Tfa + 1; 

% Allocate memory for all the acquisitions
KnctData = zeros(3, NKnct);
AccData = zeros(3, NAcc);
GyroData = zeros(3, NAcc); 

% Allocate memory for the time stamps
tKnct = zeros(1, NKnct);
tAcc = zeros(1, NAcc); 

% Counters
j = 2; % Accelerometer sample counter
k = 2; % Kinect frame counter

%% Setup the Kinect acquisition variables
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
disp('Starting data acquisition...')
t0 = tic; t = 0;
while(t < N)
% Extend the time array
    t = toc(t0); % Get the time at the beginning of the loop
    if( (t - tAcc(j-1)) > Tsa )
        % Set the time stamp for the sample
        tAcc(j) = t; 
        % Get the data
        D = A.getDataSample(); 
        % Store the data for later
        AccData(1:3,j) = D(1:3)';
        GyroData(1:3,j) = D(4:6)';
        % Increment the sample counter
        j = j+1; 
    end
    if( (t - tKnct(k-1)) > Tsk )
        % Set the time stamp for the sample
        tKnct(k) = t; 
        % Get the data
        trigger([colorVid depthVid]);
        rgb_frame = getdata(colorVid); depth_frame = getdata(depthVid);
        [x, y, d] = findPosition(rgb_frame, depth_frame, tracker); 
        % Store the data for later
        KnctData(:,k) = [x;y;d]; 
        % Increment the sample counter
        k = k+1; 
        toc(t0)
    end
end

%% Reduce the sample vectors to their true size
tKnct = tKnct(:,2:(k-1));
KnctData = KnctData(:,2:(k-1));
tAcc = tAcc(:,2:(j-1));
AccData = AccData(:,2:(j-1));
GyroData = GyroData(:,2:(j-1));
disp(['Sampling frequency (Kinect): ' num2str(length(tKnct)/(max(tKnct)-min(tKnct)))])
disp(['Sampling frequency (Acc): ' num2str(length(tAcc)/(max(tAcc)-min(tKnct)))])

%% Deinialize
disp('Cleaning up...')
stop([colorVid depthVid]);

A.close(); 
A.delete(); 
clear A

delete(colorVid)
delete(depthVid)
clear colorVid
clear depthVid
