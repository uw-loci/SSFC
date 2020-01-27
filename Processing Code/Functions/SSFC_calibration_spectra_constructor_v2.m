function [ calibration_space, prism_angle, band_map, wavelength_range ] ...
    = SSFC_calibration_spectra_constructor_v2( ...
    wavelength_range, calibration_folder )
%% SSFC Calibration Spectra Constructor
%   By: Niklas Gahm
%   2019/05/17
%
%   This script reads in calibration files (wavelengths) and generates a 
%   pixel by pixel association to the spectrum with them. This is specific
%   to the SSFC methodology.
%
%
%   2019/05/17 - Started
%   2019/05/19 - Finished




%% Navigate to Folder and Determine How Many Files to Read
hpath = pwd;
cd(calibration_folder); % Move to Folder
file_list = dir;
file_list = file_list(3:end);   % Remove System Navigation Entries
num_ref = numel(file_list); % Number of calibration files (wavelengths)



%% Read in the Calibration Files
calibration_set = struct;
for i = 1:num_ref
    % Get the associated wavelength assuming each file is ___nm.ome.tiff
    [~, wavelength, ~] = fileparts(file_list(i).name);
    calibration_set(i).wavelength = str2double(wavelength(1:(end-6)));
    
    % Read in file
    bf_reader_element = bfopen(file_list(i).name);
    calibration_set(i).image = double(bf_reader_element{1,1}{1,1});
end



%% Clean Up Navigation
cd(hpath);



%% Hough Transform Line Angle Deterimination 
% Initialize Angle List
line_angles = zeros(1,num_ref);
img_intensities = line_angles;
for i = 1:num_ref
    % Generate a temporary Binary Image (BW)
    BW = edge(calibration_set(i).image, 'canny');
    
    % Get the Hough Transform (H)
    [H, theta, ~] = hough(BW,'RhoResolution',0.5,'Theta',-10:0.01:30);
    
    % Find the Location of the Maximum of the Transform
    [~, theta_loc] = find(H == max(max(H))); 
    
    % Determine the Line Angle
    if numel(theta_loc) == 1
        line_angles(i) = theta(theta_loc);
        calibration_set(i).angle = theta(theta_loc);
    else
        temp_angles = zeros(1, numel(theta_loc));
        for j = 1:numel(theta_loc)
            temp_angles(j) = theta(theta_loc(j));
        end
        temp_angle = mean(temp_angles);
        line_angles(i) = temp_angle;
        calibration_set(i).angle = temp_angle;
    end
    
    % Determine the Total Image Intensity
    img_intensities(i) = sum(sum(calibration_set(i).image));
end

% Determine the Image Weights
img_weights = img_intensities ./ sum(img_intensities);

% Get the Weighted Average of the Angles
prism_angle = sum(line_angles .* img_weights);



%% Generating Rotated Images
for i = 1:num_ref
    % Rotate Images 
    calibration_set(i).image_rot = imrotate(calibration_set(i).image, ...
        prism_angle, 'bilinear', 'crop');
end



%% Determining the Number of Lines in the Calibration Images
% Determine the strongest line to use for this step
[~, strongest_line] = max(img_intensities);

% Go through and determine the number of lines in each row
num_line = zeros(1,size(calibration_set(strongest_line).image, 1));
% avg_dist_btw_lines = num_line;
for i = 1:numel(num_line)
    [peaks,loc] = findpeaks( smooth( ...
        calibration_set(strongest_line).image(i,:)));
    loc = loc(find(peaks >= (max(peaks)/2)));
    num_line(i) = numel(loc);
end

% The number of actual lines is the mode of how many lines were found in
% each row.
num_bands = mode(num_line); 



%% Determine True Distance Between Bands
% Initialize Search
num_line = size(calibration_set(strongest_line).image, 1);
avg_dist_btw_bands = zeros(1,num_line);
avg_starting_offset = zeros(1,num_line);

% Go through and determine the number of lines in each row
for i = 1:num_line
    
    % Generate the Reference Line
    [peaks,loc_ref] = findpeaks( smooth( ...
        calibration_set(strongest_line).image(i,:)));
    [~, ind] = maxk( peaks, num_bands);
    loc_ref = loc_ref(sort(ind));
    
    % Calculate the Between Band Distance
    avg_dist_btw_bands(i) = mean(loc_ref(2:end)-loc_ref(1:end-1));
    
    % Store the first peak location
    avg_starting_offset(i) = loc_ref(1);
end

% Get the average distance between band peaks.
avg_dist_btw_bands = mean(avg_dist_btw_bands);

% Get the average starting offset 
avg_starting_offset = mean(avg_starting_offset);



%% Determine True Distance Between Lines 
% Remove the Strongest Line from the Search since it is Reference
search_ind = 1:1:num_ref;
search_ind(strongest_line) = [];

% Initialize the Offset Cell
calibration_set(strongest_line).offset = 0;

% Sum Images vertically, find peaks, and determine relative offset 
ref_line_summed = sum(calibration_set(strongest_line).image_rot, 1);
[peaks,loc_ref] = findpeaks( smooth(ref_line_summed) );
[~, ind] = maxk( peaks, num_bands);
loc_ref = loc_ref(sort(ind));
for i = 1:numel(search_ind)
    comparison_line = sum(calibration_set(search_ind(i)).image_rot, 1);
    
    [peaks, loc_comparison] = findpeaks( smooth(comparison_line) );
    [~, ind] = maxk( peaks, num_bands);
    loc_comparison = loc_comparison(sort(ind));
    
    % Calculate the Between Band Distance
    calibration_set(search_ind(i)).offset = mean(loc_ref-loc_comparison);
end



%% Generate a Linear Spectral Fit Based on Between Line Distances 
% Get the range of offsets based on theoretical wavelength range
wavelengths = extractfield(calibration_set, 'wavelength');
offsets = extractfield(calibration_set, 'offset'); 
p_coeffs = polyfit(wavelengths, offsets, 1);
offset_range = polyval(p_coeffs, wavelength_range);

% Check direction wavelength offsets are going
if offset_range(2) < offset_range(1)
    % Decreasing direction needs adjustement for interpolation
    wavelengths = flip(wavelengths);
    wavelength_range = flip(wavelength_range);
    offsets = flip(offsets) - offsets(end);
    offset_range = flip(offset_range) - offset_range(2);
end

% Check that the range isn't too large
if abs(offset_range(2)-offset_range(1)) > avg_dist_btw_bands
    warning(['Input Theoretical Wavelength Range is larger than the' ...
        ' actual range.']); 
    
    offset_range_old = offset_range;
    
    % Adjust Offset Range
    overhang = ceil((abs(offset_range(2)-offset_range(1)) - ...
        avg_dist_btw_bands)/2);
    offset_range(1) = offset_range(1) + overhang;
    offset_range(2) = offset_range(2) - overhang;
    
    % Adjust Wavelength Range
    wavelength_range = interp1(offset_range_old, wavelength_range, ...
        offset_range, 'linear', 0);
    
    fprintf(['\n\nNew Wavelength Range: ' num2str(wavelength_range(1)) ...
        'nm to ' num2str(wavelength_range(2)) 'nm\n\n']);
end



%% Generate Spectral Band
% Add the wavelength range to the wavelengths
wavelengths = [wavelength_range(1), wavelengths, wavelength_range(2)];

% Adjust the average starting offset to reflect the start of the range
if offset_range(2) < offset_range(1)
    avg_starting_offset = avg_starting_offset - abs(offset_range(2));
else
    avg_starting_offset = avg_starting_offset - abs(offset_range(1));
end

% Adjust the offsets such that the lowest wavelength sits at pixel 1 of the
% band and encompasses the whole wavelength range 
offsets = [offset_range(1), offsets, offset_range(2)] - offset_range(1);

% Generate Positional Offsets
positional_offsets = mod( (avg_starting_offset - ...
    fix(avg_starting_offset)):1:ceil(avg_dist_btw_bands * num_bands), ...
    avg_dist_btw_bands);

% Generate Band Map Spacing
band_map = ones(1, numel(positional_offsets));
counter = 1;
for i = 2:numel(positional_offsets)
    if positional_offsets(i) < positional_offsets(i-1)
        counter = counter + 1;
    end
    band_map(i) = counter;
end

% Pad the start to match the dark region of the rotated calibration images
pad_count = fix(avg_starting_offset);
% By padding with a value larger than the acceptable offset range, it will
% be zeroed during interpolation
pad_vector = ones(1,pad_count) * (avg_dist_btw_bands + 10);
spectral_band = [pad_vector, positional_offsets];
band_map = [(pad_vector.*0), band_map];

% Pad the back to match the rotated image size
if numel(spectral_band) < size(calibration_set(1).image_rot,2)
    pad_count = size(calibration_set(1).image_rot,2) ...
        - numel(spectral_band);
    % By padding with a value larger than the acceptable offset range, it
    % will be zeroed during interpolation
    pad_vector = ones(1,pad_count) * (avg_dist_btw_bands + 10);
    spectral_band = [spectral_band, pad_vector];
    band_map = [band_map, (pad_vector .* 0)];
end

% Interpolate to convert to spectral values
spectral_band = interp1(offsets, wavelengths, spectral_band, ...
    'linear', 0);


%% Generate Calibration Space for the rotated sub-image approach
calibration_space = repmat(spectral_band, ...
    [size(calibration_set(1).image_rot,1), 1]);
band_map = repmat(band_map, [size(calibration_set(1).image_rot,1), 1]);


end