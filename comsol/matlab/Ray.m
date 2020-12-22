classdef Ray < handle
    %Ray class for calcualting rays and coordinates
    %   Ray class for calcualting rays and coordinates (no properties)
      
    methods
        function obj = Ray()
            %Ray Construct an instance of this class
            %   Ray Construct an instance of this class, set the raddii
            obj.radii([12.42, 8.14, 8.057]);
            % skin radii: [14., 9.74, 9.74]
            % core radii: [12.42, 8.14, 8.057]           
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
            % TODO : Calc length of rays to core (D)
            persistent skin;
            if nargin               
                r = Ray;
                uv = r.uvGrid(n, offset);
                XYZ = r.uv_to_xyz(uv);
                D = vecnorm(XYZ, 2, 2);
                skin = [XYZ D];                   
            elseif isempty(skin)
                r = Ray;
                uv = r.uvGrid();
                XYZ = r.uv_to_xyz(uv);
                D = vecnorm(XYZ, 2, 2);
                skin = [XYZ D];                   
            end
            
            out = skin;
        end

    end
    
end

