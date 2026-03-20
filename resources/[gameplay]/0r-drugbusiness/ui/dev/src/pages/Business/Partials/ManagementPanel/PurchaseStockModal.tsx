import useData from "@/hooks/useData";
import { useState } from "react";
import { useTranslation } from "react-i18next";

type PurchaseStockModalProps = {
  onClose: () => void;
  onConfirm: (data: { selectedItem: string | null; amount: string }) => void;
  selectableItems: { id: string; name: string }[];
};

const PurchaseStockModal: React.FC<PurchaseStockModalProps> = ({
  onClose,
  onConfirm,
  selectableItems,
}) => {
  const { t } = useTranslation();
  const { Config } = useData();
  const [selectedItem, setSelectedItem] = useState<string | null>(null);
  const [amount, setAmount] = useState<string>("1");

  return (
    <div className="bg-0c0c0c/80 absolute inset-0 flex items-center justify-center z-[9990]">
      <div className="min-h-[220px] w-96 bg-0c0c0c p-3 border border-202020 flex">
        <div className="w-full flex gap-2 flex-col items-center justify-between border border-white/15 rounded-sm p-3">
          <h1
            className="font-sfpro font-bold text-[#29BA99] uppercase text-xl"
            style={{ textShadow: "0px 0px 20px rgba(60, 243, 196, 0.53)" }}
          >
            {t("purchase_storage")}
          </h1>

          <div className="w-full text-white/50 text-sm">
            <label>{t("select_item")}</label>
            <select
              className="w-full border border-white/15 p-3 rounded-sm mt-1 outline-none ring-0 focus:border-white/50"
              style={{
                background:
                  "radial-gradient(87.66% 87.66% at 50% 50%, rgba(255, 255, 255, 0.16) 0%, rgba(255, 255, 255, 0.00) 100%)",
              }}
              value={selectedItem || ""}
              onChange={(e) => setSelectedItem(e.target.value)}
            >
              <option
                value=""
                disabled
                className="!bg-0c0c0c checked:!bg-151515 hover:!bg-202020 !rounded-none"
              >
                {"..."}
              </option>
              {selectableItems.map((item) => (
                <option
                  key={item.id}
                  value={item.id}
                  className="!bg-0c0c0c checked:!bg-151515 hover:!bg-202020 !rounded-none"
                >
                  {item.name}{" "}
                  <span>
                    [{t("money_type") + Config.Stock[item.id]?.unit_price}]
                  </span>
                </option>
              ))}
            </select>
          </div>

          <div className="w-full text-white/50 text-sm">
            <label>{t("enter_amount")}</label>
            <input
              type="number"
              className="w-full border border-white/15 p-2.5 mt-1 outline-none ring-0 focus:border-white/50"
              value={amount}
              onChange={(e) =>
                setAmount(
                  Math.max(
                    1,
                    Math.min(1000, parseInt(e.target.value || "1"))
                  ).toString()
                )
              }
              style={{
                background:
                  "radial-gradient(87.66% 87.66% at 50% 50%, rgba(255, 255, 255, 0.16) 0%, rgba(255, 255, 255, 0.00) 100%)",
              }}
            />
          </div>
          {selectedItem && amount && (
            <h1 className="text-xs font-sfpro tracking-wider text-start w-full text-1EE8B6/80 border-b border-white/10 pb-1">
              {t("total_price") +
                ": " +
                (
                  parseInt(amount) * Config.Stock[selectedItem].unit_price
                ).toFixed(2) +
                t("money_type")}
            </h1>
          )}
          <div className="flex items-center justify-center gap-5 mt-1">
            <button
              onClick={() => onConfirm({ selectedItem, amount })}
              className="w-32 p-1.5 text-xs text-center bg-[#00d2a0]/20 text-[#29ba99] border border-transparent hover:border-[#29ba99] transition-colors"
              disabled={!selectedItem || !amount}
            >
              {t("confirm")}
            </button>
            <button
              onClick={onClose}
              className="w-32 p-1.5 bg-[#ff5050]/20 text-xs text-center text-[#ff5050] border border-transparent hover:border-[#ff5050] transition-colors"
            >
              {t("cancel")}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PurchaseStockModal;
