classdef Ray < handle
    %Ray class for calcualting rays and coordinates
    %   Ray class for calcualting rays and coordinates (no properties)
    
    properties
        % Sensor xyz and uv values (24 impedance sensors)
        XYZ
        UV
    end
    
    methods
        function obj = Ray(location_path)
            %Ray Construct an instance of this class
            %   Ray Construct an instance of this class, set the raddii
            obj.radii([12.42, 8.14, 8.057]);
            % skin radii: [14., 9.74, 9.74]
            % core radii: [12.42, 8.14, 8.057]
            
            if nargin == 1
                t = readtable(location_path);
                % four locations on a flat surface (21...24)
                % four excitation electrodes; (-4...-1)
                obj.XYZ = [t.(2) t.(3) t.(4)];
                obj.UV = [t.(9) t.(10)];
                % % find exact uv values for locations
                % obj.UV = obj.xyz_to_uv(obj.XYZ);
                % obj.fitSensor();                
                obj.showSensor();
            end
        end       
   
        function uv = xyz_to_uv(obj, xyz)
            %converts xyz to uv
            %   converts xyz (N x 3) to uv (N x 2)
            eps = 1e-2;
            r = obj.radii;

            c1 = xyz(:,3)/r(3)>1;
            c2 = xyz(:,3)/r(3)<-1;                
            v = c1*1+c2*pi+(1-c1-c2).*acos(xyz(:,3)/r(3));

            u = atan2(r(1)*xyz(:,2), r(2)*xyz(:,1));
%             u = atan2(r(1)*xyz(:,2).*sin(v), r(2)*xyz(:,1).*sin(v));
            u = u + 2*pi*(u < -eps);
            uv = [u, v];
        end

        function xyz = uv_to_xyz(obj, uv)
            %converts uv to xyz
            %   converts uv (N x 2) to xyz (N x 3)
            r = obj.radii;
            xyz = [r(1)*cos(uv(:,1)).*sin(uv(:,2)), ...
                   r(2)*sin(uv(:,1)).*sin(uv(:,2)), ...
                   r(3)*cos(uv(:,2))];
        end     
        
        function obj = fitSensor(obj)
            % distance from a line
            % https://mathworld.wolfram.com/Point-LineDistance3-Dimensional.html
            f = @(uv, x2)norm(cross(obj.uv_to_xyz(uv), x2))/norm(x2);
            
            for i = 1:size(obj.XYZ, 1)
                x2 = obj.XYZ(i, 1:3);
                fun = @(uv)f(uv, x2);
                uv0 = obj.UV(i, 1:2);
                uv = fminsearch(fun, uv0);
                obj.UV(i, 1:2) = uv;
            end
        end
        
        function showSensor(obj)
            % Visualization function to inspect the sensor locations
            xyz = obj.uv_to_xyz(obj.UV);
            figure,
            plot3(obj.XYZ(:,1), obj.XYZ(:,2), obj.XYZ(:,3), '.r' );
            hold on;
            plot3(xyz(:,1), xyz(:,2), xyz(:,3), '+b' );
            for i = 1:size(obj.XYZ, 1)
                text(obj.XYZ(i,1), obj.XYZ(i,2), obj.XYZ(i,3), sprintf("%d", i));
                text(xyz(i,1), xyz(i,2), xyz(i,3), sprintf("%d", i));
            end
            axis equal
            ylim([-10.6  10.6])
            xlim([-14.9 14.9])
            zlim([-14.2 0])
            xlabel('x [mm]')
            ylabel('y [mm]')
            zlabel('z [mm]')
            view( 0, 90 );      
        end
        
    end
    
    methods(Static)
        function out = radii(data)
            persistent Radii;
            if nargin
                Radii = data;
            end
            out = Radii;
        end
                
        function out = uvGrid(n, offset)
            persistent uv;
            if nargin
                eps =  1e-3;
%                 u = linspace(pi, 2*pi-pi/n, n);
%                 v = linspace(pi/2+offset, 3*pi/2-offset, 2*n);  
                u = linspace(0, 2*pi*(1-1/n), n);
                v = linspace(pi/2+offset, pi-eps, n*1/2);
                [gu, gv] = meshgrid(u, v);
                uv = [reshape(gu, [],1) reshape(gv,[],1)];
            end
            if isempty(uv)
                error('Error, first use\n uvGrid(n, offset)')
            end
            out = uv;
        end
            
        function out = skinGrid(n, offset)
            persistent skin;
            if nargin               
                r = Ray;
                uv = r.uvGrid(n, offset);
                skin = r.uv_to_xyz(uv);
            elseif isempty(skin)
                r = Ray;
                uv = r.uvGrid();
                skin = r.uv_to_xyz(uv);
            end
            
            out = skin;
        end

    end
    
end

