function [spectral_boundary] = spectral_boundary_finder(...
    img_sets, calibration_map, spectral_finding_granularity)
%% SSFC Data Cube Constructor
%   By: Niklas Gahm
%   2020/04/23
%
%   This script builds an intensity count vector with corresponding
%   wavelengths and finds optimal boundaries between wavelengths for
%   seperation.
%
%
%   2020/04/23 - Started
%   2020/04/28 - Finished




%% Build Superposition Intensity Vector
intensities = 0*img_sets(1).images_straightened(1);
sub_img_waitbar = waitbar((1/numel(img_sets)), ...
    'Generating Intensity Vector.');
for i = 1:numel(img_sets)
    waitbar((i/numel(img_sets)), sub_img_waitbar);
    for j = 1:numel(img_sets(i).images_straightened)
        intensities = intesnsities + img_sets(i).images_straightened(j);
    end
end
close(sub_img_waitbar);


%% Build Wavelength Counts
% Convert matrices into a vector.
intensities = intensities(:);
wavelengths = calibration_map(:);
[wavelengths, sorted_ind] = sort(wavelengths, 'ascending');
intensities = intensities(sorted_ind);


%% Compress Vectors by Granularity 
wavelengths = fix(wavelengths * (10^spectral_finding_granularity)) / ...
    (10^spectral_finding_granularity);

wavelengths_comp = wavelengths * 0;
wavelengths_comp(1) = wavelengths(1);
intensities_comp = intensities * 0;
intensities_comp(1) = intensities(1);
current_ind = 1;

for i = 2:numel(wavelengths)
    if wavelengths(i) == wavelengths(i-1)
        % Case where sorted neighbors are the same bin
        intensities_comp(current_ind) = intensities_comp(current_ind) + ...
            intensities(i);
    else
        current_ind = current_ind + 1;
        wavelengths_comp(current_ind) = wavelengths(i);
        intensities_comp(current_ind) = intensities(i);
    end
end

wavelengths_comp = wavelengths_comp(1:current_ind);
intensities_comp = intensities_comp(1:current_ind);


%% Determine Boundaries
intensities_smooth = smooth(intensities_comp);
min_intensities = islocalmin(intensities_smooth);
min_intensities_loc = find(min_intensities);
[peak_intensities, peak_locs] = findpeaks(intensities_smooth); 

% Clean peaks data, only use peaks over 25% of maximum intensity
max_intensity = max(intensities_smooth);
peak_logical = peak_intensities * 0;
for i = 1:numel(peak_logical)
    if peak_intensities(i) >= (max_intensity/4)
        peak_logical(i) = 1;
    end
end
peak_locs = peak_locs(find(peak_logical));

% Clean min data, since there can only be one minimum between peaks
min_logical = (min_intensities_loc * 0) + 1;
for i = 1:numel(min_intensities_loc)
    if min_intensities_loc(i) < peak_locs(1)
        % Minimum before an actual peak, remove since spectral bin will be
        % from the minimum wavelength in the system to the first actual
        % minimum in the data set.
        min_logical(i) = 0;
        
    elseif min_intensities_loc(i) > peak_locs(end)
        % Minimum after the last peak, remove since spectral bin will be
        % from previous minimum to maximum wavelength in the system.
        min_logical(i) = 0;
        
    else
        % Case guaranteed to be between two peaks need tomakesure it is the
        % only minima between thes two peaks, and if it isn't, selecting
        % the optimal minima.
        % Find stradling peaks
        straddling_peaks = [0,0];
        for j = 2:numel(peak_locs)
            if (min_intensities_loc(i) > peak_locs(j-1)) && ...
                    (min_intensities_loc(i) < peak_locs(j))
                straddling_peaks = [peak_locs(j-1), peak_locs(j)];
                break;
            end
        end
        
        % Determine how many minima are between straddling peaks
        neighbor_logical = min_logical * 0;
        for j = 1:numel(min_logical)
            if (min_intensities_loc(j) > straddling_peaks(1)) && ...
                    (min_intensities_loc(j) < straddling_peaks(2))
                neighbor_logical(j) = 1; 
            end
        end
        
        % Select best minima if necessary
        if sum(neighbor_logical) ~= 1
            neighbor_minima = min_intensities_loc(find(neighbor_logical));
            [~, min_loc] = min(intensities_smooth(neighbor_minima));
            min_logical(find(neighbor_logical)) = 0;
            min_logical(min_loc) = 1;
        end
    end
end
min_intensities_loc = min_intensities_loc(find(min_logical));

% Generate Spectral Boundary Vector from the minimums
spectral_boundary = wavelengths_comp(min_intensities_loc);


%% Print Spectral Bounds to Console
fprintf(['\nSpectral boundaries are set at: ' ...
    num2str(spectral_boundary) '\n']);
end