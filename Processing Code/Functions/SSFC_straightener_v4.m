function [ img_sets ] = SSFC_straightener_v4( img_sets, prism_angle )
%% SSFC Sub-Image Straightener
%   By: Niklas Gahm
%   2018/11/26
%
%   This script straightens the lines of the sub-images used for
%   reconstruction
%
%
%   2018/09/24 - Started
%   2018/09/24 - Finished Placeholder
%   2019/02/15 - Finished



%% Apply Image Rotational to Each Sub-Image
wait_element = waitbar(0, 'Rotating Sub Images');
for i = 1:numel(img_sets)
    for j = 1:numel(img_sets(i).images)
        waitbar(((j + (i .* numel(img_sets(1).images))) / ...
            (numel(img_sets).* numel(img_sets(1).images))), wait_element);
        img_sets(i).images_straightened{j} = ...
            imrotate(img_sets(i).images{j}, (prism_angle), ...
            'bilinear', 'crop');
    end
end
close(wait_element)


%% Clean Memory Usage
% img_sets.images is not used after this point, but still hogs most of the
% memory so deleting it is advantageous. 
img_sets = rmfield(img_sets, 'images');
end
