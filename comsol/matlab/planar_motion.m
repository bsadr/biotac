%% load comsol file
import com.comsol.model.*
import com.comsol.model.util.*
% biotac_model.mph has "finer" mesh preset
% model =
% mphopen('/home/bsadrfa/behzad/projects/shadowhand/comsol/biotac_model.mph');%
model = mphopen('/home/bsadrfa/behzad/projects/shadowhand/comsol/biotac_model_fine_mesh.mph');
save_folder = '/home/bsadrfa/behzad/projects/shadowhand/comsol/results';
ModelUtil.showProgress(true);
% ModelUtil.showProgress(false);
% Shore A26 for biotac sensor
model.param.set('c01', .083);
model.param.set('c10', .332);
model.result('pg4').set('title', '');
model.result('pg6').feature('arws1').set('scale', '2.0E-4');
model.param.set('iw', '20');
model.param.set('il', '14');
model.geom('geom1').run();
model.mesh('mesh2').run();

%% initialize the rays
% grid of rays
n = 5;
offset = 0.25*pi;
rays = Ray;
rays_uv = Ray.uvGrid(n, offset);
rays_xyz = Ray.skinGrid(n, offset);
% figure(1)
% scatter3(rays_xyz(:,1), rays_xyz(:,2), rays_xyz(:,3), '.')
% initial intersections

% pd=mphplot(model,'pg4', 'createplot', 'off');
% skinBase = pd{2}{1};
[pointsBase, trisBase] = calcIntersect(skinBase, rays);


%% define plane motion
% number of steps
N = 5; 
step = .001;
dx = zeros(1, N);
dy = zeros(1, N);
[gap,~,~,~] = mphevaluate(model, 'igap');
dz = linspace(gap,gap+(N-1)*step,N);

%% test 
    % finding intersections
    pd=mphplot(model,'pg4', 'createplot', 'off');
    skin = pd{2}{1};
    [points, tris] = calcIntersect(skinBase, rays);
    %   points(N x 7) = [intersection point(x, y, z), normal distance, triangle
    %   number, point in triangle in Barycentric coordinate system (u, v)]

    % finding points on skin from the Barycentric coordinates
    [px, py, pz] = pointTri(tris, points(:,6), points(:,7), skinBase);
    scatter3(px, py, pz, '.')
    dif_points = points(:,1:3)-[px, py, pz];

%% Main loop
f1 = figure;
f2 = figure;
plotGroups = ["pg6", "pg4"];
plotNames = ["contact", "deformation"];
p0 = mphglobal(model,'p0');
tic
wBar = waitbar(0, 'Main Loop Progress ...');
for i = 1:N-1
    % call comsol solver
    model.common('pres1').set('prescribedDeformation', ...
        {sprintf('%0.2f[mm]', dx(i)), sprintf('%0.2f[mm]', dy(i)), sprintf('%0.2f[mm]', dz(i))});
    try
%         model.study('std2').run
    catch 
        warning('BIOTAC MODEL COMSOL ERROR OCCURED')
%         break
    end
    waitbar((i-.5)/N, wBar,'Postprocessing current iteration');
    
    % postprocessing the solution
    
    % finding intersections
    pd=mphplot(model,'pg4', 'createplot', 'off');
    skin = pd{2}{1};
    [points, tris] = calcIntersect(skin, rays);
    %   points(N x 7) = [intersection point(x, y, z), normal distance, triangle
    %   number, point in triangle in Barycentric coordinate system (u, v)]

    dif_p = points-pointsBase;
    dif_t = tris-trisBase;

    % plotting the solver solution
    if 1==2
    for j = 1:2
        fig = figure(j);
        set(fig, 'PaperPositionMode', 'manual');
        set(fig, 'PaperUnits', 'inches');
        set(fig, 'PaperPosition', [0 0 8 6]);
        ax1 = subplot(1, 2, 1);
        mphplot(model, plotGroups(j), 'rangenum', 1);
        view([1, 0, 0])
%         set(ax1, 'visible', 'off')
        ylim([-10.6  10.6])
        xlim([-14.9 14.9])
        zlim([-14.2 0])
        xlabel('x [mm]')
        ylabel('y [mm]')
        zlabel('z [mm]')
        tighten(ax1);
        ax2 = subplot(1, 2, 2);
        mphplot(model, plotGroups(j), 'rangenum', 1);
        view([0, 1, 0])
%         set(ax2, 'visible', 'off')
        ylim([-10.6  10.6])
        xlim([-14.9 14.9])
        zlim([-14.2 0])
        xlabel('x [mm]')
        ylabel('y [mm]')
        zlabel('z [mm]')
        tighten(ax2);
        sgtitle(strcat("\itd\rm\bfx\rm=", sprintf("[%0.2f, %0.2f, %0.2f]", dx(i), dy(i), dz(i)-gap)))
        saveas(fig, sprintf('%s/%s_%03d.png', save_folder, plotNames(j), i));
        close(j);
    end
    end
    
    % save stl
%     pd=mphplot(model,'pg4')
%     pd2stl=pd{2}{1};
%     mphwritestl(sprintf('%s/stl_deformation_%03d.stl', save_folder, i), pd2stl);
    
    % updating the total contact force in the model
    U = mphgetu(model);
    pc = mphglobal(model,'pc');
    model.param.set('pf_pre', p0+pc);
%     model.sol('sol1').setU(U)
%     model.sol('sol1').run;
    waitbar(i/N, wBar, 'Waiting for Comsol solver for next solution');
end
toc 
close(wBar)

