import ConfirmModal from "@/components/common/ConfirmModal";
import useData from "@/hooks/useData";
import { Warehouse } from "@/types/index.type";
import { fetchNui } from "@/utils/fetchNui";
import { useState } from "react";
import { useTranslation } from "react-i18next";
import { MoneyWashingModal } from "./MoneyWashingModal";

type WorkingInfoProps = {
  warehouse: Warehouse;
};

const WorkingInfo = ({ warehouse }: WorkingInfoProps) => {
  const { t } = useTranslation();
  const { Config } = useData();

  const [isSleep, setSleep] = useState<boolean>(false);

  const [activeModal, setActiveModal] = useState<string | undefined>();

  const handleToggleWorking = async () => {
    if (isSleep) return;
    setSleep(true);
    await fetchNui("nui:warehouse:toggleWorking", true, true);
    setTimeout(() => setSleep(false), 1000);
  };

  const handleOpenModal = () => {
    if (warehouse.meta.money_washing_level == 0)
      return setActiveModal("upgrade_money_washing");
    else return setActiveModal("info_money_washing");
  };

  const handleUpgradeMoneyWashing = async () => {
    if (isSleep) return;
    setSleep(true);
    setActiveModal(undefined);
    await fetchNui("nui:moneywashing:upgrade", true, true);
    setSleep(false);
  };

  const renderModal = (f?: string) => {
    switch (f != undefined ? f : activeModal) {
      case "upgrade_money_washing":
        return (
          <ConfirmModal
            title={
              t(`modal_upgrade_money_washing_title`) +
              " " +
              t("money_type") +
              Config.MoneyWashingUpgrades[warehouse.meta.money_washing_level]
                ?.price
            }
            message={t(`modal_money_washing_desc`, {
              level: warehouse.meta.money_washing_level + 1,
            })}
            onClose={() => setActiveModal(undefined)}
            onConfirm={handleUpgradeMoneyWashing}
          />
        );
      case "info_money_washing":
        return (
          <MoneyWashingModal
            warehouse={warehouse}
            onClose={() => setActiveModal(undefined)}
          />
        );
      default:
        return <></>;
    }
  };

  return (
    <>
      <div className="px-2.5 py-3 flex flex-col gap-1">
        <h1 className="text-white/55 text-shadow-adez font-primary text-sm">
          {t("working_info")}
        </h1>
        <h1 className="text-xs text-white/55 font-primary">
          {t("desc_working_info")}
        </h1>
        <div className="flex items-center justify-between gap-2 mt-0.5">
          <button
            onClick={handleToggleWorking}
            className="bg-20846D/30 text-1EE8B6/80 font-primary w-full rounded-sm border border-transparent hover:border-1EE8B6 transition-colors py-1"
          >
            <h1 className="text-sm font-primary font-medium">
              {!warehouse.meta.is_working
                ? t("start_working")
                : t("stop_working")}
            </h1>
          </button>
          <button
            onClick={handleOpenModal}
            className="bg-ff6b6b/15 text-ff6b6b/80 font-primary w-full rounded-sm border border-transparent hover:border-ff6b6b transition-colors py-1 disabled:opacity-50"
          >
            <h1 className="text-sm font-primary font-medium whitespace-nowrap">
              {warehouse.meta.money_washing_level == 0 && t("buy") + " "}
              {t("black_money_washing")}
            </h1>
          </button>
        </div>
      </div>
      {activeModal && renderModal()}
    </>
  );
};

export default WorkingInfo;
