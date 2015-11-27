%% Close, clear, and set up for acquisition
clear all;
acqSize = 10000;
com_port = 'COM5'; 

%% Open the serial port
com_port = 'COM5'; 
baud_rate = 250000; 
s = serial(com_port, 'BaudRate', baud_rate);
s.InputBufferSize = 2048; 
fopen(s); 


%% Set up the filters and parameters for acquisition
i=1;
dt=0;
GyroRate=zeros(3,acqSize);
Acc=zeros(3,acqSize);
Magn=zeros(3,acqSize);
t = zeros(1, acqSize);

%% Do the acquisition

% Accelerometer Data
counter = 0; 
disp('Starting acquisition...')
t0 = tic;
while(counter<=acqSize)
    if(i>1)
        t(i)=toc(t0);
    end

    % Get the data
    [D, count, msg] = fread(s, 1024, 'int16');

	% Get the data from the sampler
    % Acc(1:3,i:(i+count-1)) = D(2:4)';
    % GyroRate(1:3,(i+count-1)) = D(5:7)';  
    % Magn(1:3,(i+count-1)) = D(8:10)';
    
    i=i+1;
    counter = counter + count; 
end
disp('Finishing acquisition...')
disp(['Sample rate: ', num2str(counter/max(t))])
disp('Cleaning up...')
    
%% Clean up the serial port from the workspace
fclose(s); 
delete(s)
clear s
