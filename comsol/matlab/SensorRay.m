classdef SensorRay < Ray
    %Ray class for loading rays of the sensor (24 locations)
    %   Ray class for calling rays and coordinates (no properties)
      
    methods
        function obj = SensorRay()
        end       
    end
    
    methods(Static)                             
        function out = uvGrid()
            persistent uv;          
            if isempty(uv)
                t = readtable('3dmodels/locations.csv');
                % four locations on a flat surface (21...24)
                % four excitation electrodes; (-4...-1)
                uv = [t.(9) t.(10)];
                uv(25:end, :) = [];               
            end
            out = uv;
        end        
        function out = skinGrid()
            persistent skin;
            if isempty(skin) 
                t = readtable('3dmodels/locations.csv');
                XYZ = [t.(2) t.(3) t.(4)];                
                XYZ(25:end, :) = [];
                D = vecnorm(XYZ, 2, 2);
                skin = [XYZ D];                   
            end           
            out = skin;
        end
    end   
end

