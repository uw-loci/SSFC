function SSFC_tiled_saver(img_cube, fpath, bit_depth)
%% SSFC Tiled Cube Saver
%   By: Niklas Gahm
%   2020/02/06
%
%   This script saves the raw tiled SSFC images cube 
%
%
%   2020/02/06 - Started
%   2020/02/06 - Finished 



%% Setup Navigation
hpath = pwd;


%% Save Images
spath = [fpath '\Tiled Image Stack'];
mkdir(spath);
bfsave(img_bit_depth_converter(img_cube, bit_depth), ...
    [spath '\Image Cube.ome.tif' ]);


%% Clean Navigation
cd(hpath);
end