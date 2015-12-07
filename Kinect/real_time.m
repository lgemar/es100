%% Variables of interest

% Sample rates, frequencies, and periods
N = 15; % Number of seconds for the acquisition
Tfk = 2; % Number of Kinect samples per second
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
com_port = 'COM6'; 
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
    % Here's where you'll try to recompute the actual position
end

%% Reduce the sample vectors to their true size
tKnct = tKnct(:,2:(k-1));
KnctData = KnctData(:,2:(k-1));
tAcc = tAcc(:,2:(j-1));
AccData = AccData(:,2:(j-1));
GyroData = GyroData(:,2:(j-1));
disp(['Sampling frequency (Kinect): ' num2str(length(tKnct)/(max(tKnct)-min(tKnct)))])
disp(['Sampling frequency (Acc): ' num2str(length(tAcc)/(max(tAcc)-min(tKnct)))])

%% Visualize the raw Kinect data
% Plot the x-z dimensions of the Kinect data
c = linspace(1,10,size(KnctData,2));
figure;
subplot(1,2,1)
scatter(KnctData(1,:),640-KnctData(2,:),[],c)
xlim([0 640])
ylim([0 480])
% Plot the y-z dimensions of the Kinect data
subplot(1,2,2)
scatter(KnctData(3,:),640-KnctData(2,:),[],c)
xlim([700 2000])
ylim([0 480])

%% Visualize the raw accelerometer data
AccVel = integrate3D(tAcc,AccData); 

AccPos = integrate3D(tAcc,AccVel);

figure; 
subplot(1,3,1)
plot(tAcc,AccData(1,:),'r',tAcc,AccVel(1,:),'g',tAcc,AccPos(1,:),'b')
title('Raw Accelerometer Data (X)')
xlabel('time (s)')
ylabel('distance (m)')
subplot(1,3,2)
plot(tAcc,AccData(2,:),'r',tAcc,AccVel(2,:),'g',tAcc,AccPos(2,:),'b')
title('Raw Accelerometer Data (Y)')
xlabel('time (s)')
ylabel('distance (m)')
subplot(1,3,3)
plot(tAcc,AccData(3,:),'r',tAcc,AccVel(3,:),'g',tAcc,AccPos(3,:),'b')
title('Raw Accelerometer Data (Z)')
xlabel('time (s)')
ylabel('distance (m)')

figure;
c = linspace(1,10,size(AccData,2));
scatter(AccPos(1,:),AccPos(3,:),[], c)

%% Transform the kinect data

%% Transform the accelerometer data
window_size = 50;
acc_filter = ones(window_size,1) * 1/window_size; 
AccFiltData = [];
for i = 1:length(tAcc)
    if(i < window_size)
        AccFiltData = [AccFiltData, AccData(:,1:i) * acc_filter(1:i)];
    else
        AccFiltData = [AccFiltData, AccData(:,(i - window_size + 1):i) * acc_filter];
    end
end

AccFiltVel = integrate3D(tAcc,AccFiltData);
AccFiltPos = integrate3D(tAcc,AccFiltVel);

figure; 
subplot(1,3,1)
plot(tAcc,AccFiltData(1,:),'r',tAcc,AccFiltVel(1,:),'g',tAcc,AccFiltPos(1,:),'b')
title('Filtered Accelerometer Data (X)')
xlabel('time (s)')
ylabel('distance (m)')
subplot(1,3,2)
plot(tAcc,AccFiltData(2,:),'r',tAcc,AccFiltVel(2,:),'g',tAcc,AccFiltPos(2,:),'b')
title('Filtered Accelerometer Data (Y)')
xlabel('time (s)')
ylabel('distance (m)')
subplot(1,3,3)
plot(tAcc,AccFiltData(3,:),'r',tAcc,AccFiltVel(3,:),'g',tAcc,AccFiltPos(3,:),'b')
title('Filtered Accelerometer Data (Z)')
xlabel('time (s)')
ylabel('distance (m)')



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
