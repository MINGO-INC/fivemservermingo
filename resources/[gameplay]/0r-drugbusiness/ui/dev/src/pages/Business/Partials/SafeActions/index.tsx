import ModalComponent from "@/components/common/Modal";
import { useState } from "react";
import { useTranslation } from "react-i18next";
import { SafeModal } from "./SafeModal";
import { Warehouse } from "@/types/index.type";
import useData from "@/hooks/useData";
import { fetchNui } from "@/utils/fetchNui";
import { TbLoader } from "react-icons/tb";

interface SafeActionsProps {
  warehouse: Warehouse;
}

const SafeActions = ({ warehouse }: SafeActionsProps) => {
  const { t } = useTranslation();
  const { isSleep, setSleep } = useData();

  const [isModalOpen, setModalOpen] = useState<boolean>(false);

  const handleOpenSafeModal = () => setModalOpen(!isModalOpen);

  const { dirty_money, clean_money } = warehouse;

  const handleAction = async (data: any, action: "withdraw" | "deposit") => {
    if (isSleep) return;
    setSleep(true);
    await fetchNui(
      `nui:safeactions:${action}`,
      {
        type: data.selectedItem,
        amount: parseInt(data.amount),
        action: action,
      },
      true,
      1000
    );
    setSleep(false);
  };

  return (
    <>
      <div className="relative w-full h-full pb-3 pt-6 px-2.5 flex flex-col gap-2.5 items-end">
        <div className="flex gap-2">
          <div
            className="relative w-24 h-24 min-w-24 min-h-24 border border-202020 p-1 rounded-sm"
            style={{
              background:
                "radial-gradient(94.07% 94.07% at 50% 5.93%, rgba(255, 255, 255, 0.13) 0%, rgba(153, 153, 153, 0.04) 100%)",
            }}
          >
            <img src="images/icons/bank.png" alt="bank" />
          </div>
          <div className="flex flex-col font-primary max-h-32 overflow-auto scrollbar-hidden">
            <h1 className="text-shadow-adez text-sm font-medium">
              {t("safe_actions")}
            </h1>
            <h1 className="text-sm text-shadow-adez text-white/55">
              {t("desc_safe_actions")}
            </h1>
            <h1 className="mt-auto text-xs text-white/55 mb-0.5">
              {t("info_safe_actions")}
            </h1>
          </div>
        </div>
        <button
          onClick={handleOpenSafeModal}
          className="bg-20846D/30 text-1EE8B6/80 font-primary rounded-sm border border-transparent hover:border-1EE8B6 transition-colors py-1 px-6"
        >
          <h1 className="text-[13px] font-primary font-medium tracking-wider">
            {t("open_safe")}
          </h1>
        </button>
        <div className="absolute top-3 right-3 flex items-center gap-2">
          <div className="flex flex-col items-center gap-0.5 py-0.5 px-3 bg-[#FF7E88]/15 text-[#FF6B6B]/80 text-xs font-primary rounded-sm tracking-wider">
            <h1>{t("dirty_money")}</h1>
            <h1>{t("money_type") + dirty_money.toLocaleString()}</h1>
          </div>
          <div className="flex flex-col items-center gap-0.5 py-0.5 px-3 bg-[#20846D]/20 text-[#1EE8B6]/80 text-xs font-primary rounded-sm tracking-wider">
            <h1>{t("clean_money")}</h1>
            <h1>{t("money_type") + clean_money.toLocaleString()}</h1>
          </div>
        </div>
      </div>
      <ModalComponent
        open={isModalOpen}
        title={t("warehouse_safe")}
        onClose={() => setModalOpen(false)}
      >
        <SafeModal onConfirm={handleAction} warehouse={warehouse} />
        {isSleep && (
          <div className="flex items-center justify-center absolute inset-0 bg-black/50">
            <TbLoader className="w-10 h-10 animate-[spin_2s_linear_infinite]" />
          </div>
        )}
      </ModalComponent>
    </>
  );
};

export default SafeActions;
