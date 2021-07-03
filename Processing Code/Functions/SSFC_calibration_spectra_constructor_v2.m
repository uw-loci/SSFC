function [ calibration_space, prism_angle, band_map, wavelength_range ] ...
    = SSFC_calibration_spectra_constructor_v2( ...
    wavelength_range, calibration_folder, ...
    automated_line_detection_flag, num_bands )
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




%% Setup Input Handling
if nargin == 2
    automated_line_detection_flag = 1;
    num_bands = 0;
end



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

if automated_line_detection_flag == 1
    % Go through and determine the number of lines in each row
    img_dim_1_lines = ...
        zeros(1,size(calibration_set(strongest_line).image, 1));
    % avg_dist_btw_lines = num_line;
    for i = 1:numel(img_dim_1_lines)
        [peaks,loc] = findpeaks( smooth( ...
            calibration_set(strongest_line).image(i,:)));
        loc = loc(find(peaks >= (max(peaks)/3)));
        img_dim_1_lines(i) = numel(loc);
    end
    
    % The number of actual lines is the mode of how many lines were found 
    % in each row.
    num_bands = mode(img_dim_1_lines);
end



%% Determine True Distance Between Bands
% Initialize Search
img_dim_1 = size(calibration_set(strongest_line).image, 1);
avg_dist_btw_bands = zeros(1,img_dim_1);
avg_starting_offset = zeros(1,img_dim_1);

% Go through and determine the number of lines in each row
for i = 1:img_dim_1
    
    % Generate the Reference Line
    [peaks,loc_ref] = findpeaks( smooth( ...
        calibration_set(strongest_line).image(i,:)));
    [~, ind] = maxk( peaks, num_bands);
    loc_ref_line = loc_ref(sort(ind));
    starting_peak_val = peaks(ind(1));
    
    % Calculate the Between Band Distance
    avg_dist_btw_bands(i) = mean(loc_ref_line(2:end)-loc_ref_line(1:end-1));
    
    % Use the first peak location to estimate avg starting offset
    avg_starting_offset(i) = loc_ref_line(1);
end

% Get the average distance between band peaks.
avg_dist_btw_bands = mean(avg_dist_btw_bands);

% Clean the Avg Starting Offset Vector by removing outliers
avg_starting_offset(avg_starting_offset < ...
    (mean(avg_starting_offset) * 0.75)) = [];
avg_starting_offset(avg_starting_offset > ...
    (mean(avg_starting_offset) * 1.25)) = [];

% Get the average starting offset 
avg_starting_offset = mean(avg_starting_offset);



%% Determine True Distance Between Wavelength Lines 
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
p_coeffs_wavelengths = polyfit(wavelengths, offsets, 1);
p_coeffs_offsets = polyfit(offsets, wavelengths, 1);
if max(wavelength_range) < max(wavelengths)
    [~, max_ind] = max(wavelength_range);
    wavelength_range = wavelength_range([1:(max_ind-1), (max_ind+1):end]);
end
offset_range = polyval(p_coeffs_wavelengths, wavelength_range);

if numel(offset_range) == 2
    
    % Check that the range isn't too large
    if abs(offset_range(2)-offset_range(1)) > avg_dist_btw_bands
        warning(['Input Theoretical Wavelength Range is larger than the' ...
            ' actual range.']);
        
        % Adjust Offset Range
        overhang = ceil((abs(offset_range(2)-offset_range(1)) - ...
            avg_dist_btw_bands)/2);
        offset_range(offset_range == min(offset_range)) = ...
            min(offset_range) + overhang;
        offset_range(offset_range == max(offset_range)) = ...
            max(offset_range) - overhang;
        
        % Adjust Wavelength Range
        wavelength_range = polyval(p_coeffs_offsets, offset_range, 1);
        
        fprintf(['\n\nNew Wavelength Range: ' num2str(wavelength_range(1)) ...
            'nm to ' num2str(wavelength_range(2)) 'nm\n\n']);
    end
end



%% Generate Spectral Band
% Add the wavelength range to the wavelengths
[wavelengths, ind_wavelengths] = sort([wavelengths, wavelength_range], ...
    'ascend');

% Adjust the offsets such that the lowest wavelength sits at pixel 1 of the
% band and encompasses the whole wavelength range 
offsets = [offsets, offset_range];
offsets = offsets(ind_wavelengths);

offset_shift = min(offsets);
offsets = offsets - offset_shift;

% Adjust the average starting offset to reflect the start of the range
% avg_starting_offset = avg_starting_offset + offset_shift;
avg_starting_offset = avg_starting_offset + offset_shift - 3;
% avg_starting_offset = avg_starting_offset + ;

% Generate Positional Offsets
positional_offsets = SSFC_calibration_positional_offset_generator( ...
    loc_ref, avg_dist_btw_bands, avg_starting_offset, calibration_set, ...
    offsets, strongest_line);

% Generate Band Map Spacing
band_map = zeros(1, numel(positional_offsets));
counter = 0;
for i = 2:numel(positional_offsets)
    if positional_offsets(i) ~= (avg_dist_btw_bands^2)
        if (positional_offsets(i) < positional_offsets(i-1))
            counter = counter + 1;
        end
        band_map(i) = counter;
    end
end

% Polyfit to get 
p_coeffs_spectral = polyfit(offsets, wavelengths, 1);
spectral_band = polyval(p_coeffs_spectral, positional_offsets);
dummy_val = mode(spectral_band);
spectral_band(spectral_band == dummy_val) = 0;



%% Generate Calibration Space for the rotated sub-image approach
calibration_space = repmat(spectral_band, ...
    [size(calibration_set(1).image_rot,2), 1]);
band_map = repmat(band_map, [size(calibration_set(1).image_rot,2), 1]);



%% Build the Output Wavelength Range
wavelength_range = [min(wavelengths), max(wavelengths)];
end