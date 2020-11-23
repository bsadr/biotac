savefolder = "/home/bsadrfa/behzad/projects/biotac/comsol/results/";
cfg_folder = savefolder + "configs/";
cfg_base = cfg_folder + "base.csv";
t = readtable(cfg_base);
parameters = t.(1);
values = t.(2);
for i=1:size(values,1)
    model.param.set(parameters(i), values(i));
end

model.component('comp1').geom('geom1').run;
model.component('comp1').geom('geom1').run('fin');
model.component('comp1').mesh('mesh2').run;
model.component('comp1').mesh('mesh3').run;
model.component('comp1').mesh('mesh4').run;

model.study('std1').feature('stat').set('pname', {'para'});
model.study('std1').feature('stat').set('plistarr', {'range(0,istep,istop)'});
model.study('std1').feature('stat').set('punit', {''});

model.sol('sol1').feature('v1').set('clistctrl', {'p1'});
model.sol('sol1').feature('v1').set('cname', {'para'});
model.sol('sol1').feature('v1').set('clist', {'range(0,istep,istop)'});

model.sol('sol1').feature('s1').feature('p1').set('pname', {'para'});
model.sol('sol1').feature('s1').feature('p1').set('plistarr', {'range(0,istep,istop)'});
model.sol('sol1').feature('s1').feature('p1').set('punit', {''});

model.study('std1').run

fid = 0;
for i=1:1
    % load comsol file
    import com.comsol.model.*
    import com.comsol.model.util.*
    % biotac_model_.mph has "finer" mesh preset
    % model = mphopen('/home/bsadrfa/behzad/projects/shadowhand/comsol/biotac_model.mph');%
    model = mphopen('/home/bsadrfa/behzad/projects/biotac/comsol/model/biotac.mph');
    ModelUtil.showProgress(true);
end

%     model.param.set('idz', 1.0);
%     p1=model.batch.create('p1', 'Parametric');
%     p1.set('pname', 'idy');
%     p1.set('plist', 'range(0.0,0.1,1.0)');
%     p1.run;
%     model.study('std1').run

    

    model.result('pg1').set('looplevel', 1);
    model.result('pg1').run
   
%     pd=mphplot(model,'pg1', 'createplot', 'off');
    pd=mphplot(model,'pg1');
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
% end