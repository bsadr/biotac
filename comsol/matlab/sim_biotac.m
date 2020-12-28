clear all
savefolder = "/home/bsadrfa/behzad/projects/biotac/comsol/results/";

% load comsol file
import com.comsol.model.*
import com.comsol.model.util.*
model = mphopen('/home/bsadrfa/behzad/projects/biotac/comsol/model/biotac.mph');
ModelUtil.showProgress(true);

% meshgrid of rays in u,v coordinates
n = 30;
offset = 0.05*pi;
rays_uv = Ray.uvGrid(n, offset);
rays_xyz = Ray.skinGrid(n, offset);

% Create a Biotac instance
biotac = Biotac(model, 1, savefolder);
biotac.setSkins;

% biotac.spin
