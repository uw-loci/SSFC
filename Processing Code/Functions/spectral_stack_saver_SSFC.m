function [ ] = spectral_stack_saver_SSFC( img_sets, file_path, ...
    img_save_type, bit_depth )
%% SSFC Data Cube Constructor
%   By: Niklas Gahm
%   2018/09/27
%
%   This script saves the individual spectral stacks
%
%
%   2018/09/24 - Started
%   2018/09/27 - Finished



%% Save Z-Stacks
spath = [file_path '\Individual Spectral Stacks'];
mkdir(spath);
for i = 1:numel(img_sets)
    bfsave(img_bit_depth_converter(img_sets(i).images_reconstructed, ...
        bit_depth), [spath '\' num2str(img_sets(i).x_pos) 'x ' ...
        num2str(img_sets(i).y_pos) 'y ' num2str(img_sets(i).z_pos) 'z' ...
        num2str(img_sets(i).t) 't' img_save_type]);
end
end
