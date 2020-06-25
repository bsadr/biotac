MAX_Z = [10.55447]
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
%% set p0
model.param.set('pf_pre', '5000.0');  
model.common('pres1').set('prescribedDeformation', { ...
    '0.0[mm]', '0.0[mm]', '-2.0[mm]'});
model.study('std2').run

%% initialize the rays
% grid of rays
n = 5;
offset = 0.25*pi;
rays = Ray;
rays_uv = Ray.uvGrid(n, offset);
rays_xyz = Ray.skinGrid(n, offset);
baseSkin = Skin(model);
% figure(1)
%% read stl file
pd=mphreadstl('/home/bsadrfa/behzad/projects/shadowhand/comsol/skinSurface/filledSkin.STL');
pd{1,1}.title = 'filled skin';
tmp = pd{1,1}.p(2,:);
pd{1,1}.p(2,:)=pd{1,1}.p(3,:);
pd{1,1}.p(3,:)=tmp;
max_z = max(pd{1,1}.p(3,:))
max_x = max(pd{1,1}.p(1,:));
max_y = max(pd{1,1}.p(2,:));
pd{1,1}.p(3,:) = pd{1,1}.p(3,:) - max_z;
pd{1,1}.p(1,:) = pd{1,1}.p(1,:) - max_x/2;
pd{1,1}.p(2,:) = pd{1,1}.p(2,:) - max_y/2;
mphplot(pd)

filledSkin=Skin(pd, baseSkin, 1);
 min(filledSkin.Vertices(:,3))

%% plot
subplot(1, 2, 1)
filledSkin.triSurf('b')
hold on
baseSkin.triSurf('y')
view([1 0 0])
ylim([-10.6  10.6])
xlim([-14.9 14.9])
zlim([-14.2 0])
xlabel('x [mm]')
ylabel('y [mm]')
zlabel('z [mm]')

subplot(1, 2, 2)
filledSkin.triSurf('b')
hold on
baseSkin.triSurf('y')
view([0 0 1])
ylim([-10.6  10.6])
xlim([-14.9 14.9])
zlim([-14.2 0])
xlabel('x [mm]')
ylabel('y [mm]')
zlabel('z [mm]')

saveas(gcf, "/home/bsadrfa/behzad/projects/shadowhand/comsol/results/p0Skin-5000.png")


