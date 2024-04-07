classdef autosarMBD < handle
    properties
        cantx_error
        cantx_noerror
    end

    methods
        function obj = autosarMBD()
            obj.cantx_error = 'Lib/cantx_error';
            obj.cantx_noerror = 'Lib/cantx_noerror';
        end

        function gen_tx_normal_model(obj, output_path, msg_name, msg_info)
            tx_normal_model_name = ['cantx_0x' msg_name];
            tx_normal_model = new_system(tx_normal_model_name);
            open_system(tx_normal_model);
            for i_row = 1:height(msg_info)
                
                sig_model_path = ['cantx_0x' msg_name '/sig_' msg_info.Signal{i_row}];

                if contains(msg_info.("Invalid Status"){i_row}, 'always FALSE')
                    add_block(obj.cantx_noerror, sig_model_path, 'Position', [1325, 270 + i_row * 90,1980, 330 + i_row * 90]);

                else
                    add_block(obj.cantx_error, sig_model_path, 'Position', [1325, 270 + i_row * 90,1980, 330 + i_row * 90])

                    error_name = ['cantx_err_diag_' msg_info.Signal{i_row} '_bsw'];
                    obj.modify_port_name('In', sig_model_path, 'cantx_inv_status', error_name)

                end

                inport_name = ['cantx_diag_' msg_info.Signal{i_row} '_bsw'];
                obj.modify_port_name('In', sig_model_path, 'cantx_phy', inport_name)

                outport_name = ['cantx_diag_' msg_info.Signal{i_row} '_raw'];
                obj.modify_port_name('Out', sig_model_path, 'cantx_raw', outport_name)

                mask_values = {msg_info.Offset{i_row}, msg_info.Factor{i_row}};
                set_param([sig_model_path '/Phy2Raw'], 'MaskValues', mask_values);

                set_param([sig_model_path '/Max'], 'Value', msg_info.Max{i_row});
                set_param([sig_model_path '/Min'], 'Value', msg_info.Min{i_row});

                obj.add_subsystem_port(sig_model_path)
            end

            save_system(tx_normal_model, [output_path, '\' , tx_normal_model_name, '.slx']);
            close_system(tx_normal_model)
        end

        function modify_port_name(obj, port_dire, mdl_path, ori_name, dst_name)

            if strcmp(port_dire, 'In')
                line_handle = get_param([mdl_path '/' ori_name], 'LineHandles').Outport;
            elseif strcmp(port_dire, 'Out')
                line_handle = get_param([mdl_path '/' ori_name], 'LineHandles').Inport;
            end

            set_param([mdl_path '/' ori_name], 'Name', dst_name);
            set_param(line_handle, 'Name', dst_name);

        end

        function add_subsystem_port(obj, subsystem_path)
            parent_path = get_param(subsystem_path, 'Parent');
            subsystem_name = get_param(subsystem_path, 'Name');

            inport_names = get_param(find_system(subsystem_path, 'SearchDepth', 1, 'BlockType', 'Inport'), 'Name');
            in_handles = get_param(gcbh, 'PortHandles').Inport;
            for i_in = 1:length(in_handles)

                in_pos = get_param(get_param(subsystem_path, 'PortHandles').Inport(i_in), 'Position');
                inport_pos =  [in_pos(1)-230, in_pos(2)-7, in_pos(1)-200, in_pos(2)+7];
                add_block('simulink/Sources/In1', [parent_path '/' inport_names{i_in}], 'Name',inport_names{i_in},'Position', inport_pos)
                in_line_handle = add_line(parent_path, [inport_names{i_in} '/1'], [subsystem_name '/' num2str(i_in)]);
                set_param(in_line_handle, 'Name', inport_names{i_in});
            end


            outport_names = get_param(find_system(subsystem_path, 'SearchDepth', 1, 'BlockType', 'Outport'), 'Name');
            out_handles = get_param(gcbh, 'PortHandles').Outport;
            for i_out = 1:length(out_handles)

                out_pos = get_param(get_param(subsystem_path, 'PortHandles').Outport(i_out), 'Position');
                outport_pos =  [out_pos(1)+200, out_pos(2)-7, out_pos(1)+230, out_pos(2)+7];
                add_block('simulink/Sinks/Out1', [parent_path '/' outport_names{i_out}], 'Name',outport_names{i_out},'Position', outport_pos)
                out_line_handle = add_line(parent_path, [subsystem_name '/' num2str(i_out)], [outport_names{i_out} '/1']);
                set_param(out_line_handle, 'Name', outport_names{i_out});
            end



        end

    end

end