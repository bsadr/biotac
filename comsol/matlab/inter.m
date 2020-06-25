%% load comsol file
import com.comsol.model.*
import com.comsol.model.util.*
% biotac_model.mph has "finer" mesh preset
% model = mphopen('/home/bsadrfa/behzad/projects/shadowhand/comsol/biotac_model.mph');%
model = mphopen('/home/bsadrfa/behzad/projects/shadowhand/comsol/biotac_model_fine_mesh.mph');
save_folder = '/home/bsadrfa/behzad/projects/shadowhand/comsol/results';
ModelUtil.showProgress(true);

%% meshgrid of rays in u,v coordinates
n = 20;
offset = 0.05*pi;
rays_uv = Ray.uvGrid(n, offset);
rays_xyz = Ray.skinGrid(n, offset);
figure(1)
scatter3(rays_xyz(:,1), rays_xyz(:,2), rays_xyz(:,3), [],  '.')
axis equal
hold on
s = Skin(model, Ray);
s.drawEllip;
%% test skin
s = Skin(model, Ray);
t_xyz = s.test_convert_xyz;
t_uv = s.test_convert_uv;
%% Create a Biotac instance
biotac = Biotac(model);
%%
biotac.spinAll;
%% Iterate 
biotac.spinOnce();
biotac.csvWrite
%% plot results

%% test uv_to_xyz
r = Ray;
uv = r.xyz_to_uv(rays_xyz);
xyz = r.uv_to_xyz(uv);
dif_uv = rays_uv - uv;
dif_x = rays_xyz - xyz;
err = sum(dif_x.*dif_x);
figure(2)
scatter3(xyz(:,1), xyz(:,2), xyz(:,3), '.')

%% test Skin
import com.comsol.model.*
import com.comsol.model.util.*
model = mphopen('/home/bsadrfa/behzad/projects/shadowhand/comsol/biotac_model_fine_mesh.mph');

rays = Ray();
skinBase = Skin(model, rays);

%% load comsol defromed plot
figure(3)
pd=mphplot(model, 'pg4', 'createplot', 'off');
skin = pd{2}{1};

% create trianlges and vertices from the deformed plot
vertices = skin.p.';
triangles =  1+skin.t.';
vert1 = vertices(triangles(:,1),:);
vert2 = vertices(triangles(:,2),:);
vert3 = vertices(triangles(:,3),:);

% intersect rays
orig = [0 0 0];
%intersection points
i_points = zeros(size(rays_xyz, 1), 7);
%intersection triangles
i_tris = zeros(size(rays_xyz, 1),1);

tic;
for i=1:size(rays_xyz)
    [intersect, t, u, v, xcoor] = TriangleRayIntersection(orig, rays_xyz(i,:), vert1, vert2, vert3);
    indices = find(intersect);
    normal_distances = t(indices);
    [normal_d, local_idx] = max(normal_distances);
    idx = indices(local_idx);

    i_points(i, :) = [xcoor(idx, :), normal_d, idx, u(idx), v(idx)];
    i_tris(i) = idx;
end
fprintf('Number of: faces=%i, points=%i, rays=%i; time=%f sec\n', ...
  size(triangles,1), size(vertices,1), size(intersections, 1), toc);

figure(3)
hold on
scatter3(intersections(:,1), intersections(:,2), intersections(:,3), '.')
view([1, 0, 0])
ylim([-10.6  10.6])
xlim([-14.9 14.9])
zlim([-14.2 0])
xlabel('x [mm]')
ylabel('y [mm]')
zlabel('z [mm]')
%%
figure(3)
hold on
trisurf(triangles, vertices(:,1), vertices(:,2), vertices(:,3), intersect*1.0,'FaceAlpha', 0.7)
hold on;
line('XData',[0 dir(1)],'YData',orig(2)+[0 dir(2)],'ZData',...
  orig(3)+[0 dir(3)],'Color','r','LineWidth',3)
set(gca, 'CameraPosition', [106.2478  -35.9079  136.4875])
set(gco,'EdgeColor','none');
%%
orig = [0 0 0];

dir = [10 0 -2];
pd=mphplot(model,'pg4');
skin = pd{2}{1};
vertices = skin.p.';
triangles =  1+skin.t.';

vert1 = vertices(triangles(:,1),:);
vert2 = vertices(triangles(:,2),:);
vert3 = vertices(triangles(:,3),:);

tic;
[intersect, ~, ~, ~, xcoor] = TriangleRayIntersection(orig, dir, vert1, vert2, vert3, ...
    'lineType', 'line', 'planeType', 'two sided');
points = xcoor(intersect, :);
distances = sum((points.'-orig.').^2);
[d, idx] = max(distances);
d = sqrt(d)
interpoint = points(idx, :)
fprintf('Number of: faces=%i, points=%i, intresections=%i; time=%f sec\n', ...
  size(triangles,1), size(vertices,1), sum(intersect), toc);

figure(4); clf;
trisurf(triangles, vertices(:,1), vertices(:,2), vertices(:,3), intersect*1.0,'FaceAlpha', 0.7)
hold on;
line('XData',orig(1)+[0 dir(1)],'YData',orig(2)+[0 dir(2)],'ZData',...
  orig(3)+[0 dir(3)],'Color','r','LineWidth',3)
set(gca, 'CameraPosition', [106.2478  -35.9079  136.4875])
set(gco,'EdgeColor','none');

%%
function [points, tris] = calcIntersect(skin, ray)
%clacIntersect(skin, ray)
%   points(N x 7): [intersection point(x, y, z), normal distance, triangle
%   numbers, point in triangle in Barycentric coordinate system (u, v)]
%   tris (N x 1): triangle numbers
%     rays_uv = ray.uvGrid();
    rays_xyz = ray.skinGrid();
    % create trianlges and vertices from the deformed plot
    vertices = skin.p.';
    triangles =  1+skin.t.';
    vert1 = vertices(triangles(:,1),:);
    vert2 = vertices(triangles(:,2),:);
    vert3 = vertices(triangles(:,3),:);

    % intersect rays
    orig = [0 0 0];
    %intersection points
    points = zeros(size(rays_xyz, 1), 7);
    %intersection triangles
    tris = zeros(size(rays_xyz, 1),1);

    for i=1:size(rays_xyz)
        [intersect, t, u, v, xcoor] = TriangleRayIntersection(orig, rays_xyz(i,:), vert1, vert2, vert3);
        indices = find(intersect);
        normal_distances = t(indices);
        [normal_d, local_idx] = max(normal_distances);
        idx = indices(local_idx);

        points(i, :) = [xcoor(idx, :), normal_d, idx, u(idx), v(idx)];
        if nargout ==2
            tris(i) = idx;
        end
    end    
    
end

function [px, py, pz] = pointTri(tri, u, v, skin) 
    % create trianlges and vertices from the skin
    vertices = skin.p.';
    triangles =  1+skin.t.';
    v1 = vertices(triangles(tri,1),:);
    v2 = vertices(triangles(tri,2),:);
    v3 = vertices(triangles(tri,3),:);
    
    % calc the point inside the triangles
    w = 1-u-v;
    px = u.*v1(:,1)+v.*v2(:,1)+w.*v3(:,1);
    py = u.*v1(:,2)+v.*v2(:,2)+w.*v3(:,2);
    pz = u.*v1(:,3)+v.*v2(:,3)+w.*v3(:,3);
end