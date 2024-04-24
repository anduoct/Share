classdef autoMBD < handle
    properties
        dd_sht_tbl
    end

    methods
        function obj = autoMBD(dd_sht_tbl)
            obj.dd_sht_tbl = dd_sht_tbl;
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

        function modify_model_config(~, model_name, sldd_name)
            sldd_cfg = Simulink.ConfigSetRef;
            set_param(sldd_cfg, 'Name', sldd_name, 'SourceName', sldd_name)
            attachConfigSet(model_name, sldd_cfg);
            setActiveConfigSet(model_name, sldd_name);
        end

        function add_subsystem_port_resolve(obj, subsystem_path, can_info, design_data)
            obj.add_inport_resolve_on_line(subsystem_path, can_info, design_data);
            obj.add_outport_resolve_on_port(subsystem_path, can_info, design_data);
        end

        function add_inport_resolve_on_line(obj, subsystem_path, can_info, design_data)
            inport_path_list = find_system(subsystem_path, 'SearchDepth', 1, 'BlockType', 'Inport');
            inport_name_list = get_param(inport_path_list, 'NAME');
            inport_line_hdls = get_param(inport_path_list, 'LineHandles');
            for i_hdl = 1:length(inport_line_hdls)
                set_param(inport_line_hdls{i_hdl}.Outport, 'Name', inport_name_list{i_hdl});
                set(inport_line_hdls{i_hdl}.Outport, 'MustResolveToSignalObject', 1);
                obj.add_signal_to_sldd(inport_name_list{i_hdl}, can_info, design_data);
            end
        end

        function add_outport_resolve_on_line(obj, subsystem_path, can_info, design_data)
            outport_path_list = find_system(subsystem_path, 'SearchDepth', 1, 'BlockType', 'Outport');
            outport_name_list = get_param(outport_path_list, 'NAME');
            outport_line_hdls = get_param(outport_path_list, 'LineHandles');
            for i_hdl = 1:length(outport_line_hdls)
                set_param(outport_line_hdls{i_hdl}.Inport, 'Name', outport_name_list{i_hdl});
                set(outport_line_hdls{i_hdl}.Inport, 'MustResolveToSignalObject', 1);
                obj.add_signal_to_sldd(outport_name_list{i_hdl}, can_info, design_data);
            end
        end

        function add_outport_resolve_on_port(obj, subsystem_path, can_info, design_data)
            outport_path_list = find_system(subsystem_path, 'SearchDepth', 1, 'BlockType', 'Outport');
            outport_name_list = get_param(outport_path_list, 'NAME');
            for i_hdl = 1:length(outport_path_list)
                set_param(outport_path_list{i_hdl}, 'SignalName', outport_name_list{i_hdl});
                hdl = get_param(outport_path_list{i_hdl}, 'Handle');
                set(hdl, 'MustResolveToSignalObject', 1);
                obj.add_signal_to_sldd(outport_name_list{i_hdl}, can_info, design_data);
            end
        end

        function add_signal_to_sldd(obj, signal_name, can_info, design_data)
            sig = Simulink.Signal;
            sig.CoderInfo.StorageClass = "ExportedGlobal";
            sig_info = obj.dd_sht_tbl(signal_name,:);
%             strcmp(signal_name(1:6), "CanTx_") || strcmp(signal_name(1:6), "CanRx_")
            if strcmp(sig_info.Resolution, "1")
                sig.DataType = sig_info.Attribute;
            else
                tx_info = can_info(signal_name,:);
                if strcmp(sig_info.Attribute, "UB")
                    sig.DataType = strcat("fixdt(0, 8, ", sig_info.numerator , "/" , sig_info.denominator, ", ", tx_info.Offset, ")");
                elseif strcmp(sig_info.Attribute, "UW")
                    sig.DataType = strcat("fixdt(0, 16, ", sig_info.numerator , "/" , sig_info.denominator, ", ", tx_info.Offset, ")");
                elseif strcmp(sig_info.Attribute, "UD")
                    sig.DataType = strcat("fixdt(0, 32, ", sig_info.numerator , "/" , sig_info.denominator, ", ", tx_info.Offset, ")");
                elseif strcmp(sig_info.Attribute, "SB")
                    sig.DataType = strcat("fixdt(0, 8, ", sig_info.numerator , "/" , sig_info.denominator, ", ", tx_info.Offset, ")");
                elseif strcmp(sig_info.Attribute, "SW")
                    sig.DataType = strcat("fixdt(0, 16, ", sig_info.numerator , "/" , sig_info.denominator, ", ", tx_info.Offset, ")");
                elseif strcmp(sig_info.Attribute, "SD")
                    sig.DataType = strcat("fixdt(0, 32, ", sig_info.numerator , "/" , sig_info.denominator, ", ", tx_info.Offset, ")");
                end
            end
            sig.Max = str2double(sig_info.("Max（Internal）"));
            sig.Min = str2double(sig_info.("Min（Internal）"));
            addEntry(design_data, signal_name, sig)
        end
    end
end