clear all
savefolder = "/home/bsadrfa/behzad/projects/biotac/comsol/results/";
model_paths = ["/home/bsadrfa/behzad/projects/biotac/comsol/model/data/biotac.mph"; ...
    "/home/bsadrfa/behzad/projects/biotac/comsol/model/data/biotac_theta_10.mph"; ...
    "/home/bsadrfa/behzad/projects/biotac/comsol/model/data/biotac_theta_20.mph"; ...
    "/home/bsadrfa/behzad/projects/biotac/comsol/model/data/biotac_theta_30.mph"; ...
    "/home/bsadrfa/behzad/projects/biotac/comsol/model/data/biotac_theta_40.mph"; ...
    "/home/bsadrfa/behzad/projects/biotac/comsol/model/data/biotac_theta_50.mph"; ...
    "/home/bsadrfa/behzad/projects/biotac/comsol/model/data/biotac_theta_-10.mph"; ...
    "/home/bsadrfa/behzad/projects/biotac/comsol/model/data/biotac_theta_-20.mph"; ...
    "/home/bsadrfa/behzad/projects/biotac/comsol/model/data/biotac_theta_-30.mph"; ...
    "/home/bsadrfa/behzad/projects/biotac/comsol/model/data/biotac_theta_-40.mph"; ...
    "/home/bsadrfa/behzad/projects/biotac/comsol/model/data/biotac_theta_-50.mph"; ...
    "/home/bsadrfa/behzad/projects/biotac/comsol/model/data/biotac_theta_-60.mph"];


    import com.comsol.model.*
    import com.comsol.model.util.*
    ModelUtil.showProgress(true);

    % meshgrid of rays in u,v coordinates
    n = 40;
    offset = 0.05*pi;
    rays_uv = Ray.uvGrid(n, offset);
    rays_xyz = Ray.skinGrid(n, offset);

for i=1:size(model_paths, 1)
    % load comsol file
    model = mphopen(char(model_paths(i)));

    % Create a Biotac instance
    biotac = Biotac(model, i, savefolder);
%     biotac.setSkins;

    % biotac.spin
    biotac.saveData;
    % biotac.plotSkin;

    % biotac.Skins(1).plot(figure(1), [0, 0, 1]);
    % fig=figure(1);
    % 
    % biotac.SensorSkins(1).plot(figure(2), [0, 0, 1]);
    % fig2=figure(2);
    % 
    % 
    % writematrix(rays_xyz, sprintf('%s/rays_xyz.csv', biotac.SaveFolder))
    % writematrix(rays_uv, sprintf('%s/rays_uv.csv', biotac.SaveFolder))
end
