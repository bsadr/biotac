classdef Biotac < handle
    %Biotac Manager class for simulating biotac sensor
    %   Manager class for simulating biotac sensor
    
    properties
        Model
        SaveFolder
        BaseSkin
        DeformedSkin

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
        Skins
        FluidPressures
        ContactPressures
        SkinHeights
    end
       
    methods
        function obj = Biotac(model, savefolder)
            %Biotac Construct an instance of this class
            %   Construct an instance of this class

            % Shore A26 (linear from A35) for biotac sensor
            model.param.set('c01', .041*26/35);
            model.param.set('c10', .162*26/35);
            obj.Model = model;
%             model.result('pg4').set('title', '');
%             model.result('pg6').feature('arws1').set('scale', '2.0E-4');
            model.param.set('iw', '24');
            model.param.set('il', '16');
            obj.SaveFolder = '/home/bsadrfa/behzad/projects/biotac/comsol/results/';
            if nargin>1
                obj.SaveFolder = savefolder;
            end
            obj.DirNormal = [0, 0, 1];
            obj.DirTangent = [0, 1, 0];
            obj.Step = 0.1;
            obj.NumWayPoints = 10;
            obj.InContact = false;
            obj.init;
            obj.StrainNormal = 0.5;
%             obj.makeContact;
%             obj.planMotion;
        end
        
        function obj = planMotion(obj, N, step, dir)
            if nargin>1
                obj.NumWayPoints = N;
            end
            if nargin>2
                obj.Step = step;
            end
            if nargin>3
                obj.DirNormal = dir;
            end           
            for i=1:3
                obj.WayPoints(2:end,i) = obj.WayPoints(1, i) + ...
                    obj.DirNormal(i) * obj.StrainNormal + ...
                    linspace(0, ...
                    obj.Step*(obj.NumWayPoints-2)*obj.DirTangent(i), ...
                    obj.NumWayPoints-1);
            end
        end
        
        function obj = init(obj)
            obj.Model.geom('geom1').run();
            obj.Model.mesh('mesh2').run();            
            obj.WayPoints = zeros(obj.NumWayPoints, 3);
            obj.CurWayPoint = 1;
            obj.Skins = Skin.empty(obj.NumWayPoints, 0);
            obj.FluidPressures = zeros(obj.NumWayPoints, 1);
            obj.ContactPressures = zeros(obj.NumWayPoints, 1);
            obj.SkinHeights = zeros(obj.NumWayPoints, 1);
        end
        
        function obj = spinAll(obj)
            status = true;
            while(status && obj.CurWayPoint<=obj.NumWayPoints)
                [~, status] = obj.spinOnce;
                obj.csvWrite;
                obj.savePlot;
            end
        end

        function [obj, status] = spinOnce(obj)
            i = obj.CurWayPoint;
            obj.Model.param.set('idx', obj.WayPoints(i, 1));
            obj.Model.param.set('idy', obj.WayPoints(i, 2));
            obj.Model.param.set('idz', obj.WayPoints(i, 3));
            status = true;
            try
                obj.Model.study('std1').run
            catch 
                warning('BIOTAC MODEL COMSOL ERROR OCCURED')
                status = false;
                obj.NumWayPoints = i-1;
            end
            obj.DeformedSkin = Skin(obj.Model, obj.BaseSkin);
            obj.Skins(i) = obj.DeformedSkin;
            pc = mphglobal(obj.Model,'pc');
            pf = mphglobal(obj.Model,'Pressure');
            obj.FluidPressures(i) = pf;
            obj.ContactPressures(i) = pc;
            obj.SkinHeights(i) = obj.DeformedSkin.height;
            fprintf("%02d\t%0.2f\t%0.2f\t%0.2f\n", i, obj.DeformedSkin.height, pc, pf);
            obj.CurWayPoint = i+1;
        end
        
        function [obj, status] = makeContact(obj)
            maxd = 0.02;
            low = 0; high = maxd;
            status = true;
            i = 1;
            obj.Model.component('comp1').physics('solid').feature('cnt1').feature('fric1').set('ContactPreviousStep', 'NotInContact');
            while (low+0.01<=high && i<10 && status)
                mid = low + (high-low)/2;           
                id = mid*obj.DirNormal;
                obj.Model.param.set('idx', id(1));
                obj.Model.param.set('idy', id(2));
                obj.Model.param.set('idz', id(3));
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
                
                if i == 1
                    obj.BaseSkin = Skin(obj.Model);
                end
                i = i+1;
            end
            obj.Model.component('comp1').physics('solid').feature('cnt1').feature('fric1').set('ContactPreviousStep', 'InContact');
            obj.DeformedSkin = Skin(obj.Model, obj.BaseSkin);
            obj.Skins(1) = obj.DeformedSkin;
            obj.FluidPressures(1) = mphglobal(obj.Model,'Pressure');
            obj.ContactPressures(1) = mphglobal(obj.Model,'pc');
            obj.SkinHeights(1) = obj.DeformedSkin.height;           
            obj.WayPoints(1, :) = id;
            obj.CurWayPoint = 2;
            
            obj.csvWrite;
            obj.savePlot;            
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

    end
    
end

