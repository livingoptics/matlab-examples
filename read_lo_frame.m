%% [scene, spectra, sampling_coordinates, metadata] = read_lo_frame(filename, [framenumber])
%  D Pearce - 2024-11-27
%
%% LOFMT file reader for *.lo files
%
% inputs:  filename   - (char*) String of the full filename and path to the
%                       .lo file.
%        [framenumber]- (int) Frame number to seach to in multiframe video files
%                       [optional] default value: 1.
%
% returns: scene      - scene view image in the same format stored in the file,
%                       image in the format of [h,w,c] (debayered) or
%                       [h,w] (raw).
%          spectra    - (single n x b array) spectral radiance from .lo file,
%                       in the format [n,b], typically (n=4384) spectra with
%                       (b=96) bands each.
%          sampling_coordinates - (single n x 2 array) sampling coordinates
%                       from the scene for each of n spectra. coordinates 
%                       are given as [y,x] position in scene image.
%          metadata   - (struct) metadata associated with the .lo file.
%
% example usage:
%
%   [sceneview, spectra, coords, metadata] = read_lo_frame("C:\\data\\mylofile.lo");
%   figure('Name','scene'); title('scene frame');
%   imshow(sceneview,[]);
%   figure('Name','spectra'); title('mean spectra');
%   plot(metadata.wavelengths,mean(spectra,'omitnan'));
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
function [scene, spectra, sampling_coordinates, metadata] = read_lo_frame(filename,framenumber)

  scene = 0;
  spectra = 0;
  sampling_coordinates = 0;
  metadata = 0;

  if nargin<2
    framenumber = 1;
  end

  %% open file and read data
  try
    fid = fopen(filename,'r');
  catch
    disp(['unable to open file: ', filename]);
    rethrow(lasterror);
  end

  %% extract data from file
  arch = "ieee-le"; %le=native for intel arch and Nvidia AGX Orin
  try
    % read head data of first frame (assume all frames are the same size)
    magicPrefix = fread(fid,15,'char=>char',0,arch)';
    v1 = fread(fid,1,'uint8',0,arch);
    v2 = fread(fid,1,'uint8',0,arch);
    metadatasize = fread(fid,1,'uint16',0,arch);
    framesize = fread(fid,1,'uint32',0,arch)';

    %seek to required frame
    fseek(fid,(framenumber-1)*(framesize+metadatasize+23),"bof");

    % re-read head data for current frame
    magicPrefix = fread(fid,15,'char=>char',0,arch)';
    v1 = fread(fid,1,'uint8',0,arch);
    v2 = fread(fid,1,'uint8',0,arch);
    metadatasize = fread(fid,1,'uint16',0,arch);
    framesize = fread(fid,1,'uint32',0,arch)';

    metadata = fread(fid,metadatasize,'uint8=>uint8',0,arch)';

    % decode metadata
    md = decode_metadata(metadata);

    % check for frame size vs number of pixels and spectra
    if strncmp(md.scene_dtype,"uint16",6)
      scenedtype = 'uint16=>uint16';
      scenedtypesize = 2;
    elseif strncmp(md.scene_dtype,"uint8",5)
      scenedtype = 'uint8=>uint8';
      scenedtypesize = 1;
    else
      error('no valid type found for scene data - unable to read image');
    end

    % check for frame size vs number of pixels and spectra
    if strncmp(md.spectra_dtype,"float64",7)
      spectradtype = 'double=>double';
      spectradtypesize = 8;
    elseif strncmp(md.spectra_dtype,"float32",7)
      spectradtype = 'single=>single';
      spectradtypesize = 4;
    else
      error('no valid type found for scene data - unable to read image');
    end

    if framesize<((md.scene_channels*md.scene_width*md.scene_height*scenedtypesize)+(md.nspectra*md.nchannels*spectradtypesize))
      error('metadata and framesize missmatch');
    end

    % read scene view
    scene = fread(fid,md.scene_channels*md.scene_width*md.scene_height,scenedtype,0,arch);
    scene = reshape_scene_frame(scene,md);

    % read spectra
    spectra = fread(fid,md.nspectra*md.nchannels,spectradtype,0,arch);
    spectra = reshape(spectra,[md.nchannels,md.nspectra])';

    %% close file
    fclose(fid);

    %update variable names for consistancy
    metadata = md;
    sampling_coordinates = metadata.sampling_coordinates;

  catch
    disp(['error reading data from file: ', filename]);
    fclose(fid);
    rethrow(lasterror);
  end


end

function metadata_struct = decode_metadata(metadata)

  metadata_struct.nspectra = typecast(uint8(metadata(1:4)),'int32');
  metadata_struct.nchannels = typecast(uint8(metadata(5:8)),'int32');
  metadata_struct.scene_height = typecast(uint8(metadata(9:12)),'int32');
  metadata_struct.scene_width = typecast(uint8(metadata(13:16)),'int32');
  metadata_struct.scene_channels = typecast(uint8(metadata(17:20)),'int32');
  metadata_struct.timestamp_s = typecast(uint8(metadata(21:24)),'int32');
  metadata_struct.timestamp_us = typecast(uint8(metadata(25:28)),'int32');
  metadata_struct.frame_rate = typecast(uint8(metadata(29:32)),'int32');
  metadata_struct.exposure = typecast(uint8(metadata(33:36)),'int32');
  metadata_struct.gain = typecast(uint8(metadata(37:40)),'int32');
  metadata_struct.scene_exposure = typecast(uint8(metadata(41:44)),'int32');
  metadata_struct.scene_gain = typecast(uint8(metadata(45:48)),'int32');
  metadata_struct.camera_serial_id = typecast(uint8(metadata(49:52)),'int32');
  metadata_struct.edge_compute_serial_id = typecast(uint8(metadata(53:56)),'int32');
  metadata_struct.spectra_dtype = cast(uint8(metadata(57:66)),'char');
  metadata_struct.scene_dtype = cast(uint8(metadata(67:76)),'char');
  metadata_struct.sdk_version = cast(uint8(metadata(77:91)),'char');
  metadata_struct.calibration = cast(uint8(metadata(92:141)),'char');


  metadata_struct.wavelengths = typecast(uint8(metadata(142:(141+(metadata_struct.nchannels*4)))),'single');

  p = (141+(metadata_struct.nchannels*4))+1;
  metadata_struct.sampling_coordinates = typecast(uint8(metadata(p:(p-1+(metadata_struct.nspectra*4*2)))),'single');
  metadata_struct.sampling_coordinates = reshape(metadata_struct.sampling_coordinates,[2,metadata_struct.nspectra])';

  p = (p+(metadata_struct.nspectra*2))+1;
  metadata_struct.description = cast(uint8(metadata(p:end)),'char');

end

function frame = reshape_scene_frame(scene_frame,metadata_struct)

  %scene_frame = bitshift(scene_frame,-4)
  %scene_frame = scene_frame-cast(metadata_struct.fmtblklevel,'uint16');
  frame = reshape(scene_frame,[metadata_struct.scene_width,metadata_struct.scene_height,metadata_struct.scene_channels])';
end


%testing
function test()
  filename = './20241023-052635-696953.lo';

  [scene, spectra, sampling_coordinates, metadata] = read_lo_frame(filename,1);

  figure('Name','scene'); title('scene frame');
  imshow(scene,[]);

  figure('Name','spectra'); title('mean spectra');
  plot(metadata.wavelengths,mean(spectra,'omitnan'));

  figure('Name','spectra'); title('30 random spectra');
  i = randperm(metadata.nspectra);
  i = i(1:30);
  plot(metadata.wavelengths,spectra(i,:));
 end
