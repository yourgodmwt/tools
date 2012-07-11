function [] = dc_roms_vorticity(fname,tindices,outname,isDir)

 if ~exist('outname','var') || isempty(outname), outname = 'ocean_vor.nc'; end
if ~exist('isDir','var'), isDir = 0; end

if isdir(fname)
    files = ls([fname '\*.nc']);
    isDir = 1;
    for ii=1:length(files)
        dc_roms_vorticity([fname '\' files(ii,:)],tindices,outname,ii);
    end
end
    
vinfo = ncinfo(fname,'u');
s     = vinfo.Size;
dim   = length(s); 
slab  = roms_slab(fname,0)-3;

warning off
grid = roms_get_grid(fname,fname,0,1);
warning on

% parse input
if ~exist('tindices','var'), tindices = []; end

[iend,tindices,dt,nt,stride] = roms_tindices(tindices,slab,vinfo.Size(end));

%if ~isDir
    tvor = ncread(fname,'ocean_time');
    tvor = tvor([tindices(1):tindices(2)]);
%else
    % make time vector from
    
%end

grid1.xv = grid.lon_v(1,:)';
grid1.yv = grid.lat_v(:,1);
grid1.zv = grid.z_v;

grid1.xu = grid.lon_u(1,:)';
grid1.yu = grid.lat_u(:,1);
grid1.zu = grid.z_u;

xname = 'xvor'; yname = 'yvor'; zname = 'zvor'; tname = 'ocean_time';

%% setup netcdf file
% overwrite = ~isDir;
% 
%     overwrite = input('File exists. Do you want to overwrite (1/0)? ');
% end

if exist(outname,'file')
    fprintf('\n Appending to existing file. File = %s \n', fname);
else
    delete(outname);
    nccreate(outname,'vor','Dimensions', {xname s(1) yname s(2)-1 zname s(3) tname Inf});
    nccreate(outname,xname,'Dimensions',{xname s(1)});
    nccreate(outname,yname,'Dimensions',{yname s(2)-1});
    nccreate(outname,zname,'Dimensions',{xname s(1) yname s(2)-1 zname s(3)});
    nccreate(outname,tname,'Dimensions',{tname Inf});

    ncwriteatt(outname,'vor','Description','Vorticity calculated from ROMS output');
    ncwriteatt(outname,'vor','coordinates','xvor yvor zvor ocean_time');
    ncwriteatt(outname,'vor','units','1/s');
    ncwriteatt(outname,xname,'units',ncreadatt(fname,'lon_u','units'));
    ncwriteatt(outname,yname,'units',ncreadatt(fname,'lat_u','units'));
    ncwriteatt(outname,zname,'units','m');
    ncwriteatt(outname,tname,'units','datenum');
    fprintf('\n Created file : %s\n', outname);
end

%% loop and calculate
for i=0:iend-1
    [read_start,read_count] = roms_ncread_params(dim,i,iend,slab,tindices,dt);
    tstart = read_start(end);
    tend   = read_start(end) + read_count(end) -1;
    
    u      = ncread(fname,'u',read_start,read_count,stride);
    v      = ncread(fname,'v',read_start,read_count,stride);
    
    toUTM =  findstr(ncreadatt(fname,'lon_u','units'),'degree');
    
    [vor,xvor,yvor,zvor] = vorticity_cgrid(grid1,u,v,toUTM);
    
    read_start(4) = isDir;
    [~,~,T] = Z_get_basic_info(fname);
    
    if i == 0
        ncwrite(outname,xname,xvor);
        ncwrite(outname,yname,yvor);
        ncwrite(outname,zname,zvor);
    end
    
    ncwrite(outname,'vor',vor,read_start); 
    ncwrite(outname,'ocean_time',T.time_datenum,[isDir]);
    
    %intPV(tstart:tend) = domain_integrate(pv,xpv,ypv,zpv);
    
end
