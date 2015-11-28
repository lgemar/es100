classdef Kinect
   properties
      % Basic properties of the connection with the Kinect
      colorVid
      depthVid
   end
   methods
      function K = Kinect()
        colorVid = videoinput('kinect',1); 
        depthVid = videoinput('kinect',2);
      end

      function aquire(K, NUM_FRAMES)
        colorVid.FramesPerTrigger = NUM_FRAMES;
        depthVid.FramesPerTrigger = NUM_FRAMES;
        triggerconfig([colorVid depthVid],'manual');
        start([colorVid depthVid]);
      end

      function [rgb_frames, depth_frames] = getFrames(K, NUM_FRAMES)
        while(colorVid.FramesAcquired ~= NUM_FRAMES || depthVid.FramesAcquired ~= NUM_FRAMES)
            pause(.1); 
        end
        [rgb_frames, ts1, rgb_metaData] = getdata(colorVid, NUM_FRAMES);
        [depth_frames, ts2, depth_metaData] = getdata(depthVid, NUM_FRAMES);
      end

      function stopAcquisition(K)
        stop([colorVid depthVid]);
      end
   end
end
