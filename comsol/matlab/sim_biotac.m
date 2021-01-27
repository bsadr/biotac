clear all
savefolder = "/home/bsadrfa/behzad/projects/biotac/comsol/results/";

% load comsol file
import com.comsol.model.*
import com.comsol.model.util.*
% model = mphopen('/home/bsadrfa/behzad/projects/biotac/comsol/model/biotac.mph');
model = mphopen('/home/bsadrfa/behzad/projects/biotac/comsol/model/data/biotac_theta_20.mph');
ModelUtil.showProgress(true);

% meshgrid of rays in u,v coordinates
n = 50;
offset = 0.05*pi;
rays_uv = Ray.uvGrid(n, offset);
rays_xyz = Ray.skinGrid(n, offset);model = mphopen('/home/bsadrfa/behzad/projects/biotac/comsol/model/biotac.mph');


% Create a Biotac instance
biotac = Biotac(model, 3, savefolder);
biotac.setSkins;

% biotac.spin
biotac.saveData;
% biotac.plotSkin;

writematrix(rays_xyz, sprintf('%s/rays_xyz.csv', biotac.SaveFolder))
writematrix(rays_uv, sprintf('%s/rays_uv.csv', biotac.SaveFolder))