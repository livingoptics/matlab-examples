%% Example extracting spectra from ROI
% D Pearce - 2024-11-27
%% Example script for extracting spectra from simple box ROI
%
% Prerequisites: MATLAB, MATLAB image processing toolbox,
%                read_lo_frame.m
%                "mylofile.lo" - your .lo file captured with a Living Optics Development Kit

%% load in .lo file
[scene, spectra, sampling_coordinates, metadata] = read_lo_frame("mylofile.lo",1);

%% add one to sample coordinates for matlab indexing
sampling_coordinates = sampling_coordinates + 1;

%% display scene view
scene = double(scene);
scene = scene*255.0/max(scene(:));
scene = uint8(round(scene));
scene = demosaic(scene,'rggb');
fgr = figure; imshow(scene,[]);

%% define coordinates of bounding box using scene view image coords
% [y,x] image coordinates (opposite to the tooltip)
topLeftBoxCoord = [519,892];
bottomRightBoxCoord = [753,1136];

%% extract spectra from spectral list based on bounding box and sampling coordinates
indexes = intersect(find(all(round(sampling_coordinates)<=bottomRightBoxCoord,2)),find(all(round(sampling_coordinates)>=topLeftBoxCoord,2)));
roispectra = spectra(indexes,:);

%% show positions of sampling points
fgr = figure; imshow(scene,[]);
hold on
for i=1:size(indexes,1)
  plot(sampling_coordinates(indexes(i),2),sampling_coordinates(indexes(i),1), 'r+', 'MarkerSize', 2, 'LineWidth', 2);
end
hold off

%% plot all spectra from ROI
fgr = figure; plot(metadata.wavelengths,roispectra(:,:),'k-');
xlabel('\lambda [nm]');
ylabel('radiance [W sr^{-1} m^{-2} nm^{-1}]');
title('spectral radiance samples');

%% plot mean spectra and +/- 2 std for the ROI
fgr = figure; plot(metadata.wavelengths,mean(roispectra,1),'k-');
hold on;
plot(metadata.wavelengths,mean(roispectra,1)+(2*std(roispectra,1,1)),'k-.');
plot(metadata.wavelengths,mean(roispectra,1)-(2*std(roispectra,1,1)),'k-.');
hold off;
xlabel('\lambda [nm]');
ylabel('radiance [W sr^{-1} m^{-2} nm^{-1}]');
title('spectral radiance for ROI');
legend('mean radiance','+/-2\sigma');

%% plot mean spectra and 95pc interval for the ROI
totalpoints = size(indexes,1);
upper = round(0.95*totalpoints);
lower = round(0.05*totalpoints);
sortedroispectra = sort(roispectra,1,"ascend");
fgr = figure; plot(metadata.wavelengths,mean(roispectra,1),'k-');
hold on;
plot(metadata.wavelengths,sortedroispectra(upper,:),'k-.');
plot(metadata.wavelengths,sortedroispectra(lower,:),'k-.');
hold off;
xlabel('\lambda [nm]');
ylabel('radiance [W sr^{-1} m^{-2} nm^{-1}]');
title('spectral radiance for ROI');
legend('mean radiance','95% interval');


%NOTE radiance data are only valid when collected with the same camera and objective lens settings as used during calibration.
%This is typically f/4 30mm focal length with 400ms exposure and 0dB gain.
