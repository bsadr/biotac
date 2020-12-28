% demofile = '/home/bsadrfa/behzad/projects/biotac/comsol/largefiles/biotac(demo,mu=2).mph';
% modeld = mphopen(demofile);
view_vec = [1, 0, 0];
fig = figure(1);
for i=1:40
    modeld.result('pg3').set('looplevel', i);
    modeld.result('pg3').run
    mphplot(modeld,'pg3', 'createplot', 'on')
    view(view_vec)
    pause(0.1)
end
%%
% load comsol model       
view_vec = [1, 0, 0];
fig = figure(1);
surface = [];
model = mphopen('/home/bsadrfa/behzad/projects/biotac/comsol/model/biotac.mph');
for i=1:16
    model.result('pg1').set('looplevel', i);
    model.result('pg1').run
    pd=mphplot(model,'pg1', 'createplot', 'on');
%     surface = [surface pd{2}{1}];
    view(view_vec)
    pause(0.1)
end