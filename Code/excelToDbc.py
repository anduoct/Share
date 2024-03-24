# %%
import os
from decimal import Decimal
from fractions import Fraction

import numpy as np
import pandas as pd
import xlwings as xw


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
    def Max(self, RecParaInvSta):
        self.__RecParaInvSta = RecParaInvSta

    @property
    def RecInitVal(self):
        return self.__RecInitVal

    @RecInitVal.setter
    def Max(self, RecInitVal):
        self.__RecInitVal = RecInitVal

    @property
    def EcmInReqPara(self):
        return self.__EcmInReqPara

    @EcmInReqPara.setter
    def Max(self, EcmInReqPara):
        self.__EcmInReqPara = EcmInReqPara

    @property
    def EcmInReqParaInvSta(self):
        return self.__EcmInReqParaInvSta

    @EcmInReqParaInvSta.setter
    def Max(self, EcmInReqParaInvSta):
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
            str(self.MsgDf.loc["Frame Select Area"].values[0]).strip().replace(".0", "")
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
            i_header.replace("\n", " ") for i_header in sig_df.values.tolist()[0]
        ]
        sig_df.columns = sig_header
        sig_df = sig_df.drop([0])
        self.SigDf = sig_df.reset_index(drop=True)


class _xlsCanRxNormalMsg(_xlsCanMsg):
    def __init__(self) -> None:
        super().__init__()
        self.RecRate = ""
        self.Sigs = []

    def load(self, msg_df, sig_df):
        super().load(msg_df)
        self.RecRate = (
            str(self.MsgDf.loc["Receive Rate(msec)"].values[0])
            .strip()
            .replace(".0", "")
        )
        self.prase_sig_df(sig_df)

    def prase_sig_df(self, sig_df):
        super().prase_sig_df(sig_df)
        ori_para = "Default"
        signal = "NoNeed"
        for _, row in self.SigDf.iterrows():
            if ori_para != row["Parameter (Padding)"]:
                ori_para = row["Parameter (Padding)"]
                if isinstance(signal, _xlsCanRxSig):
                    self.Sigs.append(signal)
                    signal = "NoNeed"
                if ori_para == "(0)":
                    signal = "NoNeed"
                    continue
                else:
                    signal = _xlsCanRxSig()
                    start_byte = get_true_number(str(row["Start Byte"]).strip())
                    bit = str(row["Bit"]).strip().replace(".0", "")

                    if bit == "-":
                        signal.StartBit = (int(start_byte) - 1) * 8
                        signal.Len = signal.Len + 8
                    else:
                        signal.StartBit = (int(start_byte) - 1) * 8 + (8 - int(bit[0]))
                        if bit.isdigit():
                            signal.Len = signal.Len + 1
                        else:
                            signal.Len = signal.Len + eval(bit) + 1

                    if ori_para == "always0":
                        signal.Para = (
                            row["Parameter (Padding)"]
                            + "_Byte_"
                            + start_byte
                            + "_"
                            + bit[0]
                        )
                    else:
                        signal.Para = row["Parameter (Padding)"]

                    signal.Desc = row["Description"]
                    signal.Unit = row["Unit"]
                    signal.LSB = get_true_number(str(row["LSB"]).strip())
                    signal.Offset = get_true_number(str(row["Offset"]).strip())
                    signal.Min = get_true_number(str(row["Min"]).strip())
                    signal.Max = get_true_number(str(row["Max"]).strip())
                    signal.InvSta = row["Invalid Status"]
                    signal.ErrIndVal = row["Error Indicator Value"]
            else:
                if ori_para == "(0)":
                    continue
                else:
                    bit = str(row["Bit"]).strip().replace(".0", "")

                    if bit == "-":
                        signal.Len = signal.Len + 8
                    else:
                        if bit.isdigit():
                            signal.Len = signal.Len + 1
                        else:
                            signal.Len = signal.Len + eval(bit) + 1


class _xlsCanTxNormalMsg(_xlsCanMsg):
    def __init__(self) -> None:
        super().__init__()
        self.TransRate = ""
        self.Sigs = []

    def load(self, msg_df, sig_df):
        super().load(msg_df)
        self.TransRate = (
            str(self.MsgDf.loc["Transmission Rate(msec)"].values[0])
            .strip()
            .replace(".0", "")
        )
        self.prase_sig_df(sig_df)

    def prase_sig_df(self, sig_df):
        super().prase_sig_df(sig_df)
        ori_para = "Default"
        signal = "NoNeed"
        for _, row in self.SigDf.iterrows():
            if ori_para != row["Parameter (Padding)"]:
                ori_para = row["Parameter (Padding)"]
                if isinstance(signal, _xlsCanTxSig):
                    self.Sigs.append(signal)
                    signal = "NoNeed"
                if ori_para == "(0)":
                    signal = "NoNeed"
                    continue
                else:
                    signal = _xlsCanTxSig()
                    start_byte = get_true_number(str(row["Start Byte"]).strip())
                    bit = str(row["Bit"]).strip().replace(".0", "")

                    if bit == "-":
                        signal.StartBit = (int(start_byte) - 1) * 8
                        signal.Len = signal.Len + 8
                    else:
                        signal.StartBit = (int(start_byte) - 1) * 8 + (8 - int(bit[0]))
                        if bit.isdigit():
                            signal.Len = signal.Len + 1
                        else:
                            signal.Len = signal.Len + eval(bit) + 1

                    if ori_para == "always0":
                        signal.Para = (
                            row["Parameter (Padding)"]
                            + "_Byte_"
                            + start_byte
                            + "_"
                            + bit[0]
                        )
                    else:
                        signal.Para = row["Parameter (Padding)"]

                    signal.Desc = row["Description"]
                    signal.Unit = row["Unit"]
                    signal.LSB = get_true_number(str(row["LSB"]).strip())
                    signal.Offset = get_true_number(str(row["Offset"]).strip())
                    signal.Min = get_true_number(str(row["Min"]).strip())
                    signal.Max = get_true_number(str(row["Max"]).strip())
                    signal.InvSta = row["Invalid Status"]
                    signal.ErrIndVal = row["Error Indicator Value"]
            else:
                if ori_para == "(0)":
                    continue
                else:
                    bit = str(row["Bit"]).strip().replace(".0", "")

                    if bit == "-":
                        signal.Len = signal.Len + 8
                    else:
                        if bit.isdigit():
                            signal.Len = signal.Len + 1
                        else:
                            signal.Len = signal.Len + eval(bit) + 1


# %%
class xlsDatabase:
    def __init__(self) -> None:
        self.MsgList = []
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
        xls_end_row = b_col_data.index(xls_end) + 1

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
class ecuDbc:
    def __init__(self):
        self.Content = ""
        with open("dbcHeader.txt", "r") as h_f:
            self.Header = h_f.read()
        with open("dbcTail.txt", "r") as t_f:
            self.Tail = t_f.read()

    def load(self, xls_db):
        can_type = xls_db.CanType
        if can_type == "ISOCAN":
            # motorola
            self.ByteOder = 0
            rx_normal_info, rx_normal_desc = self.get_msg_content(
                xls_db.RxNormal, "Other", "ECU"
            )
            tx_normal_info, tx_normal_desc = self.get_msg_content(
                xls_db.TxNormal, "ECU", "Other"
            )

            self.Content = (
                self.Content
                + rx_normal_info
                + tx_normal_info
                + rx_normal_desc
                + tx_normal_desc
            )

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
        for i_msg in msgs:
            info_content = info_content + "BO_ {} ECU_0x{}: 8 {}".format(
                str(int(i_msg.CanID, 16)), i_msg.CanID, tx_ecu
            )
            info_content = info_content + "\n"

            desc_content = desc_content + 'CM_ BO_ {} "{}";'.format(
                str(int(i_msg.CanID, 16)), i_msg.FrameDesc
            )
            desc_content = desc_content + "\n"

            for i_sig in i_msg.Sigs:
                info_content = (
                    info_content
                    + ' SG_ {} : {}|{}@{}+ ({},{}) [{}|{}] "{}"  {}'.format(
                        i_sig.Para,
                        self.calclate_start_bit(i_sig.StartBit),
                        str(i_sig.Len),
                        self.ByteOder,
                        i_sig.LSB,
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
        return info_content, desc_content

    def calclate_start_bit(self, startbit):
        if self.ByteOder == 0:
            # (int(startbit / 8) + 1) * 8 - (a - int(startbit / 8) * 8 + 1)
            startbit = 16 * int(startbit / 8) + 7 - startbit
            return str(startbit)
        elif self.ByteOder == 1:
            return str(startbit)

    def generate_dbc(self):
        with open("ecuDbc.dbc", "w") as db_f:
            db_f.write(self.Header + "\n" + self.Content + "\n" + self.Tail)


# %%
xlsDB = xlsDatabase()
xlsDB.load("test.xlsx", "ISOCAN")

dbc = ecuDbc()
dbc.load(xlsDB)
dbc.generate_dbc()