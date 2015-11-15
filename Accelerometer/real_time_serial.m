N = 10000; 

% Open the serial port
com_port = 'COM5'; 
baud_rate = 38400; 
s = serial(com_port, 'BaudRate', baud_rate);
fopen(s); 

% Set the format specification for reading from the serial port
formatspec  = ['a/g/m:\t' '%d\t' '%d\t' '%d\t' '%d\t' '%d\t' '%d\t' '%d\t' '%d\t' '%d\n']; 

% Allocate memory for the various data streams
taxis = zeros(1, N); 
ax = zeros(1, N); ay = zeros(1, N); az = zeros(1, N); 
gx = zeros(1, N); gy = zeros(1, N); gz = zeros(1, N); 
mx = zeros(1, N); my = zeros(1, N); mz = zeros(1, N);

% Open the figures
h1 = figure(1);
subplot(3, 2, 1); sax = line(0, 0, 'Color', 'b'); ylim([-2 2]); 
subplot(3, 2, 2); svx = line(0, 0, 'Color', 'r');
subplot(3, 2, 3); say = line(0, 0, 'Color', 'b'); ylim([-2 2]);
subplot(3, 2, 4); svy = line(0, 0, 'Color', 'r'); 
subplot(3, 2, 5); saz = line(0, 0, 'Color', 'b'); ylim([-2 2]);
subplot(3, 2, 6); svz = line(0, 0, 'Color', 'r'); 

% Initialize the 
try
    start_time = datenum(datetime('now')); 
    idx = 2; 
    while (ishandle(h1))
        data = fscanf(s, formatspec); %do some process
        if( size(data) ~= 9 )
            continue; % If the serial read was bad, try again
        end
        t = 86400 * (datenum(datetime('now')) - start_time);
        taxis(idx) = t; 
        dt = t - taxis(idx - 1); 
        
        % Calibration: 2^14 ~ 1g
        ax = data(1) / 2^14; ay = data(2) / 2^14; az = data(3) / 2^14; 
        gx = data(4); gy = data(5); gz = data(6); 
        mx = data(7); my = data(8); mz = data(9); 

        % Plot the accelerometer data (x)
        tax = get(sax, 'XData');
        yax = get(sax, 'YData'); 
        tax = [tax t];
        yax = [yax ax];
        set(sax, 'XData', tax, 'YData', yax);
        
		% Plot the velocity data (x)
        tvx = get(svx, 'XData');
        yvx = get(svx, 'YData'); 
        tvx = [tvx t];
        dv = 0.5*ax*dt; 
        yvx = [yvx (yvx(end)+dv)]; % integrate the acceleration
        set(svx, 'XData', tvx, 'YData', yvx);
        
        % Plot the accelerometer data (y)
        tay = get(say, 'XData');
        yay = get(say, 'YData');
        tay = [tay t];
        yay = [yay ay];
        set(say, 'XData', tay, 'YData', yay);

		% Plot the velocity data (y)
        tvy = get(svy, 'XData');
        yvy = get(svy, 'YData'); 
        tvy = [tvy t];
        dv = 0.5*ay*dt; 
        yvy = [yvy (yvy(end)+dv)]; % integrate the acceleration
        set(svy, 'XData', tvy, 'YData', yvy);

        % plot the accelerometer data (z)
        taz = get(saz, 'xdata');
        yaz = get(saz, 'YData');
        taz = [taz t];
        yaz = [yaz az];
        set(saz, 'XData', taz, 'YData', yaz);

		% Plot the velocity data (z)
        tvz = get(svz, 'XData');
        yvz = get(svz, 'YData'); 
        tvz = [tvz t];
        dv = 0.5*az*dt; 
        yvz = [yvz (yvz(end)+dv)]; % integrate the acceleration
        set(svz, 'XData', tvz, 'YData', yvz);

        % Clean up the loop
        idx = mod((idx + 1), 1000) + 1; 
        
        % Plot the data after every 10 frames to increase speed
		%flush the graphics queue
        drawnow limitrate 
    end

    % Clean up the serial port from the workspace
    fclose(s); 
    delete(s)
    clear s
catch
    % Clean up the serial port from the workspace
    fclose(s); 
    delete(s)
    clear s
end
