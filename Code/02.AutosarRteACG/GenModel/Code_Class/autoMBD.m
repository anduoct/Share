classdef autoMBD < handle
    properties
        ram_sht_tbl
        rom_sht_tbl
    end

    methods
        function obj = autoMBD(ram_sht_tbl, rom_sht_tbl)
            obj.ram_sht_tbl = ram_sht_tbl;
            obj.rom_sht_tbl = rom_sht_tbl;
        end

        function clear_all(~)
            Simulink.data.dictionary.closeAll('-discard');
            bdclose all
            clc
            clear
        end

        function modify_port_line_name(~, port_dire, subsystem_path, ori_name, dst_name)
            %% 修改 Port Name
            set_param([subsystem_path '/' ori_name], 'Name', dst_name);
            %% 连线上若存在 Port 名则同步修改
            if strcmp(port_dire, 'In')
                line_handle = get_param([subsystem_path '/' dst_name], 'LineHandles').Outport;
            elseif strcmp(port_dire, 'Out')
                line_handle = get_param([subsystem_path '/' dst_name], 'LineHandles').Inport;
            end
            if get_param(line_handle, 'Name')
                set_param(line_handle, 'Name', dst_name);
            end
        end

        function add_subsystem_port(obj, subsystem_path)
            %% 添加 subsystem inport
            obj.add_subsystem_inport(subsystem_path)
            %% 添加 subsystem outport
            obj.add_subsystem_outport(subsystem_path)
        end

        function add_subsystem_inport(~, subsystem_path)
            parent_path = get_param(subsystem_path, 'Parent');
            subsystem_name = get_param(subsystem_path, 'Name');
            inport_names = get_param(find_system(subsystem_path, 'SearchDepth', 1, 'BlockType', 'Inport'), 'Name');
            in_handles = get_param(subsystem_path, 'PortHandles').Inport;
            for i_in = 1:length(in_handles)
                in_hdl = get_param(subsystem_path, 'PortHandles').Inport(i_in);
                if get_param(in_hdl, 'Line') == -1
                    in_pos = get_param(in_hdl, 'Position');
                    inport_pos =  [in_pos(1)-200, in_pos(2)-7, in_pos(1)-170, in_pos(2)+7];
                    if isempty(find_system(parent_path,'SearchDepth', 1, 'BlockType', 'Inport', 'Name', inport_names{i_in}))
                        add_block('simulink/Sources/In1', [parent_path '/' inport_names{i_in}], 'Name', inport_names{i_in}, 'Position', inport_pos)
                    end
                    add_line(parent_path, [inport_names{i_in} '/1'], [subsystem_name '/' num2str(i_in)], 'autorouting','on');     
                end
            end
        end

        function add_subsystem_outport(~, subsystem_path)
            parent_path = get_param(subsystem_path, 'Parent');
            subsystem_name = get_param(subsystem_path, 'Name');
            outport_names = get_param(find_system(subsystem_path, 'SearchDepth', 1, 'BlockType', 'Outport'), 'Name');
            out_handles = get_param(subsystem_path, 'PortHandles').Outport;
            for i_out = 1:length(out_handles)
                out_hdl = get_param(subsystem_path, 'PortHandles').Outport(i_out);
                if get_param(out_hdl, 'Line') == -1
                    out_pos = get_param(out_hdl, 'Position');
                    outport_pos =  [out_pos(1)+170, out_pos(2)-7, out_pos(1)+200, out_pos(2)+7];
                    add_block('simulink/Sinks/Out1', [parent_path '/' outport_names{i_out}], 'Name',outport_names{i_out},'Position', outport_pos)
                    add_line(parent_path, [subsystem_name '/' num2str(i_out)], [outport_names{i_out} '/1'], 'autorouting','on');
                end
            end
        end

        function add_subsystem_merge_outport(~, subsystem1_path, subsystem2_path)
            parent_path = get_param(subsystem1_path, 'Parent');
            sub1_port_hdl = get_param(subsystem1_path, 'PortHandles').Outport;
            sub2_port_hdl = get_param(subsystem2_path, 'PortHandles').Outport;
            outport_names = get_param(find_system({subsystem1_path, subsystem2_path}, 'SearchDepth', 1, 'BlockType', 'Outport'), 'Name');
            [~,diff_idx] = unique(outport_names, "stable");
            outport_names(diff_idx) = [];
            for i_port = 1:length(outport_names)
                sub1_port_cell = get_param([subsystem1_path '/' outport_names{i_port}], 'Port');
                sub1_port_num = str2double(sub1_port_cell);
                sub1_port_pos = get_param(sub1_port_hdl(sub1_port_num), 'Position');
                sub2_port_cell = get_param([subsystem2_path '/' outport_names{i_port}], 'Port');
                sub2_port_num = str2double(sub2_port_cell);
                merge_pos = [sub1_port_pos(1)+100, sub1_port_pos(2)-10, sub1_port_pos(1)+140, sub1_port_pos(2)+30];
                merge_hdl = add_block('simulink/Signal Routing/Merge', [parent_path '/Merge' ], 'MakeNameUnique', 'on', 'Position', merge_pos);
                merge_port_hdl = get_param(merge_hdl, 'PortHandles');
                add_line(parent_path, sub1_port_hdl(sub1_port_num), merge_port_hdl.Inport(1), 'autorouting','on');
                add_line(parent_path, sub2_port_hdl(sub2_port_num), merge_port_hdl.Inport(2), 'autorouting','on');
                merge_port_pos = get_param(get_param(merge_hdl, 'PortHandles').Outport(1), 'Position');
                outport_pos =  [merge_port_pos(1)+100, merge_port_pos(2)-7, merge_port_pos(1)+130, merge_port_pos(2)+7];
                outport_hdl = add_block('simulink/Sinks/Out1', [parent_path '/' outport_names{i_port}], 'Name',outport_names{i_port},'Position', outport_pos);
                outport_port_hdl = get_param(outport_hdl, 'PortHandles');
                add_line(parent_path, merge_port_hdl.Outport(1), outport_port_hdl.Inport(1));
            end
        end

        function add_line_between_subsystem(~, subsystem1_path, subsystem2_path)
            parent_path = get_param(subsystem1_path, 'Parent');
            subsystem1_name = get_param(subsystem1_path, 'Name');
            subsystem2_name = get_param(subsystem2_path, 'Name');
            outport_names = get_param(find_system(subsystem1_path, 'SearchDepth', 1, 'BlockType', 'Outport'), 'Name');
            inport_names = get_param(find_system(subsystem2_path, 'SearchDepth', 1, 'BlockType', 'Inport'), 'Name');
            intersect_names = intersect(outport_names, inport_names);
            for i_inter = 1:length(intersect_names)
                out_num = get_param([subsystem1_path '/' intersect_names{i_inter}], 'Port');
                in_num  = get_param([subsystem2_path '/' intersect_names{i_inter}], 'Port');
                add_line(parent_path, [subsystem1_name '/' out_num], [subsystem2_name '/' in_num], 'autorouting','on');
            end

        end

        function modify_model_config(~, model_name, sldd_name)
            sldd_cfg = Simulink.ConfigSetRef;
            set_param(sldd_cfg, 'Name', sldd_name, 'SourceName', sldd_name)
            attachConfigSet(model_name, sldd_cfg);
            setActiveConfigSet(model_name, sldd_name);
        end

        function add_subsystem_port_resolve(obj, subsystem_path, design_data)
            obj.add_inport_dd_resolve_on_line(subsystem_path, design_data, 'ExportedGlobal');
            obj.add_outport_dd_resolve_on_port(subsystem_path, design_data, 'ExportedGlobal');
        end

        function add_inport_dd_resolve_on_line(obj, subsystem_path, design_data, storage_class)
            inport_path_list = find_system(subsystem_path, 'SearchDepth', 1, 'BlockType', 'Inport');
            inport_name_list = get_param(inport_path_list, 'NAME');
            inport_line_hdls = get_param(inport_path_list, 'LineHandles');
            for i_hdl = 1:length(inport_line_hdls)
                sig_name = inport_name_list{i_hdl};
                if ~ismember(sig_name, obj.ram_sht_tbl.Row)
                    continue
                end
                inter_name = obj.ram_sht_tbl.Label(sig_name);
                set_param(inport_line_hdls{i_hdl}.Outport, 'Name', inter_name);
                set(inport_line_hdls{i_hdl}.Outport, 'MustResolveToSignalObject', 1);
                obj.add_dd_signal_to_sldd(sig_name,  design_data, storage_class);
            end
        end

        function add_outport_dd_resolve_on_line(obj, subsystem_path,  design_data, storage_class)
            outport_path_list = find_system(subsystem_path, 'SearchDepth', 1, 'BlockType', 'Outport');
            outport_name_list = get_param(outport_path_list, 'NAME');
            outport_line_hdls = get_param(outport_path_list, 'LineHandles');
            for i_hdl = 1:length(outport_line_hdls)
                sig_name = outport_name_list{i_hdl};
                if ~ismember(sig_name, obj.ram_sht_tbl.Row)
                    continue
                end
                inter_name = obj.ram_sht_tbl.Label(sig_name);
                set_param(outport_line_hdls{i_hdl}.Inport, 'Name', inter_name);
                set(outport_line_hdls{i_hdl}.Inport, 'MustResolveToSignalObject', 1);
                obj.add_dd_signal_to_sldd(sig_name, design_data, storage_class);
            end
        end

        function add_outport_dd_resolve_on_port(obj, subsystem_path, design_data, storage_class)
            outport_path_list = find_system(subsystem_path, 'SearchDepth', 1, 'BlockType', 'Outport');
            outport_name_list = get_param(outport_path_list, 'NAME');
            for i_hdl = 1:length(outport_path_list)
                sig_name = outport_name_list{i_hdl};
                if ~ismember(sig_name, obj.ram_sht_tbl.Row)
                    continue
                end
                inter_name = obj.ram_sht_tbl.Label(sig_name);
                set_param(outport_path_list{i_hdl}, 'SignalName', inter_name);
                hdl = get_param(outport_path_list{i_hdl}, 'Handle');
                set(hdl, 'MustResolveToSignalObject', 1);
                obj.add_dd_signal_to_sldd(sig_name, design_data, storage_class);
            end
        end

        function add_dd_signal_to_sldd(obj, signal_name, design_data, storage_class)
            sig = Simulink.Signal;
            sig.CoderInfo.StorageClass = storage_class;
            sig_info = obj.ram_sht_tbl(signal_name,:);
            inter_name = sig_info.Label;
            if strcmp(sig_info.Attribute, "UB")
                sig.DataType = strcat("fixdt(0, 8, ", sig_info.numerator , "/" , sig_info.denominator, ")");
            elseif strcmp(sig_info.Attribute, "UW")
                sig.DataType = strcat("fixdt(0, 16, ", sig_info.numerator , "/" , sig_info.denominator, ")");
            elseif strcmp(sig_info.Attribute, "UD")
                sig.DataType = strcat("fixdt(0, 32, ", sig_info.numerator , "/" , sig_info.denominator, ")");
            elseif strcmp(sig_info.Attribute, "SB")
                sig.DataType = strcat("fixdt(1, 8, ", sig_info.numerator , "/" , sig_info.denominator, ")");
            elseif strcmp(sig_info.Attribute, "SW")
                sig.DataType = strcat("fixdt(1, 16, ", sig_info.numerator , "/" , sig_info.denominator, ")");
            elseif strcmp(sig_info.Attribute, "SD")
                sig.DataType = strcat("fixdt(1, 32, ", sig_info.numerator , "/" , sig_info.denominator, ")");
            end
            % sig.Max = str2double(sig_info.("Max（Internal）"));
            % sig.Min = str2double(sig_info.("Min（Internal）"));
            addEntry(design_data, inter_name, sig)
        end


        function add_outport_canframe_resolve_on_line(obj, subsystem_path, caninfo, design_data, storage_class)
            outport_path_list = find_system(subsystem_path, 'SearchDepth', 1, 'BlockType', 'Outport');
            outport_name_list = get_param(outport_path_list, 'NAME');
            outport_line_hdls = get_param(outport_path_list, 'LineHandles');
            for i_hdl = 1:length(outport_line_hdls)
                outport_name = outport_name_list{i_hdl};
                [is_member, pos] = ismember(outport_name, caninfo.Input);
                if ~is_member
                    continue
                else
                    sig_name = caninfo.Row{pos};
                end
                set_param(outport_line_hdls{i_hdl}.Inport, 'Name', outport_name);
                set(outport_line_hdls{i_hdl}.Inport, 'MustResolveToSignalObject', 1);
                obj.add_canframe_signal_to_sldd(sig_name, caninfo, design_data, storage_class);
            end
        end

        function add_canframe_signal_to_sldd(~, signal_name, caninfo, design_data, storage_class)
            sig = Simulink.Signal;
            sig.CoderInfo.StorageClass = storage_class;
            sig_info = caninfo(signal_name,:);
            if str2double(sig_info.Min) < 0
                sign_flag = "1";
            else
                sign_flag = "0";
            end
            sig.DataType = strcat("fixdt(",sign_flag,",",sig_info.Length,",",sig_info.Factor,",",sig_info.Offset,")");
            % sig.Max = str2double(sig_info.Max);
            % sig.Min = str2double(sig_info.Min);
            outport_name = sig_info.Input{1};
            addEntry(design_data, outport_name, sig)
        end


        function add_parameter_to_sldd(obj, caninfo, design_data, storage_class)
            for i_sig = 1:length(caninfo.Row)
                param_name = caninfo.('Error Indicator Value'){i_sig};
                param_info = obj.rom_sht_tbl(param_name,:);
                param = Simulink.Parameter;
                param.CoderInfo.StorageClass = storage_class;
                if strcmp(param_info.Attribute, "UB")
                    param.DataType = strcat("fixdt(0, 8, ", param_info.numerator , "/" , param_info.denominator, ")");
                elseif strcmp(param_info.Attribute, "UW")
                    param.DataType = strcat("fixdt(0, 16, ", param_info.numerator , "/" , param_info.denominator, ")");
                elseif strcmp(param_info.Attribute, "UD")
                    param.DataType = strcat("fixdt(0, 32, ", param_info.numerator , "/" , param_info.denominator, ")");
                elseif strcmp(param_info.Attribute, "SB")
                    param.DataType = strcat("fixdt(1, 8, ", param_info.numerator , "/" , param_info.denominator, ")");
                elseif strcmp(param_info.Attribute, "SW")
                    param.DataType = strcat("fixdt(1, 16, ", param_info.numerator , "/" , param_info.denominator, ")");
                elseif strcmp(param_info.Attribute, "SD")
                    param.DataType = strcat("fixdt(1, 32, ", param_info.numerator , "/" , param_info.denominator, ")");
                end
                param.Value = str2double(param_info.('Initial（Internal）'));
                addEntry(design_data, param_name, param)
            end
        end
    end
end