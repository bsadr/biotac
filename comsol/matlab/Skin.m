classdef Skin < handle
    %Skin class for handling the skin intersection with rays and
    %deformation
    %   The inputs are COMSOL model and an instance of Ray

    
    properties
        Model
        Triangles
        Vertices
        RayIntersects % [x, y, z, d, tri_id, lambda1, lambda2]
        % x, y, z: intersection of ray with the skin cartesian coordinates
        % unit distance of the intersected ray wrt to the ray length
        % d=1 for the skinBase (undeformed skin)
        % tri_id: the id of the triangle that the ray intersected
        % lambda1, lambda2: Barycentric coordinate of the intersected ray
        % on the skin wrt the intersected triangle
        
        Taxels % Taxel Coordinates [ellipsoid(3) imp(1) cartesian(3)]
        Deformeds % Deformed Coordinates [ellipsoid(3) imp(1) cartesian(3)]
        
        Ray %either Ray or SensorRay
    end
    
    methods
        function obj = Skin(model, ray)
            %Skin Construct an instance of this class
            %   Initialize the Triangles, Vertices, and RayIntersects
            %   The base skin (filled skin with no contact) should be set
            %   first

            % load comsol model           
            pd=mphplot(model,'pg1', 'createplot', 'off');
            surface = pd{2}{1};              
            
            % load trianlges and vertices from the surface
            obj.Vertices = surface.p.';
            obj.Triangles =  1+surface.t.';           
            
            % set Ray
            obj.Ray = ray;

            % calculate the intersections
            obj.calcIntersects(ray);
            obj.Model = model;
        end
                
        function vertice = V(obj, vert, coord, tri_ids)
            % getter function for the j-th coordinate i-th vertice
            % example: 
            % Vertice(1): coordinates of the 1st vertices
            % Vertice(1, 2): y coordinates of the 1st vertices
            assert((vert>0) && (vert<=3))
            if nargin == 2
                vertice = obj.Vertices(obj.Triangles(:, vert), :);
            elseif nargin == 3
                assert((coord>0) && (coord<=3))
                vertice = obj.Vertices(obj.Triangles(:, vert), coord);
            else
                vertice = obj.Vertices(obj.Triangles(tri_ids, vert), coord);
            end
        end
        
        function obj = calcIntersects(obj, rays)
            %clacIntersect(skin, ray)
            %   points(N x 7): [intersection point(x, y, z), normal 
            %   distance, triangle numbers, point in triangle in 
            %   Barycentric coordinate system (u, v)]

            % intersect rays
            orig = [0 0 0];
            % intersection points
            grid = rays.skinGrid; % (x, y, z, length_from_org_to_core)
            rays_xyz = grid(:, 1:3);
            points = zeros(size(rays_xyz, 1), 7);

            for i=1:size(rays_xyz)
                [intersect, t, u, v, xcoor] = TriangleRayIntersection( ...
                    orig, rays_xyz(i,:), obj.V(1), obj.V(2), obj.V(3));
                indices = find(intersect);
                normal_distances = t(indices);
                [d, local_idx] = max(normal_distances);
                idx = indices(local_idx);
                try
                    points(i, :) = [xcoor(idx, :), d, idx, u(idx), v(idx)];
                catch
                    disp(idx)
                end
            end 
            obj.RayIntersects = points;
            obj.calcTaxels;
            obj.calcDeformeds;
        end       
        
%         function dif = diffCart(obj)
%             %calcDeformation calculates the deformation of `obj` wrt to
%             %`base`
%             assert !isempty(obj.Base)
%             baseCoords = obj.Base.cartCoords();
%             deformedCoords = obj.cartCoords();
%             dif = baseCoords - deformedCoords;
%         end
        
        function obj = calcTaxels(obj)
            cartcoords = obj.RayIntersects(:, 1:3);
            % set radii of base skin (fitt ellipsoid)
            [base, is_init] = obj.baseSkin();
            if ~ is_init 
                [center, radii, ~, ~, ~] = ellipsoid_fit(cartcoords, '0' );
                fprintf('base radii: %.5g %.5g %.5g\n', radii);
                radii(3) = radii(3) - center(3);
                obj.Ray.skinRadii(radii);
                fprintf('base fitted center: %.5g %.5g %.5g\n', center);
                fprintf('base radii: %.5g %.5g %.5g\n', radii);
            end
            
            ellipcoords = obj.cart_to_ellip(cartcoords); % (uv, norm, imp)
            coords = [ellipcoords, cartcoords];
            % fix triangulation error
            if is_init
                coords(:, 3) = coords(:, 3) ./ base.Taxels(:, 3);
            end
            obj.Taxels = coords;
        end
        
        function obj = calcDeformeds(obj)
            %calcDeformeds calculates the deformed cartesian coordinates
            %of the points found in triangles and thus there is a
            %geometrical error from the point on the ellipsoid to the
            %triangle
            %It calculates the points inside triangles using 
            %the barycentric coordinates of the base triangles and vertices
            %coordinates of the obj triangles; the order of points is from
            %the base
            [base, is_init] = obj.baseSkin();
            if ~ is_init 
                obj.baseSkin(obj);
                base = obj;
            end           
            tris = base.RayIntersects(:, 5);
            l2 = base.RayIntersects(:, 6);
            l3 = base.RayIntersects(:, 7);
            l1 = 1 - l3 - l2;
            cartcoords = [l1.*obj.V(1, 1, tris) + l2.*obj.V(2, 1, tris) ...
                + l3.*obj.V(3, 1, tris), ...
                l1.*obj.V(1, 2, tris) + l2.*obj.V(2, 2, tris) ...
                + l3.*obj.V(3, 2, tris), ...
                l1.*obj.V(1, 3, tris) + l2.*obj.V(2, 3, tris) ...
                + l3.*obj.V(3, 3, tris)];
            ellipcoords = obj.cart_to_ellip(cartcoords);
            % fix triangulation error
            if is_init
                ellipcoords(:, 3) = ellipcoords(:, 3) ./ base.Taxels(:, 3);
            end
            
            obj.Deformeds = [ellipcoords, cartcoords];            
        end
        
               
        function ellip = cart_to_ellip(obj, obj_coords)
            %cart_to_ellip finds the ellipsoid (u,v) coordinates unit length
            %of deformed points represnted in 3d cartesian coordiantes
            r = obj.Ray;
            uv = r.xyz_to_uv(obj_coords);           % uv
            base_coords = r.uv_to_xyzd(uv);         % base skin xyz
            base_norms = base_coords(:, 4);         % base skin norm
            obj_norms = vecnorm(obj_coords, 2, 2);  % obj skin  norm
            core_norms = r.core_norms(uv);          % core norm
            imp = obj_norms-core_norms;             % impedance
            ellip = [uv, obj_norms./base_norms, imp];
        end
        
        % plot functions
        function plot(obj, fig, view_vec)
            limC = [0.86, 1.14];
            if nargin == 1
                fig = figure;
            else
                clf(fig)
                set(fig, 'Visible', 'off');
            end
            if nargin<=2
                view_vec = [1, 0, 0];
            end
            set(fig, 'PaperPositionMode', 'manual');
            set(fig, 'PaperUnits', 'points');
            set(fig, 'PaperPosition', [0 0 921 518]);

            ax1 = subplot(1, 2, 1);
            obj.drawEllip;
            hold on
            colormap(jet)
            % color based on impedance (:,4) sensor
            scatter3(obj.Taxels(:,5), obj.Taxels(:,6), obj.Taxels(:,7), ...
                [], obj.Taxels(:,4), 'filled')
            axis equal
            colorbar('southoutside')
            caxis(ax1, limC)
            view(view_vec)
            ylim([-10.6  10.6])
            xlim([-14.9 14.9])
            zlim([-14.2 0])
            xlabel('x [mm]')
            ylabel('y [mm]')
            zlabel('z [mm]')
            grid off
            title("Taxel Impedance")

            ax2 = subplot(1, 2, 2);
            obj.drawEllip;
            hold on
            colormap(jet)
            % color based on norms (:,3); impedance is not accurate for
            % deformed uv values since the ray has moved to new location
            scatter3(obj.Deformeds(:,5), obj.Deformeds(:,6), obj.Deformeds(:,7), ...
                [], obj.Deformeds(:,3), 'filled')
            axis equal
            colorbar('southoutside')
            caxis(ax2, limC)
            view(view_vec)
            ylim([-10.6  10.6])
            xlim([-14.9 14.9])
            zlim([-14.2 0])
            xlabel('x [mm]')
            ylabel('y [mm]')
            zlabel('z [mm]')
            grid off
            title("Deformation Norms")
        end
        
        function plotCOM(obj, fig, view_vec)

            if nargin == 1
                fig = figure;
            else
                clf(fig)
                set(fig, 'Visible', 'off');
            end
            if nargin<=2
                view_vec = [1, 0, 0];
            end
            set(fig, 'PaperPositionMode', 'manual');
            set(fig, 'PaperUnits', 'points');
            set(fig, 'PaperPosition', [0 0 921 518]);

            for j =1:2
                subplot(1, 2, j);
                mphplot(obj.Model, obj.plotGroup(j), 'rangenum', 1);
                axis equal
                view(view_vec)
                ylim([-10.6  10.6])
                xlim([-14.9 14.9])
                zlim([-14.2 0])
                xlabel('x [mm]')
                ylabel('y [mm]')
                zlabel('z [mm]')
                grid off
                title(obj.plotName(j))
            end
        end

        function triSurf(obj, col)
            trisurf(obj.Triangles, ...
               obj.Vertices(:,1), obj.Vertices(:,2), obj.Vertices(:,3), ...
               'FaceAlpha', 0.5, 'LineStyle', 'none','FaceColor', col)
            axis equal            
        end
        
        % utility functions
        function z = height(obj)
%             z = -min(obj.Vertices(:, 3));
            z = -min(obj.RayIntersects(:, 3));
        end
        
        % test functions
        function out = test_convert_xyz(obj)
            coords2 = obj.RayIntersects(:,1:3);
            r = obj.Ray;
            uv = r.xyz_to_uv(coords2);
            coords1 = r.uv_to_xyzd(uv);
            coords1 = coords1(:,1:3);
            out = [coords2 - coords1 coords2  coords1];
        end
        
        function out = test_convert_uv(obj)
            coords2 = obj.RayIntersects(:,1:3);
            r = obj.Ray;
            uv = r.xyz_to_uv(coords2);
            out = [uv - r.uvGrid uv r.uvGrid];
        end
    end
    
    methods(Static)

        function [skin, is_init] = baseSkin(skin)
            persistent Base;
            is_init =  ~isempty(Base);
            if nargin
                Base = skin;
            end
            skin = Base;
        end
        
        function pltg = plotGroup(i)
            plot_groups = ["pg3", "pg1"];
            pltg = plot_groups(i);
        end
        
        function pltg = plotName(i)
            plot_names = ["contact", "deformation"];
            pltg = plot_names(i);
        end
        
        function drawEllip(color)
            persistent x y z;
            if isempty(x)
                r = Ray.skinRadii;
                [x, y, z] = ellipsoid(0, 0, 0, r(1), r(2), r(3));
                x = x(1:10,:); y = y(1:10,:); z = z(1:10,:);
            end
            if nargin == 0
                color = 'blue';
            end
            surf(x, y, z, 'FaceColor', 'none', 'LineStyle', ':', ...
                'EdgeColor', color)            
        end
    end
end

