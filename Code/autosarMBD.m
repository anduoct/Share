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

        function gen_tx_normal_model(obj, msg_name, msg_info)
            tx_normal_model = new_system(['cantx_0x' msg_name]);
            open_system(tx_normal_model);             
            for i_row = 1:height(msg_info)
                if contains(msg_info.("Invalid Status"){i_row}, 'always FALSE')
                    sig_model_path = ['cantx_0x' msg_name '/sig_' msg_info.Signal{i_row}];
                    add_block(obj.cantx_noerror, sig_model_path, 'Position', [1325, 270 + i_row * 90,1980, 330 + i_row * 90]);

                    inport_handle = get_param([sig_model_path '/cantx_phy'], 'LineHandles').Outport;
                    inport_name = ['cantx_diag_' msg_info.Signal{i_row} '_bsw'];
                    set_param([sig_model_path '/cantx_phy'], 'Name', inport_name);
                    set_param(inport_handle, 'Name', inport_name);

                    mask_values = {msg_info.Offset{i_row}, msg_info.Factor{i_row}};
                    set_param([sig_model_path '/Phy2Raw'], 'MaskValues', mask_values);

                    set_param([sig_model_path '/Max'], 'Value', msg_info.Max{i_row});
                    set_param([sig_model_path '/Min'], 'Value', msg_info.Min{i_row});

                    outport_handle = get_param([sig_model_path '/cantx_raw'], 'LineHandles').Inport;
                    outport_name = ['cantx_diag_' msg_info.Signal{i_row} '_raw'];
                    set_param([sig_model_path '/cantx_raw'], 'Name', outport_name);
                    set_param(outport_handle, 'Name', outport_name);

                else
                    sig_model_path = ['cantx_0x' msg_name '/sig_' msg_info.Signal{i_row}];
                    add_block(obj.cantx_error, sig_model_path, 'Position', [1325, 270 + i_row * 90,1980, 330 + i_row * 90])

                end
            end

        end

    end

end