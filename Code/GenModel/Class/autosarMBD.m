classdef autosarMBD < handle
    properties
        elvl_key
        elvl_value
        elvl_dict
        cantx_normal
        cantx_error
        cantx_noerror
        cantx_info
        cantx_sldd
        main_base_width
        main_base_up
        main_base_down
        main_port_interval
        main_port_offset
        swt_base_width
        swt_base_up
        swt_base_down
        swt_port_interval
        swt_port_offset
        elvl_base_width
        elvl_base_up
        elvl_base_down
        elvl_sub_interval
        elvl_port_interval
        elvl_port_offset
        sig_base_pos
        sig_sub_interval
        case_str
    end

    methods
        function obj = autosarMBD()
            obj.elvl_key = {'2X', '4X', '8X', '16X', '25X', '32X', '64X', '128X', '200X', '250X', '256X', 'REF'};
            obj.elvl_value = {'PLCANI_APCNTL_SET_INF_2X', 'PLCANI_APCNTL_SET_INF_4X', 'PLCANI_APCNTL_SET_INF_8X', 'PLCANI_APCNTL_SET_INF_16X', 'PLCANI_APCNTL_SET_INF_25X', 'PLCANI_APCNTL_SET_INF_32X', 'PLCANI_APCNTL_SET_INF_64X', 'PLCANI_APCNTL_SET_INF_128X', 'PLCANI_APCNTL_SET_INF_200X', 'PLCANI_APCNTL_SET_INF_250X', 'PLCANI_APCNTL_SET_INF_256X', 'PLCANI_APCNTL_SET_INF_REF'};
            obj.elvl_dict = containers.Map(obj.elvl_key, obj.elvl_value);

            obj.cantx_normal = 'Lib/cantx_normal';
            obj.cantx_error = 'Lib/cantx_error';
            obj.cantx_noerror = 'Lib/cantx_noerror';
            obj.cantx_sldd = which('Lib.sldd');

            obj.main_base_width = [240 650];
            obj.main_base_up = 25;
            obj.main_base_down = 0;
            obj.main_port_interval = 30;
            obj.main_port_offset = 20;

            obj.swt_base_width = [240 445];
            obj.swt_base_up = 25;
            obj.swt_base_down = 0;
            obj.swt_port_interval = 25;
            obj.swt_port_offset = 10;

            obj.elvl_base_width = [1000 1510];
            obj.elvl_base_up = 150;
            obj.elvl_base_down = 0;
            obj.elvl_sub_interval = 70;
            obj.elvl_port_interval = 30;
            obj.elvl_port_offset = 10;

            obj.sig_base_pos = [-125 25 530 85];
            obj.sig_sub_interval = 90;

            obj.case_str = '';
        end

        function gen_tx_normal_model(obj, model_path, msg_name, msg_info)
            obj.cantx_info = msg_info;
            tx_normal_name = ['cantx_0x' msg_name];
            tx_normal_model = new_system(tx_normal_name);

            save_path = [model_path '\' tx_normal_name];
            mkdir(save_path);
            addpath(save_path)
            copyfile(obj.cantx_sldd, [save_path '\' tx_normal_name '.sldd'])

            set_param(tx_normal_model, 'Datadictionary',[tx_normal_name '.sldd'])
            open_system(tx_normal_model);
            subsystem_path = [tx_normal_name '/' tx_normal_name '_main'];
            add_block(obj.cantx_normal, subsystem_path)

            tx_case_list = obj.elvl_key(ismember(obj.elvl_key, unique(obj.cantx_info.Elevel)));
            obj.add_tx_sig_case_subsystem(subsystem_path, tx_normal_name, tx_case_list)

            port_num = length(get_param(subsystem_path, 'PortHandles').Inport);
            obj.main_base_down = obj.main_base_up + obj.main_port_interval*port_num + obj.main_port_offset;
            set_param(subsystem_path, 'Position', [obj.main_base_width(1) obj.main_base_up obj.main_base_width(2) obj.main_base_down])
            obj.add_subsystem_port(subsystem_path)
            

            set_param(subsystem_path, 'FunctionInterfaceSpec', 'Allow arguments (Optimized)', 'RTWFileNameOpts', 'Use subsystem name')
            set_param(tx_normal_model, 'ZoomFactor', '100')
            save_system(tx_normal_model, [save_path, '\' , tx_normal_name, '.slx']);
            close_system(tx_normal_model)
        end

        function add_tx_sig_case_subsystem(obj, subsystem_path, tx_normal_name, tx_case_list)

            swt_blk_path = [subsystem_path '/Switch Case'];
            trg_inport_path = [subsystem_path '/trigger'];
            obj.case_str = '';
            for i_case = 1:length(tx_case_list)
                tx_case_cell = tx_case_list(i_case);
                if i_case ~= length(tx_case_list)
                    obj.case_str = [obj.case_str 'PLCANI_APCNTL_SET_INF_TYPE.' obj.elvl_dict(tx_case_cell{1}) ','];
                else
                    obj.case_str = [obj.case_str 'PLCANI_APCNTL_SET_INF_TYPE.' obj.elvl_dict(tx_case_cell{1})];
                end
            end
            obj.swt_base_down = obj.swt_base_up + length(tx_case_list) * obj.swt_port_interval + obj.swt_port_offset;
            set_param(swt_blk_path, 'CaseConditions' , ['{' obj.case_str '}'], 'Position', [obj.swt_base_width(1), obj.swt_base_up, obj.swt_base_width(2), obj.swt_base_down]);
            in_pos = get_param(get_param(swt_blk_path, 'PortHandles').Inport(1), 'Position');
            trigger_pos =  [in_pos(1)-150, in_pos(2)-7, in_pos(1)-120, in_pos(2)+7];
            set_param(trg_inport_path, 'Position', trigger_pos);
            swt_blk_hdls = get_param(swt_blk_path, 'PortHandles');

            for i_elvl= 1:length(tx_case_list)
                elvl_name = tx_case_list(i_elvl);
                sig_case_info = obj.cantx_info(strcmp(obj.cantx_info.Elevel, elvl_name),:);

                sig_case_path = [subsystem_path '/' tx_normal_name '_' elvl_name{1}];
                add_block('simulink/Ports & Subsystems/Switch Case Action Subsystem', sig_case_path)
                
                in_hdl = getSimulinkBlockHandle([sig_case_path '/In1']);
                out_hdl = getSimulinkBlockHandle([sig_case_path '/Out1']);
                line_hdl = get_param(in_hdl, 'LineHandles');
                delete_block([in_hdl, out_hdl]);
                delete_line(line_hdl.Outport(1));

                obj.add_tx_sig_subsystem(sig_case_path, sig_case_info)
    
                port_hdls = get_param(sig_case_path, 'PortHandles');
                port_num = length(port_hdls.Inport);
                obj.elvl_base_down = obj.elvl_base_up + obj.elvl_port_interval*port_num + obj.elvl_port_offset;
                set_param(sig_case_path, 'Position', [obj.elvl_base_width(1) obj.elvl_base_up obj.elvl_base_width(2) obj.elvl_base_down])
                obj.elvl_base_up = obj.elvl_base_down + obj.elvl_sub_interval;

                add_line(subsystem_path, swt_blk_hdls.Outport(i_elvl), port_hdls.Ifaction(1), 'autorouting','on')

                obj.add_subsystem_port(sig_case_path)

                set_param(sig_case_path, 'RTWSystemCode', 'Nonreusable function', 'RTWFcnNameOpts', 'Use subsystem name')

            end
            obj.elvl_base_up = 150;
            obj.elvl_base_down = 0;

            set_param(subsystem_path, 'ZoomFactor', '100')

        end

        function add_tx_sig_subsystem(obj, subsystem_path, sig_case_info)

            for i_row = 1:length(sig_case_info.Row)
                sig_name_cell = sig_case_info.Row(i_row);
                sig_name = sig_name_cell{1};

                sig_subsystem_path = [subsystem_path '/sig_' sig_name];

                if contains(sig_case_info.("Invalid Status"){i_row}, 'always FALSE')
                    add_block(obj.cantx_noerror, sig_subsystem_path, 'Position', [obj.sig_base_pos(1), obj.sig_base_pos(2) + i_row * obj.sig_sub_interval,obj.sig_base_pos(3), obj.sig_base_pos(4) + i_row * obj.sig_sub_interval]);

                else
                    add_block(obj.cantx_error, sig_subsystem_path, 'Position', [obj.sig_base_pos(1), obj.sig_base_pos(2) + i_row * obj.sig_sub_interval,obj.sig_base_pos(3), obj.sig_base_pos(4) + i_row * obj.sig_sub_interval]);

                    error_name = ['CanTx_Err_' sig_name];
                    obj.modify_port_name('In', sig_subsystem_path, 'cantx_inv_status', error_name)

                end

                inport_name = sig_name;
                obj.modify_port_name('In', sig_subsystem_path, 'cantx_phy', inport_name)

                outport_name = ['CanTx_' sig_name];
                obj.modify_port_name('Out', sig_subsystem_path, 'cantx_raw', outport_name)

%                 mask_values = {sig_case_info.Offset{i_row}, sig_case_info.Factor{i_row}};
%                 set_param([sig_subsystem_path '/Phy2Raw'], 'MaskValues', mask_values);

                set_param([sig_subsystem_path '/Max'], 'Value', sig_case_info.Max{i_row});
                set_param([sig_subsystem_path '/Min'], 'Value', sig_case_info.Min{i_row});

                obj.add_subsystem_port(sig_subsystem_path)

                set_param(sig_subsystem_path, 'ZoomFactor', '100')
                set_param(sig_subsystem_path, 'RTWSystemCode', 'Nonreusable function', 'RTWFcnNameOpts', 'Use subsystem name')
            end

        end

        function modify_port_name(~, port_dire, mdl_path, ori_name, dst_name)

            if strcmp(port_dire, 'In')
                line_handle = get_param([mdl_path '/' ori_name], 'LineHandles').Outport;
            elseif strcmp(port_dire, 'Out')
                line_handle = get_param([mdl_path '/' ori_name], 'LineHandles').Inport;
            end

            set_param([mdl_path '/' ori_name], 'Name', dst_name);
            set_param(line_handle, 'Name', dst_name);

        end

        function add_subsystem_port(~, subsystem_path)
            parent_path = get_param(subsystem_path, 'Parent');
            subsystem_name = get_param(subsystem_path, 'Name');

            inport_names = get_param(find_system(subsystem_path, 'SearchDepth', 1, 'BlockType', 'Inport'), 'Name');
            in_handles = get_param(subsystem_path, 'PortHandles').Inport;
            for i_in = 1:length(in_handles)

                in_pos = get_param(get_param(subsystem_path, 'PortHandles').Inport(i_in), 'Position');
                inport_pos =  [in_pos(1)-230, in_pos(2)-7, in_pos(1)-200, in_pos(2)+7];
                add_block('simulink/Sources/In1', [parent_path '/' inport_names{i_in}], 'Name', inport_names{i_in},'Position', inport_pos)
                in_line_handle = add_line(parent_path, [inport_names{i_in} '/1'], [subsystem_name '/' num2str(i_in)]);
                set_param(in_line_handle, 'Name', inport_names{i_in});
            end


            outport_names = get_param(find_system(subsystem_path, 'SearchDepth', 1, 'BlockType', 'Outport'), 'Name');
            out_handles = get_param(subsystem_path, 'PortHandles').Outport;
            for i_out = 1:length(out_handles)

                out_pos = get_param(get_param(subsystem_path, 'PortHandles').Outport(i_out), 'Position');
                outport_pos =  [out_pos(1)+200, out_pos(2)-7, out_pos(1)+230, out_pos(2)+7];
                add_block('simulink/Sinks/Out1', [parent_path '/' outport_names{i_out}], 'Name',outport_names{i_out},'Position', outport_pos)
                out_line_handle = add_line(parent_path, [subsystem_name '/' num2str(i_out)], [outport_names{i_out} '/1']);
                set_param(out_line_handle, 'Name', outport_names{i_out});
            end

        end

        function gen_tx_normal_code(obj, model_name)
            open_system(model_name)
            obj.modify_model_config(model_name)
            save_system(model_name )
        end

        function modify_model_config(~, model_name)
            sldd_cfg = Simulink.ConfigSetRef;
            set_param(sldd_cfg, 'Name', 'SLDD_CFG', 'SourceName', 'SLDD_CFG')
            attachConfigSet(model_name, sldd_cfg)
            setActiveConfigSet(model_name,'SLDD_CFG');
        end

    end

end