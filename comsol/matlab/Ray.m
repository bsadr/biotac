classdef Ray < handle
    %Ray class for calcualting rays and coordinates
    %   Ray class for calcualting rays and coordinates (no properties)
      
    methods
        function obj = Ray()
            %Ray Construct an instance of this class
            %   Ray Construct an instance of this class, set raddii sets
            obj.coreRadii([12.42, 8.14, 8.057]);
            % obj.skinRadii([14., 9.74, 9.74]);%should update via base skin
        end       
   
        function uv = xyz_to_uv(obj, xyz) % for skin
            %converts xyz to uv (on the skin)
            %   converts xyz (N x 3) to uv (N x 2)
            eps = 1e-2;
            r = obj.skinRadii;

            c1 = xyz(:,3)/r(3)>1;
            c2 = xyz(:,3)/r(3)<-1;                
            v = c1*1+c2*pi+(1-c1-c2).*acos(xyz(:,3)/r(3));

            u = atan2(r(1)*xyz(:,2), r(2)*xyz(:,1));
%             u = atan2(r(1)*xyz(:,2).*sin(v), r(2)*xyz(:,1).*sin(v));
            u = u + 2*pi*(u < -eps);
            uv0 = double([u, v]);
            
            % fit to exact uv
            % distance from a line
            % https://mathworld.wolfram.com/Point-LineDistance3-Dimensional.html
            f = @(uv_, x2)norm(cross(obj.uv_to_xyz(uv_), x2))/norm(x2);

            for i = 1:size(xyz, 1)
                x2 = xyz(i, 1:3);
                fun = @(uv)f(uv, x2);
                uv_opt = fminsearch(fun, uv0(i, 1:2));
                uv0(i, 1:2) = uv_opt;
            end
            uv = uv0;
        end

        function xyzd = uv_to_xyzd(obj, uv)
            %converts uv to xyzd (on the skin)
            %   converts uv (N x 2) to xyzd (N x 4)
            xyzd = obj.to_xyzd(uv, obj.skinRadii);
        end     
        
        function xyz = uv_to_xyz(obj, uv)
            %converts uv to xyz (on the skin)
            %   converts uv (N x 2) to xyz (N x 3)
            xyz = obj.to_xyz(uv, obj.skinRadii);
        end     
        
        function d =  core_norms(obj, uv)
            %returns ray length (on the core)
            %   converts uv (N x 2) to norm (N x 1)
            xyzd = obj.to_xyzd(uv, obj.coreRadii);
            d = xyzd(:, 4);
        end

        function xyzd = to_xyzd(obj, uv, radii)
            %converts uv to xyzd for radii
            %   converts uv (N x 2) to xyzd (N x 4)
            xyz = obj.to_xyz(uv, radii);
            d = vecnorm(xyz, 2, 2);
            xyzd = [xyz d];                   
        end     
        
        function xyz = to_xyz(~, uv, radii)
            %converts uv to xyz for radii
            %   converts uv (N x 2) to xyz (N x 3)
            r = radii;
            xyz = [r(1)*cos(uv(:,1)).*sin(uv(:,2)), ...
                   r(2)*sin(uv(:,1)).*sin(uv(:,2)), ...
                   r(3)*cos(uv(:,2))];
        end     
        
    end
    
    methods(Static)
        function out = coreRadii(data)
            persistent Radii;
            if nargin
                Radii = data;
            end
            out = Radii;
        end
                
        function out = skinRadii(data)
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
                skin = r.to_xyzd(uv, r.coreRadii);
            elseif isempty(skin)
                r = Ray;
                uv = r.uvGrid();
                skin = r.to_xyzd(uv, r.coreRadii);
            end
            
            out = skin;
        end

    end
    
end

