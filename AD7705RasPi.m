classdef AD7705RasPi < realtime.internal.SourceSampleTime ...
        & coder.ExternalDependency ...
        & matlab.system.mixin.Propagates ...
        & matlab.system.mixin.CustomIcon
    
    %
    %	AD7705 Driver for Raspberry Pi
    %
    %	Author : Eisuke Matsuzaki
    %	Created on : 07/19/2020
    %	Copyright (c) 2020 d’Arbeloff Lab, MIT Department of Mechanical Engineering
    %	Released under the MIT license
    %
    
    %#codegen
    %#ok<*EMCA>
    
    properties
        % Public, tunable properties.
    end
    
    properties (Nontunable, Logical)
        isCE0 = true; % Enable CE0
        isCE1 = false; % Enable CE1
    end
    
    properties (Nontunable)
        filter = '50 Hz (Master clock 4.9152MHz)'; % Sampling rate
        speed = '500 kHz'; % SPI Bus speed
        ce0Ain = 'AIN1'; % Analog input
        ce1Ain = 'AIN1'; % Analog input
        ce0Calib = 'Normal Mode'; % Calibration
        ce1Calib = 'Normal Mode'; % Calibration
        ce0Gain = '1'; % PGA gain
        ce1Gain = '1'; % PGA gain
        ce0Polar = 'Bipolar'; % Operation 
        ce1Polar = 'Bipolar'; % Operation
        ce0Buffer = 'OFF'; % Buffer
        ce1Buffer = 'OFF'; % Buffer
        ce0ClockDis = 'No operation'; % Clock Disable
        ce1ClockDis = 'No operation'; % Clock Disable 
        ce0ClockDiv = '1 / 1'; % Clock Divider
        ce1ClockDiv = '1 / 1'; % Clock Divider
    end
    
    properties (Constant, Hidden)
        filterSet = matlab.system.StringSet({'20 Hz (Master clock 2MHz)', '25 Hz', '100 Hz', '200 Hz',...
                                             '50 Hz (Master clock 4.9152MHz)', '60 Hz', '250 Hz', '500 Hz'});
        speedSet = matlab.system.StringSet({'500 kHz', '1 MHz', '2 MHz', '4 MHz',...
                                            '8 MHz', '16 MHz', '32 MHz'});
        ce0AinSet = matlab.system.StringSet({'AIN1', 'AIN2'});
        ce1AinSet = matlab.system.StringSet({'AIN1', 'AIN2'});
        ce0CalibSet = matlab.system.StringSet({'Normal Mode', 'Self-Calibration',...
                                               'Zero-Scale System Calibration',...
                                               'Full-Scale System Calibration'});
        ce1CalibSet = matlab.system.StringSet({'Normal Mode', 'Self-Calibration',...
                                               'Zero-Scale System Calibration',...
                                               'Full-Scale System Calibration'});
        ce0GainSet = matlab.system.StringSet({'1', '2', '4', '8', '16', '32', '64', '128'});
        ce1GainSet = matlab.system.StringSet({'1', '2', '4', '8', '16', '32', '64', '128'});
        ce0PolarSet = matlab.system.StringSet({'Bipolar', 'Unipolar'});
        ce1PolarSet = matlab.system.StringSet({'Bipolar', 'Unipolar'});
        ce0BufferSet = matlab.system.StringSet({'OFF', 'ON'});
        ce1BufferSet = matlab.system.StringSet({'OFF', 'ON'});
        ce0ClockDisSet = matlab.system.StringSet({'No operation', 'Disable'});
        ce1ClockDisSet = matlab.system.StringSet({'No operation', 'Disable'});
        ce0ClockDivSet = matlab.system.StringSet({'1 / 1', '1 / 2'});
        ce1ClockDivSet = matlab.system.StringSet({'1 / 1', '1 / 2'});
        outputName = {'CE0', 'CE1'};
        outputType = {'uint16', 'uint16'};        
    end
    
    properties (Access = private)
        filterId = uint8(0);
        speedId = uint16(0);
        ce0AinId = uint8(0);
        ce1AinId = uint8(0);
        ce0CalibId = uint8(0);
        ce1CalibId = uint8(0);
        ce0GainId = uint8(0);
        ce1GainId = uint8(0);
        ce0PolarId = uint8(0);
        ce1PolarId = uint8(0);
        ce0BufferId = uint8(0);
        ce1BufferId = uint8(0);
        ce0ClockDisId = uint8(0);
        ce1ClockDisId = uint8(0);
        ce0ClockDivId = uint8(0);
        ce1ClockDivId = uint8(0);
        filterName = {'20 Hz (Master clock 2MHz)', '25 Hz', '100 Hz', '200 Hz',...
                      '50 Hz (Master clock 4.9152MHz)', '60 Hz', '250 Hz', '500 Hz'};
        samplingVal = double([0.05, 0.04, 0.01, 0.005, 0.02, 0.02, 0.004, 0.002]);
        speedName = {'500 kHz', '1 MHz', '2 MHz', '4 MHz', '8 MHz', '16 MHz', '32 MHz'};
        speedVal = uint16([500000, 1000000, 2000000, 4000000, 8000000, 16000000, 32000000]);
        ainName = {'AIN1', 'AIN2'};
        calibName = {'Normal Mode', 'Self-Calibration',...
                     'Zero-Scale System Calibration', 'Full-Scale System Calibration'};
        gainName = {'1', '2', '4', '8', '16', '32', '64', '128'};
        polarName = {'Bipolar', 'Unipolar'};
        bufferName = {'OFF', 'ON'};
        clockDisName = {'No operation', 'Disable'};
        clockDivName = {'1 / 1', '1 / 2'};
    end
    
    methods
        % Constructor
        function obj = Source(varargin)
            % Support name-value pair arguments when constructing the object.
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods (Access=protected)
        function setupImpl(obj) %#ok<MANU>
            if isempty(coder.target)
                % Place simulation setup code here
            else
                % Call C-function implementing device initialization
                coder.cinclude('ad7705_raspi.h');
                
                for i = 1:length(obj.filterName)
                    if(strcmp(obj.filter, obj.filterName{i}))
                        obj.filterId = uint8(i-1);
                    end
                end
                
                for i = 1:length(obj.speedName)
                    if(strcmp(obj.speed, obj.speedName{i}))
                        obj.speedId = obj.speedVal(i);
                    end
                end
                
                for i = 1:length(obj.ainName)
                    if(strcmp(obj.ce0Ain, obj.ainName{i}))
                        obj.ce0AinId = uint8(i-1);
                    end
                    if(strcmp(obj.ce1Ain, obj.ainName{i}))
                        obj.ce1AinId = uint8(i-1);
                    end
                end
                
                for i = 1:length(obj.calibName)
                    if(strcmp(obj.ce0Calib, obj.calibName{i}))
                        obj.ce0CalibId = uint8(i-1);
                    end
                    if(strcmp(obj.ce1Calib, obj.calibName{i}))
                        obj.ce1CalibId = uint8(i-1);
                    end
                end
                
                for i = 1:length(obj.gainName)
                    if(strcmp(obj.ce0Gain, obj.gainName{i}))
                        obj.ce0GainId = uint8(i-1);
                    end
                    if(strcmp(obj.ce1Gain, obj.gainName{i}))
                        obj.ce1GainId = uint8(i-1);
                    end
                end
                
                for i = 1:length(obj.polarName)
                    if(strcmp(obj.ce0Polar, obj.polarName{i}))
                        obj.ce0PolarId = uint8(i-1);
                    end
                    if(strcmp(obj.ce1Polar, obj.polarName{i}))
                        obj.ce1PolarId = uint8(i-1);
                    end
                end
                
                for i = 1:length(obj.bufferName)
                    if(strcmp(obj.ce0Buffer, obj.bufferName{i}))
                        obj.ce0BufferId = uint8(i-1);
                    end
                    if(strcmp(obj.ce1Buffer, obj.bufferName{i}))
                        obj.ce1BufferId = uint8(i-1);
                    end
                end
                
                for i = 1:length(obj.clockDisName)
                    if(strcmp(obj.ce0ClockDis, obj.clockDisName{i}))
                        obj.ce0ClockDisId = uint8(i-1);
                    end
                    if(strcmp(obj.ce1ClockDis, obj.clockDisName{i}))
                        obj.ce1ClockDisId = uint8(i-1);
                    end
                end
                
                for i = 1:length(obj.clockDivName)
                    if(strcmp(obj.ce0ClockDiv, obj.clockDivName{i}))
                        obj.ce0ClockDivId = uint8(i-1);
                    end
                    if(strcmp(obj.ce1ClockDiv, obj.clockDivName{i}))
                        obj.ce1ClockDivId = uint8(i-1);
                    end
                end
                
                settings = struct('filter', obj.filterId,...
                                  'speed', obj.speedId,...
                                  'ce', uint8([obj.isCE0, obj.isCE1]),...
                                  'ain', uint8([obj.ce0AinId, obj.ce1AinId]),...
                                  'calib', uint8([obj.ce0CalibId, obj.ce1CalibId]),...
                                  'gain', uint8([obj.ce0GainId, obj.ce1GainId]),...
                                  'polar', uint8([obj.ce0PolarId, obj.ce1PolarId]),...
                                  'buffer', uint8([obj.ce0BufferId, obj.ce1BufferId]),...
                                  'clockDis' ,uint8([obj.ce0ClockDisId, obj.ce1ClockDisId]),...
                                  'clockDiv' ,uint8([obj.ce0ClockDivId, obj.ce1ClockDivId]));
                
                coder.cstructname(settings, 'struct Settings', 'extern', 'HeaderFile', 'ad7705_raspi.h');
                coder.ceval('initialize', coder.ref(settings));
            end
        end
        
        function varargout = stepImpl(obj,u)  %#ok<INUSD>
            if isempty(coder.target)
                % Place simulation output code here 
            else
                % Call C-function implementing device output
                data = struct('ce0ain', uint16(0),...
                              'ce1ain', uint16(0));
                
                coder.cstructname(data, 'struct Data', 'extern', 'HeaderFile', 'ad7705_raspi.h');
                coder.ceval('step', coder.ref(data));
                
                varargout{1} = data.ce0ain;
                varargout{2} = data.ce1ain;
            end
        end
        
        function releaseImpl(obj) %#ok<MANU>
            if isempty(coder.target)
                % Place simulation termination code here
            else
                % Call C-function implementing device termination
                coder.ceval('terminate');
            end
        end
        
        function index = getOutputIndex(obj)
            index = [obj.isCE0, obj.isCE1];
        end
    end
    
    methods (Access=protected)
        %% Define input properties
        function num = getNumInputsImpl(~)
            num = 0;
        end
        
        function num = getNumOutputsImpl(obj)
            num = sum(getOutputIndex(obj));
        end
        
        function flag = isOutputSizeLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputFixedSizeImpl(obj,~)
            for i = 1:sum(getOutputIndex(obj))
                varargout{i} = true;
            end
        end
        
        function flag = isOutputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputComplexImpl(obj)
            for i = 1:sum(getOutputIndex(obj))
                varargout{i} = false;
            end
        end
        
        function varargout = getOutputSizeImpl(obj)
            for i = 1:sum(getOutputIndex(obj))
                varargout{i} = [1, 1];
            end
        end
        
        function varargout = getOutputDataTypeImpl(obj)
            index = getOutputIndex(obj);
            j = 1;
            for i = 1:length(index)
                if index(i)
                    varargout{j} = obj.outputType{i};
                    j = j + 1;
                end
            end
        end
        
        function icon = getIconImpl(obj)
            % Define a string as the icon for the System block in Simulink.
            text1 = 'CE0 : Disable';
            text2 = 'CE1 : Disable';
            if obj.isCE0
                text1 = ['CE0 : ', obj.ce0Ain];
            end
            if obj.isCE1
                text2 = ['CE1 : ', obj.ce1Ain];
            end
                
            icon = {'AD7705', '', text1, text2};
        end
        
        function sts = getSampleTimeImpl(obj)
            samplingTime = 0.1;
            for i = 1:length(obj.filterName)
                if(strcmp(obj.filter, obj.filterName{i}))
                    samplingTime = obj.samplingVal(i);
                end
            end
            sts = createSampleTime(obj, 'Type', 'Discrete', 'SampleTime', samplingTime);
        end
        
        function varargout = getOutputNamesImpl(obj)
            index = getOutputIndex(obj);
            j = 1;
            for i = 1:length(index)
                if index(i)
                    varargout{j} = obj.outputName{i};
                    j = j + 1;
                end
            end
        end
    end
    
    methods (Static, Access=protected)
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
        
        function header = getHeaderImpl
            % Define header panel for System block dialog
           header = matlab.system.display.Header(...
               mfilename('class'), 'Title', AD7705RasPi.getDescriptiveName());
        end
        
        function groups = getPropertyGroupsImpl()
           configGroup = matlab.system.display.Section(...
               'Title', 'General configuration', 'PropertyList', {'filter', 'speed'});
           ce0Group1 = matlab.system.display.Section(...
               'Title', 'Channel', 'PropertyList', {'isCE0', 'ce0Ain'});
           ce0Group2 = matlab.system.display.Section(...
               'Title', 'Setup', 'PropertyList', {'ce0Calib', 'ce0Gain', 'ce0Polar', 'ce0Buffer'});
           ce0Group3 = matlab.system.display.Section(...
               'Title', 'Clock', 'PropertyList', {'ce0ClockDis', 'ce0ClockDiv'});
           ce0Group = matlab.system.display.SectionGroup(...
               'Title', 'SPI0/CE0', 'Sections', [ce0Group1, ce0Group2, ce0Group3]);
           ce1Group1 = matlab.system.display.Section(...
               'Title', 'Channel', 'PropertyList', {'isCE1', 'ce1Ain'});
           ce1Group2 = matlab.system.display.Section(...
               'Title', 'Setup', 'PropertyList', {'ce1Calib', 'ce1Gain', 'ce1Polar', 'ce1Buffer'});
           ce1Group3 = matlab.system.display.Section(...
               'Title', 'Clock', 'PropertyList', {'ce1ClockDis', 'ce1ClockDiv'});
           ce1Group = matlab.system.display.SectionGroup(...
               'Title', 'SPI0/CE1', 'Sections', [ce1Group1, ce1Group2, ce1Group3]);
           groups = [configGroup, ce0Group, ce1Group];
        end
        
        function flag = isInactivePropertyImpl(obj, propertyName)
            if strcmp(propertyName, 'ce0Ain')
                flag = ~obj.isCE0;
            elseif strcmp(propertyName, 'ce0Calib')
                flag = ~obj.isCE0;
            elseif strcmp(propertyName, 'ce0Gain')
                flag = ~obj.isCE0;
            elseif strcmp(propertyName, 'ce0Polar')
                flag = ~obj.isCE0;
            elseif strcmp(propertyName, 'ce0Buffer')
                flag = ~obj.isCE0;
            elseif strcmp(propertyName, 'ce0ClockDiv')
                flag = ~obj.isCE0;
            elseif strcmp(propertyName, 'ce0ClockDis')
                flag = ~obj.isCE0;
            elseif strcmp(propertyName, 'ce1Ain')
                flag = ~obj.isCE1;
            elseif strcmp(propertyName, 'ce1Calib')
                flag = ~obj.isCE1;
            elseif strcmp(propertyName, 'ce1Gain')
                flag = ~obj.isCE1;
            elseif strcmp(propertyName, 'ce1Polar')
                flag = ~obj.isCE1;
            elseif strcmp(propertyName, 'ce1Buffer')
                flag = ~obj.isCE1;
            elseif strcmp(propertyName, 'ce1ClockDiv')
                flag = ~obj.isCE1;
            elseif strcmp(propertyName, 'ce1ClockDis')
                flag = ~obj.isCE1;
            else
                flag = false;
            end
        end
    end
    
    methods (Static)
        function name = getDescriptiveName()
            name = 'AD7705RasPi';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                % Update buildInfo
                srcDir = fullfile(fileparts(mfilename('fullpath')),'src'); %#ok<NASGU>
                includeDir = fullfile(fileparts(mfilename('fullpath')),'include');
                addIncludePaths(buildInfo,includeDir);
                % Use the following API's to add include files, sources and
                % linker flags
                addSourceFiles(buildInfo,'ad7705_raspi.c', srcDir);
                addLinkFlags(buildInfo,'-lwiringPi');
            end
        end
    end
end
