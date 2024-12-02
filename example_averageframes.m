%% Example averaging spectra from multiple frames
% D Pearce - 2024-11-27
%% Example script for extracting multiple frames and averaging in a .lo video file
%
% Prerequisites: MATLAB, MATLAB image processing toolbox,
%                read_lo_frame.m
%                "mylofile.lo" - your .lo file captured with a Living Optics Development Kit

%% loop over frames
totalframes = 10;
filename = "mylofile.lo";

[scene, spectra, sampling_coordinates, metadata] = read_lo_frame(filename,1);
avescene = zeros(size(scene));
allspectra = []; allsampling_coordinates = [];
for i=1:totalframes
    % load in .lo file
    [scene, spectra, sampling_coordinates, metadata] = read_lo_frame(filename,i);
    allspectra = [allspectra;spectra];
    allsampling_coordinates = [allsampling_coordinates;sampling_coordinates];
    avescene = avescene + double(scene)/totalframes;
end

%% add one to sample coordinates for matlab indexing
allsampling_coordinates = allsampling_coordinates + 1;

%% display scene view
avescene = double(avescene);
avescene = avescene*255.0/max(avescene(:));
avescene = uint8(round(avescene));
avescene = demosaic(avescene,'rggb');
fgr = figure; imshow(avescene,[]);

%% define coordinates of bounding box using scene view image coords
% [y,x] image coordinates (opposite to the MATLAB tooltip order)
topLeftBoxCoord = [519,892];
bottomRightBoxCoord = [753,1136];

%% extract spectra from spectral list based on bounding box and sampling coordinates
indexes = intersect(find(all(round(allsampling_coordinates)<=bottomRightBoxCoord,2)),find(all(round(allsampling_coordinates)>=topLeftBoxCoord,2)));
roispectra = allspectra(indexes,:);

%% plot mean spectra and 95pc interval for the ROI
totalpoints = size(indexes,1);
upper = round(0.95*totalpoints);
lower = round(0.05*totalpoints);
sortedroispectra = sort(roispectra,1,"ascend");
fgr = figure; p1=plot(metadata.wavelengths,mean(roispectra,1),'k-');
hold on;
p2=plot(metadata.wavelengths,sortedroispectra(upper,:),'k-.');
plot(metadata.wavelengths,sortedroispectra(lower,:),'k-.');
p3=plot(metadata.wavelengths,mean(roispectra,1)+(2*std(roispectra,1,1)),'r-.');
plot(metadata.wavelengths,mean(roispectra,1)-(2*std(roispectra,1,1)),'r-.');
hold off;
xlabel('\lambda [nm]');
ylabel('radiance [W sr^{-1} m^{-2} nm^{-1}]');
title(['spectral radiance for ROI after averaging ',num2str(totalframes),' frames']);
legend([p1,p2,p3],'mean radiance','95% interval','+/-2\sigma');

%NOTE radiance data are only valid when collected with the same camera and objective lens settings as used during calibration.
%This is typically f/4 30mm focal length with 400ms exposure and 0dB gain.