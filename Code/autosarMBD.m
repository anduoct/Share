classdef autosarMBD < handle
    properties
        autosar_lib
    end

    methods
        function obj = autosarMBD()
            obj.autosar_lib = load_system([pwd  '\Lib.slx']);
        end

%         function gen_msg(obj)
%             msg_model = new_system('Test');
%             open_system(msg_model)
%             Simulink.SubSystem.copyContentsToBlockDiagram()
%         end

    end

end