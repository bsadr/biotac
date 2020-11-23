savefolder = "/home/bsadrfa/behzad/projects/biotac/comsol/results/";

fid = 0;
for i=1:1
    % load comsol file
    import com.comsol.model.*
    import com.comsol.model.util.*
    % biotac_model_.mph has "finer" mesh preset
    % model = mphopen('/home/bsadrfa/behzad/projects/shadowhand/comsol/biotac_model.mph');%
    model = mphopen('/home/bsadrfa/behzad/projects/biotac/comsol/model/biotac.mph');
    ModelUtil.showProgress(true);
    
    % meshgrid of rays in u,v coordinates
    n = 20;
    offset = 0.05*pi;
    rays_uv = Ray.uvGrid(n, offset);
    rays_xyz = Ray.skinGrid(n, offset);

    % Create a Biotac instance
    biotac = Biotac(model, i, savefolder);
    
    biotac.spin
    
%     biotac.init;
%     biotac.makeContact;
%     biotac.planMotion;
%     biotac.spinAll;
end