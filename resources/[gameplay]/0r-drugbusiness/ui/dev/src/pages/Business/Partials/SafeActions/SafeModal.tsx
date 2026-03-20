import { Warehouse } from "@/types/index.type";
import { useTranslation } from "react-i18next";
import { PiMoneyWavyBold } from "react-icons/pi";
import { CgSmartHomeWashMachine } from "react-icons/cg";
import { Tooltip } from "@mui/material";
import { GiCube } from "react-icons/gi";
import { useEffect, useState } from "react";

type SafeModalProps = {
  warehouse: Warehouse;
  onConfirm: (
    data: { selectedItem?: string; amount: string },
    action: "withdraw" | "deposit"
  ) => void;
};

export const SafeModal = ({ warehouse, onConfirm }: SafeModalProps) => {
  const { t } = useTranslation();

  const [selectedItem, setItem] = useState<string | undefined>();
  const [amount, setAmount] = useState<string>("");

  const options = ["packaged_product", "clean_money", "dirty_money"];

  useEffect(() => {
    setAmount("");
  }, [selectedItem]);

  return (
    <div className="flex flex-col gap-3">
      <div className="flex items-center justify-between gap-3">
        <Tooltip title={t("clean_money")}>
          <div className="w-full flex items-center justify-between px-2 py-2.5 border border-202020">
            <div className="flex items-center gap-1">
              <PiMoneyWavyBold className="text-1EE8B6" />
            </div>
            <h1 className="text-sm font-sfmono font-medium text-1EE8B6">
              {warehouse.clean_money}
              <span className="text-white">{" " + t("money_type")}</span>
            </h1>
          </div>
        </Tooltip>
        <Tooltip title={t("dirty_money")}>
          <div className="w-full flex items-center justify-between px-2 py-2.5 border border-202020">
            <h1 className="text-sm font-sfmono font-medium text-ff6b6b">
              <span className="text-white">{t("money_type") + " "}</span>
              {warehouse.dirty_money}
            </h1>
            <div className="flex items-center gap-1">
              <CgSmartHomeWashMachine className="text-ff6b6b w-5 h-5" />
            </div>
          </div>
        </Tooltip>
      </div>
      <Tooltip title={t("packaged_product")}>
        <div className="w-full flex items-center justify-between px-2 py-2.5 border border-202020">
          <div className="flex items-center gap-1">
            <GiCube className="text-white w-5 h-5" />
            <h1 className="text-sm font-primary text-white">
              {t("packaged_product")}
            </h1>
          </div>
          <h1 className="text-sm font-primary text-white">
            {warehouse.packaged_product_stock +
              " / " +
              warehouse.meta.max_package_stock +
              " " +
              t("piece")}
          </h1>
        </div>
      </Tooltip>
      <hr className="border-202020" />
      <div className="w-full text-sm">
        <label>{t("select_item")}</label>
        <select
          className="w-full border border-white/15 p-3 rounded-sm mt-1 outline-none ring-0 focus:border-white/50 bg-0c0c0c placeholder:text-white/25 text-white"
          value={selectedItem || ""}
          onChange={(e) => setItem(e.target.value)}
        >
          <option
            value=""
            disabled
            className="!bg-0c0c0c checked:!bg-151515 hover:!bg-202020 !rounded-none"
          >
            {"..."}
          </option>
          {options.map((item) => (
            <option
              key={item}
              value={item}
              className="!bg-0c0c0c checked:!bg-151515 hover:!bg-202020 !rounded-none"
            >
              {t(item)}
            </option>
          ))}
        </select>
      </div>
      <div className="w-full text-sm">
        <label>{t("enter_amount")}</label>
        <input
          type="number"
          className="w-full border border-white/15 p-2.5 mt-1 outline-none ring-0 focus:border-white/50 bg-0c0c0c placeholder:text-white/25 text-white"
          value={amount}
          onChange={(e) =>
            setAmount(parseInt(e.target.value || "0").toString())
          }
        />
      </div>
      <div className="flex items-center justify-center gap-2 mt-1">
        <button
          onClick={() => {
            onConfirm({ selectedItem, amount }, "withdraw");
            setAmount("");
          }}
          className="w-full p-1.5 text-sm text-center bg-[#00d2a0]/20 text-[#29ba99] border border-transparent hover:border-[#29ba99] transition-colors"
          disabled={!selectedItem || !amount}
        >
          {t("withdraw")}
        </button>
        <button
          onClick={() => {
            onConfirm({ selectedItem, amount }, "deposit");
            setAmount("");
          }}
          className="w-full p-1.5 text-sm text-center bg-orange-500/20 text-orange-500 border border-transparent hover:border-orange-500 transition-colors"
          disabled={!selectedItem || !amount}
        >
          {t("deposit")}
        </button>
      </div>
    </div>
  );
};
