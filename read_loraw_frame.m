%% [sceneview, encodedview, scenemetadata, encodedmetadata] = read_loraw_frame(filename, [framenumber])
%  D Pearce - 2024-11-15
%
%% LORAWFMT file reader for *.loraw files
%
% inputs:  filename   - (char*) String of the full filename and path to the
%                       .lo file.
%        [framenumber]- (int) Frame number to seach to in multiframe video files
%                       [optional] default value: 1.
%
% returns: sceneview   - scene view image in raw format stored in the file,
%                        image in the format of [h,w] (raw).
%          encodedview - encoded view image in raw format stored in the file,
%                        image in the format of [h,w] (raw).
%          scenemetadata   - (struct) metadata associated with the .loraw file.
%          encodedmetadata - (struct) metadata associated with the .loraw file.
%
% example usage:
%
%   [sceneview, encodedview, scenemetadata, encodedmetadata] = read_loraw_frame("C:\\data\\mylofile.loraw",1);
%   sceneview = cast(demosaic(sceneview,'rggb'),'single')/4096.0;
%   
%   figure('Name','encoded'); title('encoded frame');
%   imshow(encodedview,[]);
%   figure('Name','scene'); title('scene frame');
%   sceneview = uint8(255*sceneview ./ max(sceneview(:)));
%   imshow(sceneview,[]);
%
%
%
%
% (C) Living Optics Limited 2023-2024
% All Rights Reserved
%
% This confidential software and the copyright therein are the property of Living Optics Limited and may not be used, copied or disclosed to any third party without the express written permission of Living Optics Limited.
%
% For more information see [Licence](docs/docs/sdk/LICENCE.md).
%
function [sceneview, encodedview, scenemetadata, encodedmetadata] = read_loraw_frame(filename, framenumber)
  sceneview = 0;
  encodedview = 0;
  scenemetadata = 0;
  encodedmetadata = 0;

  totalframepairsize = 2*(9961472 + 216 + 15);

  if nargin<2
    framenumber = 1;
  end

  %% open file and read data
  try
    fid = fopen(filename,'r');
  catch
    disp(['unable to open file: ', filename]);
  end

  try
    %seek to required frame
    fseek(fid,(framenumber-1)*(totalframepairsize),"bof");
  catch
    disp(['unable to seek to frame number: ', filename]);
  end

  %% extract data from file
  try
    arch = "ieee-le"; %le=native for intel arch and Nvidia AGX Orin
    % read encoded frame
    magicPrefix = fread(fid,6,'uint8=>uint8',0,arch)';
    v1 = fread(fid,1,'uint8',0,arch);
    v2 = fread(fid,1,'uint8',0,arch);
    numsensors = fread(fid,1,'uint8',0,arch);
    metadatasize = fread(fid,1,'uint16',0,arch);
    framesize = fread(fid,1,'uint32',0,arch)';
    encodedmetadata = fread(fid,metadatasize,'uint8=>uint8',0,arch)';
    encodedframe = fread(fid,framesize/2,'uint16=>uint16',0,arch);


    % read scene frame
    magicPrefix = fread(fid,6,'uint8=>uint8',0,arch)';
    v1 = fread(fid,1,'uint8',0,arch);
    v2 = fread(fid,1,'uint8',0,arch);
    numsensors = fread(fid,1,'uint8',0,arch);
    metadatasize = fread(fid,1,'uint16',0,arch);
    framesize = fread(fid,1,'uint32',0,arch)';
    scenemetadata = fread(fid,metadatasize,'uint8=>uint8',0,arch)';
    sceneframe = fread(fid,framesize/2,'uint16=>uint16',0,arch);


    %% close file
    fclose(fid);

  catch
    disp(['error reading data from file: ', filename]);
    fclose(fid);
  end


  %% Decode metadata
  try
    encodedmetadata = decode_metadata(encodedmetadata);
    encodedview = reshape_raw_frame(encodedframe,encodedmetadata);

    scenemetadata = decode_metadata(scenemetadata);
    sceneview = reshape_raw_frame(sceneframe,scenemetadata);
  catch
    disp(['error decoding data from file: ', filename]);
  end

end

function metadata_struct = decode_metadata(metadata)

  metadata_struct.framerate1 = typecast(uint8(metadata(1:20)),'int32');
  metadata_struct.framerate1 = metadata_struct.framerate1(5);
  metadata_struct.gain1 = typecast(uint8(metadata(21:40)),'int32');
  metadata_struct.gain1 = metadata_struct.gain1(5);
  metadata_struct.exposure1 = typecast(uint8(metadata(41:60)),'int32');
  metadata_struct.exposure1 = metadata_struct.exposure1(5);
  metadata_struct.serialid = typecast(uint8(metadata(61:64)),'int32');
  metadata_struct.computeserialid = typecast(uint8(metadata(65:68)),'int32');
  metadata_struct.loformat = typecast(uint8(metadata(69:84)),'uint8');
  vd = metadata(89:(89+127));
  metadata_struct.fd = typecast(uint8(vd(1:4)),'int32');
  metadata_struct.id = typecast(uint8(vd(5:8)),'int32');
  metadata_struct.sensorid = typecast(uint8(vd(9:12)),'int32');
  metadata_struct.sensormode = typecast(uint8(vd(13:32)),'int32');
  metadata_struct.sensormode = metadata_struct.sensormode(5);
  metadata_struct.framerate = typecast(uint8(vd(33:52)),'int32');
  metadata_struct.framerate = metadata_struct.framerate(5);
  metadata_struct.exposure = typecast(uint8(vd(53:72)),'int32');
  metadata_struct.exposure = metadata_struct.exposure(5);
  metadata_struct.gain = typecast(uint8(vd(73:92)),'int32');
  metadata_struct.gain = metadata_struct.gain(5);
  metadata_struct.temperature = typecast(uint8(vd(93:96)),'single');
  metadata_struct.fmtwidth = typecast(uint8(vd(97:112)),'int32');
  metadata_struct.fmtwidth = metadata_struct.fmtwidth(1);
  metadata_struct.fmtheight = typecast(uint8(vd(97:112)),'int32');
  metadata_struct.fmtheight = metadata_struct.fmtheight(2);
  metadata_struct.fmtfmt = typecast(uint8(vd(97:112)),'int32');
  metadata_struct.fmtfmt = metadata_struct.fmtfmt(3);
  metadata_struct.fmtblklevel = typecast(uint8(vd(97:112)),'int32');
  metadata_struct.fmtblklevel = metadata_struct.fmtblklevel(4);
  metadata_struct.frametimes = typecast(uint8(vd(113:(113+15))),'int64');
  metadata_struct.frametimes = metadata_struct.frametimes(1);
  metadata_struct.frametimeus = typecast(uint8(vd(113:(113+15))),'int64');
  metadata_struct.frametimeus = metadata_struct.frametimeus(2);
end

function frame = reshape_raw_frame(raw_frame,metadata_struct)

  frame = reshape(bitshift(raw_frame,-4),[metadata_struct.fmtwidth,metadata_struct.fmtheight])';
  frame = frame-cast(metadata_struct.fmtblklevel,'uint16');
end





