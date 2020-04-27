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
wavelengths = fix(wavelengths * (10^spectral_finding_granularity)) / ...
    (10^spectral_finding_granularity);


%% Determine Boundaries


end
