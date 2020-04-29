function varargout = SSFC_GUI(varargin)
% SSFC_GUI MATLAB code for SSFC_GUI.fig
%      SSFC_GUI, by itself, creates a new SSFC_GUI or raises the existing
%      singleton*.
%
%      H = SSFC_GUI returns the handle to a new SSFC_GUI or the handle to
%      the existing singleton*.
%
%      SSFC_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SSFC_GUI.M with the given input arguments.
%
%      SSFC_GUI('Property','Value',...) creates a new SSFC_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SSFC_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SSFC_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SSFC_GUI

% Last Modified by GUIDE v2.5 16-Jan-2019 15:22:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SSFC_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @SSFC_GUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before SSFC_GUI is made visible.
function SSFC_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SSFC_GUI (see VARARGIN)

% Choose default command line output for SSFC_GUI
handles.output = hObject;

% Initialize Variables
global path_set_flag 
path_set_flag = 0;
global position_file_flag
position_file_flag = 0;
global calibration_set_flag
calibration_set_flag = 0;
global last_path
last_path = pwd;

% Set Initial Panel Visibility
proc_mode_list = get(handles.proc_mode_select, 'String');
proc_mode_num = get(handles.proc_mode_select, 'Value');
if proc_mode_num > 3
    error('Unsupported Processing Mode');
end
rec_mode = proc_mode_list{proc_mode_num};
handles = panel_visibility_setter(rec_mode, handles);

% Initialize all Tooltips
handles = tooltip_string_setter(handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SSFC_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SSFC_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in process.
function process_Callback(hObject, eventdata, handles)
% hObject    handle to process (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global path_set_flag
global fpath
global position_file_flag
global pos_file_path
global calibration_set_flag
global cpath

% Get Values
proc_mode_list = get(handles.proc_mode_select, 'String');
proc_mode_num = get(handles.proc_mode_select, 'Value');
if proc_mode_num > 3
    error('Unsupported Processing Mode');
end
proc_mode = proc_mode_list{proc_mode_num};

save_intermediaries_flag = get(handles.save_intermediaries_flag, 'Value');

switch get(handles.img_save_type_tif, 'Value')
    case 1
        img_save_type = '.tif';
    otherwise
        error('Invalid Image Save Type Selected');
end

pixel_size = str2double(get(handles.pixel_size, 'String'));

wavelength_range = [...
    str2double(get(handles.minimum_wavelength, 'String')), ...
    str2double(get(handles.maximum_wavelength, 'String'))];

switch get(handles.bit_depth, 'Value')
    case 1
        bit_depth = 8;
    case 2
        bit_depth = 16;
    case 3
        bit_depth = 32;
    case 4
        bit_depth = 64;
    otherwise
        error('Invalid Output Bit Depth Selected');
end

% Check Processing is Valid
if path_set_flag == 0
    uiwait(msgbox('Please Select a Valid Folder to Process.'));
elseif (position_file_flag == 0) && (proc_mode_num ~= 1)
    uiwait(msgbox('Please Select a Valid Position File'));
elseif calibration_set_flag == 0
    uiwait(msgbox('Please Select a Valid Folder of Calibration Files.'));
else
    % Run Processing
    SSFC_Processing_Framework(proc_mode, ...
        save_intermediaries_flag, img_save_type, bit_depth, fpath, ...
        pixel_size, pos_file_path, cpath, wavelength_range);
    % Close GUI
    closereq;
end


% --- Executes on button press in folder_button.
function folder_button_Callback(hObject, eventdata, handles)
% hObject    handle to folder_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of folder_button

global path_set_flag 
global fpath
global last_path

hpath = pwd;

fpath = uigetdir(last_path, 'Select Folder to Process');
cd(fpath);
for i = 1:numel(fpath)
    if strcmp(filesep, fpath(end-(i-1)))
        rname = fpath((end-(i-2)):end);
        break;
    end
end
dir_list = dir;
dir_list = dir_list(3:end);
sorted_flag = 0;
for i = 1:numel(dir_list)
    if strcmp('Unprocessed Data', dir_list(i).name)
        sorted_flag = 1;
        break;
    end
end

if exist([rname '.xml'], 'file') || sorted_flag
    set(handles.process_folder_display, 'String', fpath);
    path_set_flag = 1;
else
    set(handles.process_folder_display, 'String', ...
        'Invalid Folder Selection');
end
set(handles.process_folder_display, 'TooltipString', fpath);
last_path = fpath;
cd(hpath);


% --- Executes on button press in folder_button.
function calibration_folder_button_Callback(hObject, eventdata, handles)
% hObject    handle to folder_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of folder_button

global calibration_set_flag 
global cpath
global last_path

hpath = pwd;

cpath = uigetdir(last_path, 'Select Calibration Folder');
cd(cpath);
dir_list = dir;
dir_list = dir_list(3:end);

if ~isempty(dir_list)
    set(handles.calibration_folder_display, 'String', cpath);
    calibration_set_flag = 1;
    last_path = cpath;
else
    set(handles.calibration_folder_display, 'String', ...
        'Invalid Folder Selection');
end
set(handles.process_folder_display, 'TooltipString', cpath);
cd(hpath);



% --- Executes on selection change in proc_mode_select.
function proc_mode_select_Callback(hObject, eventdata, handles)
% hObject    handle to proc_mode_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Set Initial Panel Visibility
proc_mode_list = get(handles.proc_mode_select, 'String');
proc_mode_num = get(handles.proc_mode_select, 'Value');
if proc_mode_num > 3
    error('Unsupported Processing Mode');
end
proc_mode = proc_mode_list{proc_mode_num};
handles = panel_visibility_setter(proc_mode, handles);

% Hints: contents = cellstr(get(hObject,'String')) returns proc_mode_select contents as cell array
%        contents{get(hObject,'Value')} returns selected item from proc_mode_select


% --- Executes during object creation, after setting all properties.
function proc_mode_select_CreateFcn(hObject, eventdata, handles)
% hObject    handle to proc_mode_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in save_intermediaries_flag.
function save_intermediaries_flag_Callback(hObject, eventdata, handles)
% hObject    handle to save_intermediaries_flag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of save_intermediaries_flag


function overlap_percent_Callback(hObject, eventdata, handles)
% hObject    handle to overlap_percent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of overlap_percent as text
%        str2double(get(hObject,'String')) returns contents of overlap_percent as a double


% --- Executes during object creation, after setting all properties.
function overlap_percent_CreateFcn(hObject, eventdata, handles)
% hObject    handle to overlap_percent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function threshold_percent_Callback(hObject, eventdata, handles)
% hObject    handle to threshold_percent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of threshold_percent as text
%        str2double(get(hObject,'String')) returns contents of threshold_percent as a double


% --- Executes during object creation, after setting all properties.
function threshold_percent_CreateFcn(hObject, eventdata, handles)
% hObject    handle to threshold_percent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in bit_depth.
function bit_depth_Callback(hObject, eventdata, handles)
% hObject    handle to bit_depth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns bit_depth contents as cell array
%        contents{get(hObject,'Value')} returns selected item from bit_depth


% --- Executes during object creation, after setting all properties.
function bit_depth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bit_depth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function spectral_binning_Callback(hObject, eventdata, handles)
% hObject    handle to spectral_binning (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of spectral_binning as text
%        str2double(get(hObject,'String')) returns contents of spectral_binning as a double


% --- Executes during object creation, after setting all properties.
function spectral_binning_CreateFcn(hObject, eventdata, handles)
% hObject    handle to spectral_binning (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in position_file_button.
function position_file_button_Callback(hObject, eventdata, handles)
% hObject    handle to position_file_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global position_file_flag 
global pos_file_path
global last_path

hpath = pwd;
cd(last_path);

position_file_flag = 0;
[pos_file_name, pos_file_path] = uigetfile('*.xy', ...
    'Select Position File');

if pos_file_name == 0
    uiwait(msgbox('Please Select a Valid Position File'));
elseif ~strcmp(pos_file_name(end-2:end), '.xy')
    uiwait(msgbox('Please Select a Valid Position File'));
else
    position_file_flag = 1;
    last_path = pos_file_path;
    pos_file_path = [pos_file_path, pos_file_name];
    set(handles.pos_file_display, 'String', pos_file_path);
    set(handles.pos_file_display, 'TooltipString', pos_file_path);
end

cd(hpath);






% Function to check and set Panel visibility
function handles = panel_visibility_setter(proc_mode, handles)
switch proc_mode
    case 'Individual Images'
        set(handles.image_stack_ui_panel, 'visible', 'off');
        
    case 'Image Stack'
        set(handles.image_stack_ui_panel, 'visible', 'on');
        
    case 'Video'
        set(handles.image_stack_ui_panel, 'visible', 'on');
end

% Function to set all the ToolTip Strings
function handles = tooltip_string_setter(handles)
% Processing Mode Tooltip
proc_mode_str_1 = 'Select which form of the processing to use.'; 
proc_mode_str_2 = 'Individual images are images with no overlapping areas and can be a random assortment.'; 
proc_mode_str_3 = 'Image Stack is a set of images that have been acquired to make a data cube.';
proc_mode_str_4 = 'Video is a set of images acquired either in 2D or 3D over time to generate a data cube.';
proc_mode_str_full = sprintf('%s\n%s\n%s\n%s', proc_mode_str_1, ...
    proc_mode_str_2, proc_mode_str_3, proc_mode_str_4);
set(handles.text4, 'TooltipString', proc_mode_str_full);
set(handles.proc_mode_select, 'TooltipString', proc_mode_str_full);

% Save Intermediaries Flag Tooltip
save_intermediaries_flag_str_1 = 'Select if you want to save intermediary steps from the processed images.';
save_intermediaries_flag_str_2 = 'NOTE: This will slow down your processing speeds.';
save_intermediaries_flag_str_full = sprintf('%s\n%s', ...
    save_intermediaries_flag_str_1, save_intermediaries_flag_str_2);
set(handles.save_intermediaries_flag, 'TooltipString', ...
    save_intermediaries_flag_str_full); 

% Bit Depth Tooltip
bit_depth_str_full = 'Select the Bit Depth output images should contain.';
set(handles.text7, 'TooltipString', bit_depth_str_full);
set(handles.bit_depth, 'TooltipString', bit_depth_str_full);

% Image Save Type Tif Tooltip
img_save_type_tif_str_full = 'Select for all output images to be saved as .tif';
set(handles.img_save_type_tif, 'TooltipString', ...
    img_save_type_tif_str_full);

% Pixel Size Tooltip
overlap_percent_str_full = 'Size of the pixel.';
set(handles.text5, 'TooltipString', overlap_percent_str_full);
set(handles.pixel_size, 'TooltipString', overlap_percent_str_full);


% Select Folder to Process Tooltip
folder_button_str_full = 'Push to select the folder containg all the data to process.';
set(handles.folder_button, 'TooltipString', ...
    folder_button_str_full);

% Selected Folder to Process Tooltip
process_folder_display_str_full = get(handles.process_folder_display, ...
    'String');
set(handles.process_folder_display, 'TooltipString', ...
    process_folder_display_str_full);

% Select Calibration Folder Tooltip
calibration_folder_button_str_full = 'Push to select the folder containg all the calibration files.';
set(handles.calibration_folder_button, 'TooltipString', ...
    calibration_folder_button_str_full);

% Selected Calibration Folder Tooltip
calibration_folder_display_str_full = get(...
    handles.calibration_folder_display, 'String');
set(handles.calibration_folder_display, 'TooltipString', ...
    calibration_folder_display_str_full);

% Select Position File Tooltip
pos_file_button_str_full = 'Push to select the position file for the data to process.';
set(handles.position_file_button, 'TooltipString', ...
    pos_file_button_str_full);

% Selected Position File Tooltip
pos_file_display_str_full = get(handles.pos_file_display, ...
    'String');
set(handles.pos_file_display, 'TooltipString', ...
    pos_file_display_str_full);

% Process Data Tooltip
process_str_full = 'Push to start processing data.';
set(handles.process, 'TooltipString', ...
    process_str_full);
