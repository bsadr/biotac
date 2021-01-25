classdef Biotac < handle
    %Biotac Manager class for simulating biotac sensor
    %   Manager class for simulating biotac sensor
    
    properties
        Model
        SaveFolder
        DeformedSkin
        
        Config

        % motion
        WayPoints
        NumWayPoints
        CurWayPoint
        DirNormal
        StrainNormal
        DirTangent
        Step
        InContact
        
        % output
        SensorSkins % Sensor
        Skins     % High Def Skins
        FluidPressures
        ContactPressures
        SkinHeights
    end
       
    methods
        function obj = Biotac(model, cfgid, savefolder)
            %Biotac Construct an instance of this class
            %   Construct an instance of this class

            obj.Model = model;
            obj.SaveFolder = '/home/bsadrfa/behzad/projects/biotac/comsol/results/';
            if nargin>2
                obj.SaveFolder = savefolder;
            end
            obj.Config = cfgid;
            obj.init;
        end
              
        function obj = readCfg(obj, cfgnum)
            cfgpath = obj.SaveFolder + "configs/";
            if cfgnum==0 
                cfgname = "base.csv";
            else
                cfgname = sprintf("%d.csv", cfgnum);
            end
            t = readtable(cfgpath+cfgname);
            parameters = t.(1);
            values = t.(2);
            for i=1:size(values,1)
                obj.Model.param.set(parameters(i), values(i));
            end
        end
        
        function obj = setCfg(obj,  mesh)
            %  mesh is in {'mesh2', 'mesh3', 'mesh4'}
            obj.Model.component('comp1').geom('geom1').run;
            if nargin==1
                mesh = 'mesh2';
            end
            obj.Model.component('comp1').mesh(mesh).run;

            obj.Model.study('std1').feature('stat').set('pname', {'para'});
            obj.Model.study('std1').feature('stat').set('plistarr', {'range(0,istep,istop)'});
            obj.Model.study('std1').feature('stat').set('punit', {''});

            obj.Model.sol('sol1').feature('v1').set('clistctrl', {'p1'});
            obj.Model.sol('sol1').feature('v1').set('cname', {'para'});
            obj.Model.sol('sol1').feature('v1').set('clist', {'range(0,istep,istop)'});

            obj.Model.sol('sol1').feature('s1').feature('p1').set('pname', {'para'});
            obj.Model.sol('sol1').feature('s1').feature('p1').set('plistarr', {'range(0,istep,istop)'});
            obj.Model.sol('sol1').feature('s1').feature('p1').set('punit', {''});            
        end
  
        function obj = writeCfg(obj)
            obj.SaveFolder = obj.SaveFolder+sprintf("%03d/", obj.Config);
            mkdir(obj.SaveFolder);
            cfgpath = obj.SaveFolder + "config.csv";
            params=mphgetexpressions(obj.Model.param);
            ptab = cell2table([params(:,1) params(:,4) params(:,3) params(:,2)], ...
                'VariableNames', {'Parameter', 'Value', 'Details', 'Expression'});
            writetable(ptab, cfgpath)
        end
       
        function obj = init(obj)
            obj.readCfg(obj.Config);
            obj.readCfg(0);
            % obj.setCfg;
            % obj.InContact = false;

            % obj.makeContact;
            % obj.writeCfg;
            % obj.setCfg;
            obj.NumWayPoints = size(mphglobal(obj.Model,'istop'), 1);
            obj.WayPoints = zeros(obj.NumWayPoints, 3);
            obj.CurWayPoint = 1;
            obj.SensorSkins = Skin.empty(obj.NumWayPoints, 0);
            obj.Skins = Skin.empty(obj.NumWayPoints, 0);
            obj.FluidPressures = zeros(obj.NumWayPoints, 1);
            obj.ContactPressures = zeros(obj.NumWayPoints, 1);
            obj.SkinHeights = zeros(obj.NumWayPoints, 1);
            
%             obj.DeformedSkin = Skin(obj.Model, obj.BaseSkin);
%             obj.Skins(1) = obj.DeformedSkin;
%             obj.FluidPressures(1) = mphglobal(obj.Model,'Pressure');
%             obj.ContactPressures(1) = mphglobal(obj.Model,'pc');
%             obj.SkinHeights(1) = obj.DeformedSkin.height;           
%             obj.WayPoints(1, :) = id;
%             obj.CurWayPoint = 2;
%             
%             obj.csvWrite;
%             obj.savePlot;              
        end
        
        function [obj, status] = spin(obj)
            status = true;
            try
                obj.Model.study('std1').run
            catch 
                warning('BIOTAC MODEL COMSOL ERROR OCCURED')
                status = false;
            end
        end
        
        function obj = setSkins(obj)
            for i=1:obj.NumWayPoints
                obj.Model.result('pg1').set('looplevel', i);
                obj.Model.result('pg1').run
                obj.SensorSkins(i) = Skin(obj.Model, SensorRay);    
                obj.Skins(i) = Skin(obj.Model, Ray);    

%                 obj.Skins(i) = Skin(obj.Model, Ray);    
                fprintf('loop level: %d\n', i)
            end
        end
        
%         function obj = spinAll(obj)
%             status = true;
%             while(status && obj.CurWayPoint<=obj.NumWayPoints)
%                 [~, status] = obj.spinOnce;
%                 obj.csvWrite;
%                 obj.savePlot;
%             end
%         end

%         function [obj, status] = spinOnce(obj)
%             i = obj.CurWayPoint;
%             obj.Model.param.set('idx', obj.WayPoints(i, 1));
%             obj.Model.param.set('idy', obj.WayPoints(i, 2));
%             obj.Model.param.set('idz', obj.WayPoints(i, 3));
%             status = true;
%             try
%                 obj.Model.study('std1').run
%             catch 
%                 warning('BIOTAC MODEL COMSOL ERROR OCCURED')
%                 status = false;
%                 obj.NumWayPoints = i-1;
%             end
%             obj.DeformedSkin = Skin(obj.Model, obj.BaseSkin);
%             obj.Skins(i) = obj.DeformedSkin;
%             pc = mphglobal(obj.Model,'pc');
%             pf = mphglobal(obj.Model,'Pressure');
%             obj.FluidPressures(i) = pf;
%             obj.ContactPressures(i) = pc;
%             obj.SkinHeights(i) = obj.DeformedSkin.height;
%             fprintf("%02d\t%0.2f\t%0.2f\t%0.2f\n", i, obj.DeformedSkin.height, pc, pf);
%             obj.CurWayPoint = i+1;
%         end
        
        function [obj, status] = makeContact(obj)
            maxd = 0.1;
            low = 0; high = maxd;
            status = true;
            i = 1;
            obj.Model.component('comp1').physics('solid').feature('cnt1').feature('fric1').set('ContactPreviousStep', 'NotInContact');
            while (low+0.01<=high && i<5 && status)
                mid = low + (high-low)/2;
                obj.Model.param.set('isc', mid);            
                try
                    obj.Model.study('std1').run
                catch 
                    warning('makeConatct: ERROR OCCURED')
                    status = false;
                    return;
                end
                pc = mphglobal(obj.Model,'pc');
                fprintf("%02f\t%02f\t%02f\t%0.2f\n", low, mid, high, pc)
                if (pc>0) %% contact happend
                    high = mid;
                else
                    low = mid;
                end
                
%                 if i == 1
%                     obj.BaseSkin = Skin(obj.Model);
%                 end
                i = i+1;
            end
%             obj.BaseSkin = Skin(obj.Model);
            obj.readCfg(obj.Config);
            obj.Model.param.set('isc', mid); 
            obj.Model.component('comp1').physics('solid').feature('cnt1').feature('fric1').set('ContactPreviousStep', 'InContact');
        end
        
        function csvWrite(obj)
            csvwrite(sprintf('%s/taxel_%03d.csv', obj.SaveFolder, ...
                obj.CurWayPoint-1), obj.DeformedSkin.Taxels);
            csvwrite(sprintf('%s/deformed_%03d.csv', obj.SaveFolder, ...
                obj.CurWayPoint-1), obj.DeformedSkin.Deformeds);
        end
        
        function savePlot(obj)
            view_vecs = [[1, 0, 0]; [0, 1, 0]; [0, 0, 1]];
            titles = ["yz", "xz", "xy"];
            
            for i=1:3
                obj.DeformedSkin.plot(figure(i), view_vecs(i,:));
                obj.setTitle;
                obj.saveTitle(figure(i), titles(i));
            end
            for i=1:3
                obj.DeformedSkin.plotCOM(figure(i+3), view_vecs(i,:));
                obj.setTitle;
                obj.saveTitle(figure(i+3), "COM_"+titles(i));
            end
        end
        
        function setTitle(obj)
            i = obj.CurWayPoint-1;
            d = obj.WayPoints(i, :)-obj.WayPoints(1, :);
            sgtitle(strcat("\itd\rm\bfx\rm=", ...
            sprintf("[%0.2f, %0.2f, %0.3f]", d(1), d(2), d(3))));
        end
        
        function saveTitle(obj, fig, title)
            i = obj.CurWayPoint-1;
            saveas(fig, sprintf('%s/%s_%03d.png', obj.SaveFolder, title, i));
            close(fig)
        end
        
        function t = plotSensor(obj)
            taxels = zeros(obj.NumWayPoints, 24);
            for i=1:obj.NumWayPoints
                taxels(i, :) = obj.SensorSkins(i).Taxels(:, 4);
            end
            for i=1:24
                plot(1:obj.NumWayPoints, taxels(:, i));
                hold on 
            end
            t = taxels;
        end
        
        function t = plotSkin(obj)
            np = obj.Skins(1).Ray.numPoints;
            taxels = zeros(obj.NumWayPoints, np);
            for i=1:obj.NumWayPoints
                taxels(i, :) = obj.Skins(i).Taxels(:, 4);
            end
            for i=1:np
                plot(1:obj.NumWayPoints, taxels(:, i));
                hold on 
            end
            t = taxels;
        end
        

        function saveData(obj)
            sensor_taxels = zeros(obj.NumWayPoints, 24);
            np = obj.Skins(1).Ray.numPoints;
            skin_taxels = zeros(obj.NumWayPoints, np);
            for i=1:obj.NumWayPoints
                sensor_taxels(i, :) = obj.SensorSkins(i).Taxels(:, 4);
                skin_taxels(i, :) = obj.Skins(i).Taxels(:, 4);                
            end
            writematrix(sensor_taxels, sprintf('%s/sensor_%03d.csv', ...
                obj.SaveFolder, obj.Config))
            writematrix(skin_taxels, sprintf('%s/skin_%03d.csv', ...
                obj.SaveFolder, obj.Config))
        end
    end
    
    methods(Static)
        function skin = baseSensorSkin(skin)
            persistent Base;
            if nargin
                Base = skin;
            end
            skin = Base;
        end
        function skin = baseHDSkin(skin)
            persistent Base;
            if nargin
                Base = skin;
            end
            skin = Base;
        end
    end
    
end

