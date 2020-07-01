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
        PlaneGap
        Skins
        FluidPressures
        ContactPressures
        SkinHeights
    end
       
    methods
        function obj = Biotac(model)
            %Biotac Construct an instance of this class
            %   Construct an instance of this class

            % Shore A26 for biotac sensor
%             model.param.set('c01', .083);
%             model.param.set('c10', .332);
            % Shore A35 for biotac sensor
%             model.param.set('c01', .032);
%             model.param.set('c10', .125);
            % Shore A26 (linear from A35) for biotac sensor
            model.param.set('c01', .041*26/35);
            model.param.set('c10', .162*26/35);
            obj.Model = model;
%             model.result('pg4').set('title', '');
%             model.result('pg6').feature('arws1').set('scale', '2.0E-4');
            model.param.set('iw', '24');
            model.param.set('il', '16');
            obj.SaveFolder = '/home/bsadrfa/behzad/projects/biotac/comsol/results/';
            obj.planMotion(20, .05);
            obj.PlaneGap = 10;
            obj.init;
        end
        
        function obj = planMotion(obj, N, step, dir)
            if nargin<4
                dir = [0, 0, 1];
            end
            obj.WayPoints = zeros(N,3);
%             obj.WayPoints(:,3)=obj.WayPoints(:,3);
            obj.WayPoints(:,2)=linspace(0, (N-1)*step,N);
            obj.WayPoints(:,3)=1.0;
            obj.NumWayPoints = N;
        end
        
        function obj = init(obj)
            obj.Model.geom('geom1').run();
            obj.Model.mesh('mesh2').run();            
            obj.NumWayPoints = size(obj.WayPoints, 1);
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
%             obj.Model.common('pres1').set('prescribedDeformation', { ...
%             sprintf('%0.2f[mm]', obj.WayPoints(i, 1)), ...
%             sprintf('%0.2f[mm]', obj.WayPoints(i, 2)), ...
%             sprintf('%0.2f[mm]', obj.WayPoints(i, 3))});           
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
            if i == 1
                obj.BaseSkin = Skin(obj.Model);
            end
            obj.DeformedSkin = Skin(obj.Model, obj.BaseSkin);
            obj.Skins(i) = obj.DeformedSkin;
            pc = mphglobal(obj.Model,'pc');
            pf = mphglobal(obj.Model,'Pressure');
            obj.FluidPressures(i) = pf;
            obj.ContactPressures(i) = pc;
            if (pc>0)
                if obj.PlaneGap == 10
                    obj.PlaneGap = obj.WayPoints(i, 3);
                end
            end
            obj.SkinHeights(i) = obj.DeformedSkin.height;
            display(sprintf("%02d\t%0.2f\t%0.2f\t%0.2f", i, obj.DeformedSkin.height, pc, pf));
            obj.CurWayPoint = i+1;
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
            dz = obj.WayPoints(i, 3)-obj.PlaneGap;
            dz = (dz>0) * dz;
            sgtitle(strcat("\itd\rm\bfx\rm=", ...
            sprintf("[%0.2f, %0.2f, %0.3f]", obj.WayPoints(i, 1), ...
            obj.WayPoints(i, 2), dz)))
        end
        
        function saveTitle(obj, fig, title)
            i = obj.CurWayPoint-1;
            saveas(fig, sprintf('%s/%s_%03d.png', obj.SaveFolder, title, i));
            close(fig)
        end

    end
    
end

