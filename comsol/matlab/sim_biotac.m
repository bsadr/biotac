savefolder = "/home/bsadrfa/behzad/projects/shadowhand/comsol/results";

fid = 3;
for i=1:1
    % load comsol file
    import com.comsol.model.*
    import com.comsol.model.util.*
    % biotac_model_.mph has "finer" mesh preset
    % model = mphopen('/home/bsadrfa/behzad/projects/shadowhand/comsol/biotac_model.mph');%
    model = mphopen('/home/bsadrfa/behzad/projects/shadowhand/comsol/biotac_model_fine_mesh.mph');
    ModelUtil.showProgress(true);

    % meshgrid of rays in u,v coordinates
    n = 20;
    offset = 0.05*pi;
    rays_uv = Ray.uvGrid(n, offset);
    rays_xyz = Ray.skinGrid(n, offset);

    % Create a Biotac instance
    biotac = Biotac(model);
    biotac.SaveFolder = sprintf("%s/%d", savefolder, fid+i);
    N = biotac.NumWayPoints;
    biotac.spinAll;
end