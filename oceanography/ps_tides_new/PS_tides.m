% PS_tides.m
%
% initially coded by Dave Winkel (UW-APL) in 2001
%
% edited by Parker MacCready2/26/2009 to:
% improve spacing of boxes in the gui
% add a datenum format field to the saved output (near end of
% PS_gui_funcs.m)

global PS_AREA CHAN SEG_INDEX lat_sh lon_sh TIDE_OUT
global h0 hAbx hCbx hSbx hSG hDT hDY hMap hCalc

load PSTM_shoreline % greater Puget Sound shoreline
load PSTM_areas % five main areas, with channels in each
load PSTM_chan_segs % channels, with segments in each
load PSTM_seg_index % locations of segments, and cross-index to area,channel

% create useful vectors
segs=SEG_INDEX.segno; mx=max(segs);
segi(1:mx,1)=NaN; segi(segs,1)=[1:length(segs)]';
SEG_INDEX.segind = segi; % index by segment number
yx1=SEG_INDEX.latlon1; yx2=SEG_INDEX.latlon2;
xx=[yx1(:,2) (yx1(:,2)+yx2(:,2))/2 yx2(:,2)];
yy=[yx1(:,1) (yx1(:,1)+yx2(:,1))/2 yx2(:,1)];
SEG_INDEX.lonpts = xx; SEG_INDEX.latpts = yy; % for plotting/selecting segments
% get widest limits for plot
xx=SEG_INDEX.LonLatLims;
yy = [min(min(xx(:,1:2))) max(max(xx(:,1:2))) ...
    min(min(xx(:,3:4))) max(max(xx(:,3:4)))];
SEG_INDEX.MAP_lims = yy;
PlRat = [1 cos(mean(yy(3:4))*pi/180) 1];
% Area names
for i=1:5
    ARnm{i} = PS_AREA(i).name;
end

CHno=[]; CHnm=[]; SEGch=[]; ARind=[]; SEGent=[]; SDate=[]; NDays=[];

% Set up GUI
fs1 = 14; fs2 = 14; % fontsizes
% set(0,'defaultaxesfontsize',fs1);
% set(0,'defaulttextfontsize',fs1);

% main figure
h0 = figure('Color',[1 1 1], ...
    'Units','pixels', ...
    'Position',[200 200 800 600], ...
    'Tag','PSTMgui', ...
    'ToolBar','none');

% List_boxes

% Area choice
hAbx = uicontrol('Parent',h0, ...
    'Units','normalized', ...
    'BackgroundColor',[1 1 1], ...
    'Callback',['PS_gui_funcs(1,0);'], ...
    'Position',[.05 .7 .3 .2], ...
    'String',ARnm, ...
    'Style','listbox', ...
    'FontSize',fs2, ...
    'Tag','AreaList', ...
    'Value',1);
hAlb = uicontrol('Parent',h0, ...
    'Units','normalized', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',fs2, ...
    'FontWeight','bold', ...
    'ListboxTop',0, ...
    'Position',[.05 .9 .3 .05], ...
    'String','Area', ...
    'Style','text', ...
    'Tag','StaticText1');

% Channel choice
hCbx = uicontrol('Parent',h0, ...
    'Units','normalized', ...
    'BackgroundColor',[1 1 1], ...
    'Callback',['PS_gui_funcs(2,0);'], ...
    'Position',[.4 .7 .3 .2], ...
    'String', CHnm, ...
    'Style','listbox', ...
    'FontSize',fs2, ...
    'Tag','ChanList', ...
    'Value',1);
hClb = uicontrol('Parent',h0, ...
    'Units','normalized', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',fs2, ...
    'FontWeight','bold', ...
    'ListboxTop',0, ...
    'Position',[.4 .9 .3 .05], ...
    'String','Channel', ...
    'Style','text', ...
    'Tag','StaticText1');

% Segment choice
hSbx = uicontrol('Parent',h0, ...
    'Units','normalized', ...
    'BackgroundColor',[1 1 1], ...
    'Callback',['PS_gui_funcs(3,0);'], ...
    'Position',[.75 .7 .2 .2], ...
    'String', SEGch, ...
    'Style','listbox', ...
    'FontSize',fs2, ...
    'Tag','SegList', ...
    'Value',1);
hSlb = uicontrol('Parent',h0, ...
    'Units','normalized', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',fs2, ...
    'FontWeight','bold', ...
    'ListboxTop',0, ...
    'Position',[.75 .9 .2 .05], ...
    'String','Segment (top is furthest from N. Adm Inlet)', ...
    'Style','text', ...
    'Tag','StaticText1');

% text entry boxes

% Segment choice (direct input)
hSG = uicontrol('Parent',h0, ...
    'Units','normalized', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',fs2, ...
    'Callback', ['PS_gui_funcs(3,1);'], ...
    'ListboxTop',0, ...
    'Position',[.75 .5 .2 .05], ...
    'Style','edit', ...
    'UserData', NaN, ...
    'Tag','SegEnt');
hSGlb = uicontrol('Parent',h0, ...
    'Units','normalized', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',fs2, ...
    'FontWeight','bold', ...
    'ListboxTop',0, ...
    'Position',[.75 .55 .2 .05], ...
    'String','Segment (direct input)', ...
    'Style','text', ...
    'Tag','StaticText1');

% Start date input
hDT = uicontrol('Parent',h0, ...
    'Units','normalized', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',fs2, ...
    'Callback', ['PS_gui_funcs(5,0);'], ...
    'ListboxTop',0, ...
    'Position',[.75 .35 .2 .05], ...
    'Style','edit', ...
    'UserData', NaN, ...
    'Tag','StartEnt');
hDTlb = uicontrol('Parent',h0, ...
    'Units','normalized', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',fs2, ...
    'FontWeight','bold', ...
    'ListboxTop',0, ...
    'Position',[.75 .4 .2 .05], ...
    'String','Start Date', ...
    'Style','text', ...
    'Tag','StaticText1');

% Number of days input
hDY = uicontrol('Parent',h0, ...
    'Units','normalized', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',fs2, ...
    'Callback', ['PS_gui_funcs(6,0);'], ...
    'ListboxTop',0, ...
    'Position',[.75 .2 .2 .05], ...
    'Style','edit', ...
    'UserData', NaN, ...
    'Tag','DaysEnt');
hDYlb = uicontrol('Parent',h0, ...
    'Units','normalized', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',fs2, ...
    'FontWeight','bold', ...
    'ListboxTop',0, ...
    'Position',[.75 .25 .2 .05], ...
    'String','No. of Days', ...
    'Style','text', ...
    'Tag','StaticText2');

% Axes for map of PS segments
hMap = axes('Parent',h0, ...
    'Units','normalized', ...
    'CameraUpVector',[0 1 0], ...
    'box', 'on', ...
    'Position',[.05 .05 .6 .6], ...
    'Tag','PSegPlot', ...
    'XColor',[0 0 0], ...
    'YColor',[0 0 0], ...
    'ZColor',[0 0 0]);

% Button to initiate tide calculation
hCalc = uicontrol('Parent',h0, ...
    'Units','normalized', ...
    'BackgroundColor',[0.75 0.75 0.75], ...
    'FontSize',fs2, ...
    'FontWeight','bold', ...
    'Callback', ['PS_gui_funcs(7,0);'], ...
    'ListboxTop',0, ...
    'Position',[.75 .05 .2 .1], ...
    'String','Compute tide', ...
    'Tag','CalcTide');

% Coastline and etc. for map
axes(hMap);
plot(lon_sh, lat_sh, 'k-', 'linewidth',2, ...
    'ButtonDownFcn',['PS_gui_funcs(4,0);']);
yy=SEG_INDEX.MAP_lims;
axis(yy + [-1 1 -1 1]/20);
set(hMap, 'DataAspectRatio',PlRat);

return

