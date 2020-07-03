savefolder = "/home/bsadrfa/behzad/projects/biotac/comsol/results";

fid = 4;
for i=1:1
    % load comsol file
    import com.comsol.model.*
    import com.comsol.model.util.*
    % biotac_model_.mph has "finer" mesh preset
    % model = mphopen('/home/bsadrfa/behzad/projects/shadowhand/comsol/biotac_model.mph');%
    model = mphopen('/home/bsadrfa/behzad/projects/biotac/comsol/model/biotac.mph');
    ModelUtil.showProgress(true);

%     model.param.set('idz', 1.0);
%     p1=model.batch.create('p1', 'Parametric');
%     p1.set('pname', 'idy');
%     p1.set('plist', 'range(0.0,0.1,1.0)');
%     p1.run;
    model.study('std1').run

    pd2 = mphgetcoords(model, 'geom1', 'domain', 1);
    mphplot(pd,'colortable', 'RainbowLight')
    
    pg1 = mphplot(model,'pg3');
    pd=mphplot(model,'pg1', 'createplot', 'off');
    surface = pd{2}{1};                       

    mphplot(model);
    
    % meshgrid of rays in u,v coordinates
%     n = 20;
%     offset = 0.05*pi;
%     rays_uv = Ray.uvGrid(n, offset);
%     rays_xyz = Ray.skinGrid(n, offset);

    % Create a Biotac instance
%     biotac = Biotac(model);
%     biotac.SaveFolder = sprintf("%s/%d", savefolder, fid+i);
%     N = biotac.NumWayPoints;
%     biotac.spinAll;
end