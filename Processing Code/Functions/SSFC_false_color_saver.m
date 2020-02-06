function SSFC_false_color_saver( img_cube_false, img_sets, proc_mode, ...
    fpath, bit_depth)
%% SSFC False Color Saver
%   By: Niklas Gahm
%   2018/12/05
%
%   This script saves false color renderings of the reconstructed or
%   tiled SSFC images. 
%
%
%   2018/12/12 - Started
%   2019/01/24 - Finished 



%% Setup Navigation
hpath = pwd;


%% Save Images
spath = [fpath '\False Colored Stack'];
mkdir(spath);
switch proc_mode
    case 'Individual Images'
        wait_element = waitbar(0, sprintf('Saving Images'));
        for i = 1:numel(img_sets)
            bfsave(img_bit_depth_converter( ...
                img_sets(i).image_false_color, bit_depth), ...
                [spath 'img' num2str(i) '.ome.tif']);
            waitbar((i/numel(img_sets)), wait_element);
        end
        close(wait_element);
        
        
    otherwise
        bfsave(img_bit_depth_converter(img_cube_false, bit_depth), ...
            [spath '\Image Cube.ome.tif' ]);
end


%% Clean Navigation
cd(hpath);
end