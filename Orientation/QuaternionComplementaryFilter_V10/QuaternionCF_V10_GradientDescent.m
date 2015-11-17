clear all;
close all;
%Connect to the INEMO device
[handle_dev pFD]=INEMO_Connection();
%End connection
acqSize=300;

%Gyroscope statistics
Offset=[-3.6982,-3.3570,-2.5909]';

%Acquisition variables
GyroRate=zeros(3,acqSize);
Acc=zeros(3,acqSize);
Magn=zeros(3,acqSize);
Angles=zeros(3,acqSize);
AccF=zeros(3,acqSize);
MagnF=zeros(3,acqSize);
mu=zeros(1,acqSize);
dqnorm=zeros(1,acqSize);
dq=zeros(4,acqSize);
err=zeros(4,acqSize);

%Observation vector (accelerometer and magnetometer)
qOsserv=zeros(4,acqSize);
qOsserv(:,1)=[1 0 0 0]';
%Gyrofilt vector
qGyroFilt=zeros(4,acqSize);
qGyroFilt(:,1)=[1 0 0 0]';
%Filtered vector
qFilt=zeros(4,acqSize);
qFilt(:,1)=[1 0 0 0]';

%----------
t=[0];

i=1;
dt=0;

[bAcc,aAcc] = butter(3,0.0075,'low');
[bMagn,aMagn] = butter(2,0.06,'low');

magnF_Length=13;
accF_Length=13;

%Bring up the filters
while(i<=accF_Length+4)
    if(i>1)
        dt = toc(t0);
        t=[t t(length(t))+dt];
    end
    
    [errre pFD]=calllib('iNEMO2_SDK','INEMO2_GetDataSample',handle_dev,pFD);
    t0 = tic;

        %----------
        pause(0.01)
        %---------
        
    Acc(1,i)=pFD.Accelerometer.X;
    Acc(2,i)=pFD.Accelerometer.Y;
    Acc(3,i)=pFD.Accelerometer.Z;
    Magn(1,i)=pFD.Magnetometer.X;
    Magn(2,i)=pFD.Magnetometer.Y;
    Magn(3,i)=pFD.Magnetometer.Z;
    GyroRate(1,i)=((pFD.Gyroscope.X-Offset(1,1))/180)*pi;
    GyroRate(2,i)=((pFD.Gyroscope.Y-Offset(2,1))/180)*pi;
    GyroRate(3,i)=((pFD.Gyroscope.Z-Offset(3,1))/180)*pi;
    
    Acc(:,i)=Acc(:,i)/norm(Acc(:,i));
    Magn(:,i)=Magn(:,i)/norm(Magn(:,i));
    if(i<=accF_Length)
        AccF(:,i)=MyFilter(bAcc,aAcc,Acc(:,:));
    else
        AccF(:,i)=MyFilter(bAcc,aAcc,Acc(:,i-accF_Length:i));
    end
    if(i<=magnF_Length)
        MagnF(:,i)=MyFilter(bMagn,aMagn,Magn(:,:));
    else
        MagnF(:,i)=MyFilter(bMagn,aMagn,Magn(:,i-magnF_Length:i));
    end
    MagnF(:,i)=MagnF(:,i)/norm(MagnF(:,i));
    AccF(:,i)=AccF(:,i)/norm(AccF(:,i));
    i=i+1;
    qOsserv(:,i)=qOsserv(:,i-1);
    qFilt(:,i)=qFilt(:,i-1);
    qGyroFilt(:,i)=qGyroFilt(:,i-1);
end



while(i<=acqSize)
    if(i>2)
        dt = toc(t0);
        t=[t t(length(t))+dt];
    end
    %dt=0.015;
    %----Acquisition
        [errre pFD]=calllib('iNEMO2_SDK','INEMO2_GetDataSample',handle_dev,pFD);
        t0 = tic;

        %----------
        pause(0.01)
        %---------
        
    Acc(1,i)=pFD.Accelerometer.X;
    Acc(2,i)=pFD.Accelerometer.Y;
    Acc(3,i)=pFD.Accelerometer.Z;
    Magn(1,i)=pFD.Magnetometer.X;
    Magn(2,i)=pFD.Magnetometer.Y;
    Magn(3,i)=pFD.Magnetometer.Z;
    GyroRate(1,i)=((pFD.Gyroscope.X-Offset(1,1))/180)*pi;
    GyroRate(2,i)=((-pFD.Gyroscope.Y+Offset(2,1))/180)*pi;
    GyroRate(3,i)=((pFD.Gyroscope.Z-Offset(3,1))/180)*pi;
    
    GyroRate(1,i)=(GyroRate(1,i)+GyroRate(1,i-1))/2;
    GyroRate(2,i)=(GyroRate(2,i)+GyroRate(2,i-1))/2;
    GyroRate(3,i)=(GyroRate(3,i)+GyroRate(3,i-1))/2;
    
    %Normalization and filtering
    Acc(:,i)=Acc(:,i)/norm(Acc(:,i));
    Magn(:,i)=Magn(:,i)/norm(Magn(:,i));
    
    AccF(:,i)=MyFilter(bAcc,aAcc,Acc(:,i-accF_Length:i));
    MagnF(:,i)=MyFilter(bMagn,aMagn,Magn(:,i-magnF_Length:i));
    
    MagnF(:,i)=MagnF(:,i)/norm(MagnF(:,i));
    AccF(:,i)=AccF(:,i)/norm(AccF(:,i));
    %----End Acquisition
    

        
    dq(:,i)=0.5*(QuaternionProduct(qFilt(:,i-1),[0 GyroRate(1,i) GyroRate(2,i) GyroRate(3,i)]'));
    dqnorm(1,i)=norm(dq(:,i));
    mu(1,i)=10*dqnorm(1,i)*dt;
    qOsserv(:,i)=GradientDescent(AccF(:,i),MagnF(:,i),qOsserv(:,i-1),mu(1,i));
    qOsserv(:,i)=qOsserv(:,i)/norm(qOsserv(:,i));
    
    if(i<=accF_Length+10)
        qGyroFilt(:,i)=qOsserv(:,i);
        qFilt(:,i)=qOsserv(:,i);
    else
        qGyroFilt(:,i)=qFilt(:,i-1)+dq(:,i)*dt;
        qGyroFilt(:,i)=qGyroFilt(:,i)/norm(qGyroFilt(:,i));

        dqnorm(1,i)=norm(dq(:,i));
        mu(1,i)=10*dqnorm(1,i)*dt;
        qOsserv(:,i)=GradientDescent(AccF(:,i),MagnF(:,i),qOsserv(:,i-1),mu(1,i));
        qOsserv(:,i)=qOsserv(:,i)/norm(qOsserv(:,i));

        qFilt(:,i)=qGyroFilt(:,i)*0.98+qOsserv(:,i)*0.02;
        qFilt(:,i)=qFilt(:,i)/norm(qFilt(:,i));

    
    end
    Angles(:,i)=GetAnglesFromQuaternion(qFilt(:,i));
    i=i+1;
    
end
%figure;
%    subplot(3,1,1);plot(t,Acc(1,:),'b',t,AccF(1,:),'r',t,Magn(1,:),'g',t,MagnF(1,:),'c');legend('AccX','AccFX','MagnX','MagnFX');grid;
%    subplot(3,1,2);plot(t,Acc(2,:),'b',t,AccF(2,:),'r',t,Magn(2,:),'g',t,MagnF(2,:),'c');legend('AcY','AccFY','MagnY','MagnFY');grid;
%    subplot(3,1,3);plot(t,Acc(3,:),'b',t,AccF(3,:),'r',t,Magn(3,:),'g',t,M
%    agnF(3,:),'c');legend('AccZ','AccFZ','MagnZ','MagnFZ');grid;

figure;
    subplot(4,1,1);plot(t,qGyroFilt(1,1:acqSize));hold on;plot(t,qOsserv(1,1:acqSize),'r',t,qFilt(1,:),'g');grid;legend('q0 GyroFilt','q0 Observed','q0 Filt');xlabel('time (sec)');ylabel('Quaternion value');
    subplot(4,1,2);plot(t,qGyroFilt(2,1:acqSize));hold on;plot(t,qOsserv(2,1:acqSize),'r',t,qFilt(2,:),'g');grid;legend('q1 GyroFilt','q1 Observed','q1 Filt');xlabel('time (sec)');ylabel('Quaternion value');
    subplot(4,1,3);plot(t,qGyroFilt(3,1:acqSize));hold on;plot(t,qOsserv(3,1:acqSize),'r',t,qFilt(3,:),'g');grid;legend('q2 GyroFilt','q2 Observed','q2 Filt');xlabel('time (sec)');ylabel('Quaternion value');
    subplot(4,1,4);plot(t,qGyroFilt(4,1:acqSize));hold on;plot(t,qOsserv(4,1:acqSize),'r',t,qFilt(4,:),'g');grid;legend('q3 GyroFilt','q3 Observed','q3 Filt');xlabel('time (sec)');ylabel('Quaternion value');    
    
figure;
    subplot(3,1,1);plot(t,Angles(1,1:acqSize));grid;legend('Roll');xlabel('time (sec)');ylabel('Angle (deg)');
    subplot(3,1,2);plot(t,Angles(2,1:acqSize));grid;legend('Pitch');xlabel('time (sec)');ylabel('Angle (deg)');
    subplot(3,1,3);plot(t,Angles(3,1:acqSize));grid;legend('Yaw');xlabel('time (sec)');ylabel('Angle (deg)');
    


INEMO_Disconnection(handle_dev);
