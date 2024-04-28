# %%
import xlwings as xw
import os
import pandas as pd
import numpy as np
from fractions import Fraction
from decimal import Decimal

# %%
def is_excel_file(filename):
    with open(filename, "rb") as f:
        header = f.read(4)
        return header == b"\x50\x4B\x03\x04"


def get_true_number(number):
    if isinstance(number, str):
        tmp_number = str(eval(number))
    elif isinstance(number, (int, float, complex)):
        tmp_number = str(number)
    else:
        raise ValueError(f"Number {number} is not valid.")

    if Decimal(tmp_number) == Decimal(tmp_number).to_integral():
        true_number = Decimal(tmp_number).to_integral()
    else:
        true_number = Decimal(tmp_number).normalize()

    return str(true_number)

# %%
class _xlsCanSig:
    def __init__(self) -> None:
        self.__StartBit = 0
        self.__Len = 0
        self.__Para = ""
        self.__Desc = ""
        self.__Unit = ""
        self.__LSB = ""
        self.__Offset = 0
        self.__Min = 0
        self.__Max = 0
        self.__InvSta = ""
        self.__ErrIndVal = ""
        self.__IsAnal = False

    @property
    def StartBit(self):
        return self.__StartBit

    @StartBit.setter
    def StartBit(self, StartBit):
        self.__StartBit = StartBit

    @property
    def Len(self):
        return self.__Len

    @Len.setter
    def Len(self, Len):
        self.__Len = Len

    @property
    def Para(self):
        return self.__Para

    @Para.setter
    def Para(self, Para):
        self.__Para = Para

    @property
    def Desc(self):
        return self.__Desc

    @Desc.setter
    def Desc(self, Desc):
        self.__Desc = Desc

    @property
    def Unit(self):
        return self.__Unit

    @Unit.setter
    def Unit(self, Unit):
        self.__Unit = Unit

    @property
    def LSB(self):
        return self.__LSB

    @LSB.setter
    def LSB(self, LSB):
        self.__LSB = LSB

    @property
    def Offset(self):
        return self.__Offset

    @Offset.setter
    def Offset(self, Offset):
        self.__Offset = Offset

    @property
    def Min(self):
        return self.__Min

    @Min.setter
    def Min(self, Min):
        self.__Min = Min

    @property
    def Max(self):
        return self.__Max

    @Max.setter
    def Max(self, Max):
        self.__Max = Max

    @property
    def InvSta(self):
        return self.__InvSta

    @InvSta.setter
    def InvSta(self, InvSta):
        self.__InvSta = InvSta

    @property
    def ErrIndVal(self):
        return self.__ErrIndVal

    @ErrIndVal.setter
    def ErrIndVal(self, ErrIndVal):
        self.__ErrIndVal = ErrIndVal

    @property
    def IsAnal(self):
        return self.__IsAnal

    @IsAnal.setter
    def IsAnal(self, IsAnal):
        self.__IsAnal = IsAnal


class _xlsCanTxSig(_xlsCanSig):
    def __init__(self) -> None:
        super().__init__()


class _xlsCanRxSig(_xlsCanSig):
    def __init__(self) -> None:
        super().__init__()
        self.__RecParaInvSta = ""
        self.__RecInitVal = ""
        self.__EcmInReqPara = ""
        self.__EcmInReqParaInvSta = ""

    @property
    def RecParaInvSta(self):
        return self.__RecParaInvSta

    @RecParaInvSta.setter
    def RecParaInvSta(self, RecParaInvSta):
        self.__RecParaInvSta = RecParaInvSta

    @property
    def RecInitVal(self):
        return self.__RecInitVal

    @RecInitVal.setter
    def RecInitVal(self, RecInitVal):
        self.__RecInitVal = RecInitVal

    @property
    def EcmInReqPara(self):
        return self.__EcmInReqPara

    @EcmInReqPara.setter
    def EcmInReqPara(self, EcmInReqPara):
        self.__EcmInReqPara = EcmInReqPara

    @property
    def EcmInReqParaInvSta(self):
        return self.__EcmInReqParaInvSta

    @EcmInReqParaInvSta.setter
    def EcmInReqParaInvSta(self, EcmInReqParaInvSta):
        self.__EcmInReqParaInvSta = EcmInReqParaInvSta

# %%
class _xlsCanMsg:
    def __init__(self) -> None:
        self.CanID = ""
        self.PGN = ""
        self.SrcAdd = ""
        self.Type = ""
        self.ModulationArea = ""
        self.FrameSelFlag = ""
        self.FrameDesc = ""
        self.SigDf = ""
        self.Rate = ""

    def load(self, msg_df):
        self.MsgDf = msg_df
        self.MsgDf = self.MsgDf.dropna(axis=1, how="all")
        self.MsgDf = self.MsgDf.dropna(axis=0, how="all")
        self.MsgDf.replace(np.nan, "", inplace=True)
        self.MsgDf = self.MsgDf.set_index(self.MsgDf.columns[0])
        self.CanID = str(self.MsgDf.loc["CAN ID"].values[0]).strip().replace(".0", "")
        self.PGN = str(self.MsgDf.loc["PGN"].values[0]).strip().replace(".0", "")
        self.SrcAdd = (
            str(self.MsgDf.loc["Source Address"].values[0]).strip().replace(".0", "")
        )
        self.Type = str(self.MsgDf.loc["Type"].values[0]).strip().replace(".0", "")
        self.ModulationArea = (
            str(self.MsgDf.loc["Modulation Area"].values[0]).strip().replace(".0", "")
        )
        self.FrameSelFlag = (
            str(self.MsgDf.loc["Frame Select Flag"].values[0]).strip().replace(".0", "")
        )
        self.FrameDesc = (
            str(self.MsgDf.loc["Frame Description"].values[0]).strip().replace(".0", "")
        )

    def prase_sig_df(self, sig_df):
        # format df
        sig_df = sig_df.dropna(axis=1, how="all")
        sig_df = sig_df.dropna(axis=0, how="all")
        sig_df = sig_df.fillna(method="ffill", axis=0)
        sig_df = sig_df.fillna(method="ffill", axis=1)
        sig_df = sig_df.drop([0])
        sig_df = sig_df.reset_index(drop=True)
        sig_header = [
            i_header.replace("\n", " ").strip() for i_header in sig_df.values.tolist()[0]
        ]
        sig_df.columns = sig_header
        sig_df = sig_df.drop([0])
        self.SigDf = sig_df.reset_index(drop=True)


class _xlsCanRxNormalMsg(_xlsCanMsg):
    def __init__(self) -> None:
        super().__init__()
        self.SuperTimeout = ""
        self.RecFlagVar = ""
        self.Sigs = []

    def load(self, msg_df, sig_df):
        super().load(msg_df)
        self.Rate = (
            str(self.MsgDf.loc["Receive Rate(msec)"].values[0])
            .strip()
            .replace(".0", "")
        )
        self.SuperTimeout = (
            str(self.MsgDf.loc["Supervision Timeout(msec)"].values[0])
            .strip()
            .replace(".0", "")
        )
        self.RecFlagVar = (
            str(self.MsgDf.loc["Receive Flag Variable"].values[0])
            .strip()
            .replace(".0", "")
        )
        self.prase_sig_df(sig_df)

    def prase_sig_df(self, sig_df):
        super().prase_sig_df(sig_df)
        ori_para = "Default"
        for _, row in self.SigDf.iterrows():
            if row["Parameter"] != '-':
                if ori_para != row["Parameter"]:
                        
                    ori_para = row["Parameter"]
                    signal = _xlsCanRxSig()
                    self.Sigs.append(signal)
                    start_byte = get_true_number(str(row["Start Byte"]).strip())
                    bit = str(row["BIT"]).strip().replace(".0", "")

                    if bit == "-":
                        self.Sigs[-1].StartBit = (int(start_byte) - 1) * 8
                        self.Sigs[-1].Len = self.Sigs[-1].Len + 8
                    else:
                        self.Sigs[-1].StartBit = (int(start_byte) - 1) * 8 + (8 - int(bit[0]))
                        if bit.isdigit():
                            self.Sigs[-1].Len = self.Sigs[-1].Len + 1
                        else:
                            self.Sigs[-1].Len = self.Sigs[-1].Len + eval(bit) + 1

                    if ori_para == "always0" or (
                        ori_para.startswith("(") and ori_para.endswith(")")
                    ):
                        if ori_para == "always0":
                            self.Sigs[-1].Para = row["Parameter"] + "_" + self.CanID + "_Byte_" + start_byte

                            if bit[0] != "-":
                                self.Sigs[-1].Para = self.Sigs[-1].Para + "_" + bit[0]

                            self.Sigs[-1].IsAnal = True

                        elif ori_para.startswith("(") and ori_para.endswith(")"):
                            para_name = ori_para[1:-1]
                            self.Sigs[-1].Para = (
                                "padding"
                                + para_name
                                + "_"
                                + self.CanID
                                + "_Byte_"
                                + start_byte
                            )

                            if bit[0] != "-":
                                self.Sigs[-1].Para = self.Sigs[-1].Para + "_" + bit[0]
                            self.Sigs[-1].IsAnal = True

                        self.Sigs[-1].LSB = (
                            "1"
                            if str(row["LSB"]).strip() == "-"
                            else get_true_number(str(row["LSB"]).strip())
                        )
                        self.Sigs[-1].Offset = (
                            "0"
                            if str(row["Offset"]).strip() == "-"
                            else get_true_number(str(row["Offset"]).strip())
                        )
                        self.Sigs[-1].Min = (
                            str(int(para_name, 16))
                            if str(row["Min"]).strip() == "-"
                            else get_true_number(str(row["Min"]).strip())
                        )
                        self.Sigs[-1].Max = (
                            str(int(para_name, 16))
                            if str(row["Max"]).strip() == "-"
                            else get_true_number(str(row["Max"]).strip())
                        )
                        self.Sigs[-1].IsAnal = True
                    else:
                        self.Sigs[-1].Para = row["Parameter"].strip()
                        self.Sigs[-1].LSB = get_true_number(str(row["LSB"]).strip())
                        self.Sigs[-1].Offset = get_true_number(str(row["Offset"]).strip())
                        self.Sigs[-1].Min = get_true_number(str(row["Min"]).strip())
                        self.Sigs[-1].Max = get_true_number(str(row["Max"]).strip())
                        self.Sigs[-1].IsAnal = False

                    self.Sigs[-1].Desc = row["Description"].strip()
                    self.Sigs[-1].Unit = row["Unit"].strip()
                    self.Sigs[-1].InvSta = row["Invalid Status"].strip()
                    self.Sigs[-1].ErrIndVal = row["Error Indicator Value （Receive Default Value）"].strip()
                    self.Sigs[-1].RecParaInvSta = row["Receive Parameter  Invalid Status"].strip()
                else:
                    bit = str(row["BIT"]).strip().replace(".0", "")

                    if bit == "-":
                        self.Sigs[-1].Len = self.Sigs[-1].Len + 8
                    else:
                        if bit.isdigit():
                            self.Sigs[-1].Len = self.Sigs[-1].Len + 1
                        else:
                            self.Sigs[-1].Len = self.Sigs[-1].Len + eval(bit) + 1
            else:
                continue


class _xlsCanTxNormalMsg(_xlsCanMsg):
    def __init__(self) -> None:
        super().__init__()
        self.Sigs = []

    def load(self, msg_df, sig_df):
        super().load(msg_df)
        self.Rate = (
            str(self.MsgDf.loc["Transmission Rate(msec)"].values[0])
            .strip()
            .replace(".0", "")
        )
        self.prase_sig_df(sig_df)

    def prase_sig_df(self, sig_df):
        super().prase_sig_df(sig_df)
        ori_para = "Default"
        for _, row in self.SigDf.iterrows():
            if row["Parameter (Padding)"].strip() != '-':
                if ori_para != row["Parameter (Padding)"].strip():
                        
                    ori_para = row["Parameter (Padding)"].strip()
                    signal = _xlsCanTxSig()
                    self.Sigs.append(signal)
                    start_byte = get_true_number(str(row["Start Byte"]).strip())
                    bit = str(row["Bit"]).strip().replace(".0", "")

                    if bit == "-":
                        self.Sigs[-1].StartBit = (int(start_byte) - 1) * 8
                        self.Sigs[-1].Len = self.Sigs[-1].Len + 8
                    else:
                        self.Sigs[-1].StartBit = (int(start_byte) - 1) * 8 + (8 - int(bit[0]))
                        if bit.isdigit():
                            self.Sigs[-1].Len = self.Sigs[-1].Len + 1
                        else:
                            self.Sigs[-1].Len = self.Sigs[-1].Len + eval(bit) + 1

                    if ori_para == "always0" or (
                        ori_para.startswith("(") and ori_para.endswith(")")
                    ):
                        if ori_para == "always0":
                            self.Sigs[-1].Para = row["Parameter (Padding)"] + "_" + self.CanID + "_Byte_" + start_byte

                            if bit[0] != "-":
                                self.Sigs[-1].Para = self.Sigs[-1].Para + "_" + bit[0]

                            self.Sigs[-1].IsAnal = True

                        elif ori_para.startswith("(") and ori_para.endswith(")"):
                            para_name = ori_para[1:-1]
                            self.Sigs[-1].Para = (
                                "padding"
                                + para_name
                                + "_"
                                + self.CanID
                                + "_Byte_"
                                + start_byte
                            )

                            if bit[0] != "-":
                                self.Sigs[-1].Para = self.Sigs[-1].Para + "_" + bit[0]
                            self.Sigs[-1].IsAnal = True

                        self.Sigs[-1].LSB = (
                            "1"
                            if str(row["LSB"]).strip() == "-"
                            else get_true_number(str(row["LSB"]).strip())
                        )
                        self.Sigs[-1].Offset = (
                            "0"
                            if str(row["Offset"]).strip() == "-"
                            else get_true_number(str(row["Offset"]).strip())
                        )
                        self.Sigs[-1].Min = (
                            str(int(para_name, 16))
                            if str(row["Min"]).strip() == "-"
                            else get_true_number(str(row["Min"]).strip())
                        )
                        self.Sigs[-1].Max = (
                            str(int(para_name, 16))
                            if str(row["Max"]).strip() == "-"
                            else get_true_number(str(row["Max"]).strip())
                        )
                    else:
                        self.Sigs[-1].Para = row["Parameter (Padding)"]
                        self.Sigs[-1].LSB = get_true_number(str(row["LSB"]).strip())
                        self.Sigs[-1].Offset = get_true_number(str(row["Offset"]).strip())
                        self.Sigs[-1].Min = get_true_number(str(row["Min"]).strip())
                        self.Sigs[-1].Max = get_true_number(str(row["Max"]).strip())
                        self.Sigs[-1].IsAnal = False

                    self.Sigs[-1].Desc = row["Description"]
                    self.Sigs[-1].Unit = row["Unit"]
                    self.Sigs[-1].InvSta = row["Invalid Status"]
                    self.Sigs[-1].ErrIndVal = row["Error Indicator Value"]
                else:
                    bit = str(row["Bit"]).strip().replace(".0", "")

                    if bit == "-":
                        self.Sigs[-1].Len = self.Sigs[-1].Len + 8
                    else:
                        if bit.isdigit():
                            self.Sigs[-1].Len = self.Sigs[-1].Len + 1
                        else:
                            self.Sigs[-1].Len = self.Sigs[-1].Len + eval(bit) + 1
            else:
                continue

# %%
class xlsDatabase:
    def __init__(self) -> None:
        self.DatabaseType = ""
        self.ShtID = ["TxNormal", "TxMulti", "TxCondition", "RxNormal"]
        self.ShtType = "None"

    def get_excel_msg_sig_df(self, sheet, msg_header, sig_header):
        xls_end = "Note"
        last_row = sheet.used_range.last_cell.row
        last_col = sheet.used_range.last_cell.column
        b_col_data = sheet.range((1, 2), (last_row, 2)).value

        msg_header_row = b_col_data.index(msg_header) + 1
        sig_header_row = b_col_data.index(sig_header) + 1

        xls_end_list = [
            i_end
            for i_end in b_col_data
            if xls_end.lower() in str(i_end).lower()
        ]
        if len(xls_end_list) != 1:
            raise ValueError(f"Sheet Contains Multi Notes, Please Check.")

        xls_end_row = b_col_data.index(xls_end_list[0]) + 1

        msg_begin = sheet.range((msg_header_row + 1, 2)).end("right")
        msg_end = sheet.range((sig_header_row - 1, 2))
        msg_range = sheet.range(msg_begin, msg_end)
        msg_df = msg_range.options(pd.DataFrame, index=False, header=False).value

        sig_begin = sheet.range((sig_header_row + 1, last_col))
        sig_end = sheet.range((xls_end_row - 1, 2))
        sig_range = sheet.range(sig_begin, sig_end)
        sig_df = sig_range.options(pd.DataFrame, index=False, header=False).value

        return msg_df, sig_df

    def load_excel(self):
        app = xw.App(visible=False, add_book=False)
        workbook = app.books.open(self.ExcelFile)
        tx_normal_name = []
        tx_multi_name = []
        tx_condition_name = []
        rx_normal_name = []
        for i_sheet in workbook.sheets:
            if any((ShtType := substring) in i_sheet.name for substring in self.ShtID):
                self.ShtType = ShtType
                continue
            if self.ShtType == "TxNormal":
                tx_normal_name.append(i_sheet.name)
            elif self.ShtType == "TxMulti":
                tx_multi_name.append(i_sheet.name)
            elif self.ShtType == "TxCondition":
                tx_condition_name.append(i_sheet.name)
            elif self.ShtType == "RxNormal":
                rx_normal_name.append(i_sheet.name)

        # load Tx Normal
        self.TxNormal = []
        for i_name in tx_normal_name:
            msg_df, sig_df = self.get_excel_msg_sig_df(
                workbook.sheets[i_name], "Header", "Transmission Frame Structure"
            )
            tx_normal_msg = _xlsCanTxNormalMsg()
            tx_normal_msg.load(msg_df, sig_df)
            self.TxNormal.append(tx_normal_msg)

        # load Tx Multi
        self.TxMulti = []
        ## TBD

        # load Tx Condition
        self.TxCondition = []
        ## TBD

        # load Rx Condition
        self.RxNormal = []
        for i_name in rx_normal_name:
            msg_df, sig_df = self.get_excel_msg_sig_df(
                workbook.sheets[i_name], "Header", "Receive Frame Structure"
            )
            rx_normal_msg = _xlsCanRxNormalMsg()
            rx_normal_msg.load(msg_df, sig_df)
            self.RxNormal.append(rx_normal_msg)

        workbook.close()
        app.quit()

    def load(self, xls_filename, can_type):
        if len(xls_filename) == 0:
            raise ValueError(f"Input filename should not be empty.")
        if not os.path.exists(xls_filename):
            raise ValueError(f"File {xls_filename} does not exist.")
        if not is_excel_file(xls_filename):
            raise ValueError(f"File {xls_filename} is not a valid Excel Database.")
        if (can_type != "ISOCAN") and (can_type != "J1939"):
            raise ValueError(f"File {can_type} is neither ISOCAN or J1939.")
        self.ExcelFile = xls_filename
        self.CanType = can_type
        self.load_excel()

# %%
class xlsMatlab:
    def __init__(self) -> None:
        self.TxNormalIdxHeader = [['No.', 'FrameID', 'Type', 'Description']]
        self.TxNormalIdx = []
        self.TxNormalInfoHeader = [['Signal', 'Factor', 'Offset', 'Max', 'Min', 'Invalid Status', 'Error Indicator Value', 'Output Can Frame']]
        self.TxNormalInfo = {}

        self.RxNormalIdxHeader = [['No.', 'FrameID', 'Type', 'Description']]
        self.RxNormalIdx = []
        self.RxNormalInfoHeader = [['Signal', 'Factor', 'Offset', 'Max', 'Min', 'Invalid Status', 'Error Indicator Value', 'Input Can Frame', 'Start Bit', 'Length']]
        self.RxNormalInfo = {}

    def load(self, xls_db):
        can_type = xls_db.CanType
        if can_type == "ISOCAN":
            self.TxNormalIdx, self.TxNormalInfo = self.get_info_content(xls_db.TxNormal, 'TxNormal')
            self.RxNormalIdx, self.RxNormalInfo = self.get_info_content(xls_db.RxNormal, 'RxNormal')
            #TBD
        elif can_type == "J1939":
            pass

    def get_info_content(self, msgs, msg_type):
        msg_idx = []
        msg_info = {}
        for idx, i_msg in enumerate(msgs):
            msg_idx.append([idx + 1, i_msg.CanID, msg_type, i_msg.FrameDesc])
            sig_info = []
            for i_sig in i_msg.Sigs:
                if i_sig.IsAnal == True:
                    continue
                else:
                    i_sig_info = [i_sig.Para, i_sig.LSB, i_sig.Offset, i_sig.Max, i_sig.Min]
                    if msg_type == 'TxNormal':
                        i_sig_info = i_sig_info + [i_sig.InvSta] + [i_sig.ErrIndVal] + ['can_tx_' + i_sig.Para]
                    elif msg_type == 'RxNormal':
                        i_sig_info = i_sig_info + [i_sig.InvSta] + [i_sig.ErrIndVal] + [i_sig.Para.replace('can_gmlan_rx_', '')] + [i_sig.StartBit]+ [i_sig.Len]
                    sig_info.append(i_sig_info)
            msg_info[i_msg.CanID] = sig_info
        return msg_idx, msg_info
    
    def generate_xls(self):
        def set_xls_format(sht):
            sht.range('A1').expand('right').color = (204, 255, 255)
            sht.range('A1').expand('right').font.bold = True
            sht.range('A1').expand('right').font.size = 13
            sht.range('A1').expand().api.Borders(8).LineStyle = 1
            sht.range('A1').expand().api.Borders(9).LineStyle = 1
            sht.range('A1').expand().api.Borders(7).LineStyle = 1
            sht.range('A1').expand().api.Borders(10).LineStyle = 1
            sht.range('A1').expand().api.Borders(12).LineStyle = 1
            sht.range('A1').expand().api.Borders(11).LineStyle = 1
            sht.range('A1').expand().api.HorizontalAlignment = -4152
            sht.range('A1').expand().api.VerticalAlignment = -4107
            sht.autofit()

        with xw.App(visible=True, add_book=False) as app:
            workbook = app.books.add()

            tx_normal_idx_sht = workbook.sheets.add(after=workbook.sheets.count)
            tx_normal_idx_sht.name = 'TxNormal'
            tx_normal_idx_sht.range('A1').value = self.TxNormalIdxHeader + self.TxNormalIdx
            set_xls_format(tx_normal_idx_sht)

            for i_msg in self.TxNormalInfo.keys():
                msg_info_sht = workbook.sheets.add(after=workbook.sheets.count)
                msg_info_sht.name = i_msg 
                msg_info_sht.range('A1').value = self.TxNormalInfoHeader + self.TxNormalInfo[i_msg]
                set_xls_format(msg_info_sht)

            rx_normal_idx_sht = workbook.sheets.add(after=workbook.sheets.count)
            rx_normal_idx_sht.name = 'RxNormal'
            rx_normal_idx_sht.range('A1').value = self.RxNormalIdxHeader + self.RxNormalIdx
            set_xls_format(rx_normal_idx_sht)

            for i_msg in self.RxNormalInfo.keys():
                msg_info_sht = workbook.sheets.add(after=workbook.sheets.count)
                msg_info_sht.name = i_msg 
                msg_info_sht.range('A1').value = self.RxNormalInfoHeader + self.RxNormalInfo[i_msg]
                set_xls_format(msg_info_sht)
            
            workbook.sheets['Sheet1'].delete()
            workbook.save(r'Output\ecuCanFrame.xlsx')

# %%
class ecuDbc:
    def __init__(self):
        self.Content = ""
        self.Property = ""
        with open("Template\dbcHeader.txt", "r") as h_f:
            self.Header = h_f.read()
        with open("Template\dbcAttribute.txt", "r") as t_f:
            self.Attribute = t_f.read()

    def load(self, xls_db):
        can_type = xls_db.CanType
        if can_type == "ISOCAN":
            # motorola
            self.ByteOder = 0
            rx_normal_info, rx_normal_desc, rx_normal_prop = self.get_msg_content(
                xls_db.RxNormal, "Other", "ECU"
            )
            tx_normal_info, tx_normal_desc, tx_normal_prop = self.get_msg_content(
                xls_db.TxNormal, "ECU", "Other"
            )

            self.Content = (
                self.Content
                + rx_normal_info
                + tx_normal_info
                + rx_normal_desc
                + tx_normal_desc
            )
            self.Property = rx_normal_prop + tx_normal_prop

        elif can_type == "J1939":
            # inter
            self.ByteOder = 1
            self.CanRxNormal = xls_db.RxNormal
            self.CanTxNormal = xls_db.TxNormal
            self.CanTxMulti = xls_db.TxMulti
            self.CanTxCondition = xls_db.TxCondition
            ## TBD

    def get_msg_content(self, msgs, tx_ecu, rx_ecu):
        info_content = ""
        desc_content = ""
        prop_content = ""
        for i_msg in msgs:
            info_content = info_content + "BO_ {} ECU_0x{}: 8 {}".format(
                str(int(i_msg.CanID, 16)), i_msg.CanID, tx_ecu
            )
            info_content = info_content + "\n"

            desc_content = desc_content + 'CM_ BO_ {} "{}";'.format(
                str(int(i_msg.CanID, 16)), i_msg.FrameDesc
            )
            desc_content = desc_content + "\n"

            prop_content = prop_content + 'BA_ "GenMsgCycleTime" BO_ {} {};'.format(
                str(int(i_msg.CanID, 16)), i_msg.Rate
            )
            prop_content = prop_content + "\n"

            for i_sig in i_msg.Sigs:
                info_content = (
                    info_content
                    + ' SG_ {} : {}|{}@{}+ ({},{}) [{}|{}] "{}"  {}'.format(
                        i_sig.Para,
                        self.calclate_start_bit(i_sig.StartBit),
                        str(i_sig.Len),
                        self.ByteOder,
                        get_true_number(i_sig.LSB),
                        i_sig.Offset,
                        i_sig.Min,
                        i_sig.Max,
                        i_sig.Unit,
                        rx_ecu,
                    )
                )
                info_content = info_content + "\n"

                desc_content = desc_content + 'CM_ SG_ {} {} "{}";'.format(
                    str(int(i_msg.CanID, 16)), i_sig.Para, i_sig.Desc
                )
                desc_content = desc_content + "\n"

            info_content = info_content + "\n\n"
        return info_content, desc_content, prop_content

    def calclate_start_bit(self, startbit):
        if self.ByteOder == 0:
            # (int(startbit / 8) + 1) * 8 - (a - int(startbit / 8) * 8 + 1)
            startbit = 16 * int(startbit / 8) + 7 - startbit
            return str(startbit)
        elif self.ByteOder == 1:
            return str(startbit)

    def generate_dbc(self):
        with open("Output\ecuDbc.dbc", "w") as db_f:
            db_f.write(
                self.Header
                + "\n"
                + self.Content
                + "\n"
                + self.Attribute
                + "\n"
                + self.Property
            )

# %%
xlsDB = xlsDatabase()
xlsDB.load(r'D:\00.Me\DL\Share\Code\GenFootage\Input\test.xlsx', 'ISOCAN')

dbc = ecuDbc()
dbc.load(xlsDB)
dbc.generate_dbc()

mbd = xlsMatlab()
mbd.load(xlsDB)
mbd.generate_xls()


