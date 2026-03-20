import ModalComponent from "@/components/common/Modal";
import useData from "@/hooks/useData";
import { Warehouse } from "@/types/index.type";
import { useTranslation } from "react-i18next";
import { FaMoneyBill } from "react-icons/fa";
import { RxUpdate } from "react-icons/rx";
import { GiWashingMachine } from "react-icons/gi";
import { fetchNui } from "@/utils/fetchNui";
import { useState } from "react";
import ConfirmModal from "@/components/common/ConfirmModal";

type ModalProps = {
  onClose: () => void;
  warehouse: Warehouse;
};

export const MoneyWashingModal = (p: ModalProps) => {
  const { t } = useTranslation();
  const { Config, isSleep, setSleep } = useData();
  const [activeConfirmModal, setActiveModal] = useState<boolean>(false);

  const handleUpgradeMoneyWashing = async () => {
    if (isSleep) return;
    setActiveModal(false);
    setSleep(true);
    await fetchNui("nui:moneywashing:upgrade", true, true);
    setSleep(false);
  };

  return (
    <ModalComponent
      onClose={p.onClose}
      open
      width={420}
      title={t("black_money_washing") + " " + t("info")}
    >
      <div
        className="relative w-full h-[1px] mb-3 rounded-full"
        style={{
          background:
            "radial-gradient(circle, rgba(68,68,68,1) 50%, rgba(68,68,68,0.4990371148459384) 75%, rgba(68,68,68,0.24693627450980393) 90%, rgba(68,68,68,0) 100%)",
        }}
      >
        <div className="absolute w-2/3 h-[1px] bg-1EE8B6 left-1/2 -translate-x-1/2 rounded-full"></div>
      </div>
      <div className="flex flex-col gap-3 items-center">
        <h1 className="text-1EE8B6 font-primary font-medium tracking-wider">
          {t("money_inside")}
        </h1>
        <div className="flex gap-1">
          <div className="border-1EE8B6/80 w-12 h-20 flex items-center justify-center border bg-1EE8B6/15">
            <h1 className="font-primary text-2xl text-1EE8B6">
              {t("money_type")}
            </h1>
          </div>
          {Array.from(
            Math.min(99999, p.warehouse.dirty_money).toString().padStart(4, "0")
          ).map((digit, i) => (
            <div
              key={i}
              className="border-1EE8B6/80 w-12 h-20 flex items-center justify-center border bg-1EE8B6/15"
            >
              <h1 className="font-primary text-1EE8B6 text-2xl">{digit}</h1>
            </div>
          ))}
        </div>
      </div>
      <div
        className="relative w-full h-[1px] my-3 mt-6 rounded-full"
        style={{
          background:
            "radial-gradient(circle, rgba(68,68,68,1) 50%, rgba(68,68,68,0.4990371148459384) 75%, rgba(68,68,68,0.24693627450980393) 90%, rgba(68,68,68,0) 100%)",
        }}
      >
        <div className="absolute w-2/3 h-[1px] bg-1EE8B6 left-1/2 -translate-x-1/2 rounded-full"></div>
      </div>
      <div className="flex flex-col gap-3 items-center mb-4">
        <h1 className="text-1EE8B6 font-primary font-medium tracking-wider">
          {t("info")}
        </h1>
        <div className="flex items-center justify-between w-full px-4">
          <div className="flex gap-6">
            <div className="flex items-center gap-2">
              <div
                className="w-14 h-14 min-w-14 min-h-14 flex items-center justify-center p-1 rotate-45 shadow-[2px_-2px_0_0] shadow-1EE8B6"
                style={{
                  background:
                    "radial-gradient(94.07% 94.07% at 50% 5.93%, rgba(255, 255, 255, 0.1) 0%, rgba(153, 153, 153, 0.04) 100%)",
                }}
              >
                <FaMoneyBill className="w-7 h-7 -rotate-45 text-1EE8B6" />
              </div>
            </div>
            <div className="flex flex-col gap-1">
              <h1 className="text-sm font-primary tracking-wider font-medium">
                {t("outcome")}
              </h1>
              <h1 className="text-1EE8B6 text-sm whitespace-nowrap font-primary tracking-wider font-medium">
                {t("money_type") +
                  (Config.MoneyWashingUpgrades[
                    p.warehouse.meta.money_washing_level - 1
                  ]?.productionPerMin || "0") +
                  "/m"}
              </h1>
            </div>
          </div>
          <div className="flex gap-6">
            <div className="flex items-center gap-2">
              <div
                className="w-14 h-14 min-w-14 min-h-14 flex items-center justify-center p-1 rotate-45 shadow-[2px_-2px_0_0] shadow-1EE8B6"
                style={{
                  background:
                    "radial-gradient(94.07% 94.07% at 50% 5.93%, rgba(255, 255, 255, 0.1) 0%, rgba(153, 153, 153, 0.04) 100%)",
                }}
              >
                <RxUpdate className="w-7 h-7 -rotate-45 text-1EE8B6" />
              </div>
            </div>
            <div className="flex flex-col gap-1">
              <h1 className="text-sm font-primary tracking-wider font-medium">
                {t("working")}
              </h1>
              <h1 className="text-1EE8B6 text-sm whitespace-nowrap font-primary tracking-wider font-medium">
                {t("on")}
              </h1>
            </div>
          </div>
        </div>
      </div>
      <div
        className="relative w-full h-[1px] my-3 mt-9 rounded-full"
        style={{
          background:
            "radial-gradient(circle, rgba(68,68,68,1) 50%, rgba(68,68,68,0.4990371148459384) 75%, rgba(68,68,68,0.24693627450980393) 90%, rgba(68,68,68,0) 100%)",
        }}
      >
        <div className="absolute w-2/3 h-[1px] bg-1EE8B6 left-1/2 -translate-x-1/2 rounded-full"></div>
      </div>
      <div className="flex flex-col gap-3 items-center mb-4">
        <h1 className="text-1EE8B6 font-primary font-medium tracking-wider">
          {t("setup")}
        </h1>
        <div className="flex items-center justify-center w-full px-4">
          <div className="flex gap-6">
            <div className="flex items-center gap-2">
              <div
                className="w-14 h-14 min-w-14 min-h-14 flex items-center justify-center p-1 rotate-45 shadow-[2px_-2px_0_0] shadow-1EE8B6"
                style={{
                  background:
                    "radial-gradient(94.07% 94.07% at 50% 5.93%, rgba(255, 255, 255, 0.1) 0%, rgba(153, 153, 153, 0.04) 100%)",
                }}
              >
                <GiWashingMachine className="w-7 h-7 -rotate-45 text-1EE8B6" />
              </div>
            </div>
            <div className="flex flex-col gap-1">
              <h1 className="text-sm font-primary tracking-wider font-medium">
                {t("machine_level")}
              </h1>
              <h1 className="text-1EE8B6 text-sm whitespace-nowrap font-primary tracking-wider font-medium">
                {p.warehouse.meta.money_washing_level + "x"}
              </h1>
            </div>
          </div>
        </div>
      </div>
      <div className="flex items-center justify-center mt-8 gap-6">
        <button
          onClick={() => setActiveModal(true)}
          className="mt-4 py-2 px-8 bg-[#1EE8B6]/15 border border-[#1EE8B6]/80 hover:border-[#1EE8B6]/80 transition-colors hover:bg-[#1EE8B6]/80/50"
        >
          <h1 className="uppercase font-bold font-primary tracking-wide text-sm">
            {t("upgrade")}
          </h1>
        </button>
        <button
          onClick={p.onClose}
          className="mt-4 py-2 px-8 bg-[#FF6767]/15 border border-[#FF6B6B]/80 hover:border-[#FF6B6B]/80 transition-colors hover:bg-[#FF6B6B]/80/50"
        >
          <h1 className="uppercase font-bold font-primary tracking-wide text-sm">
            {t("close")}
          </h1>
        </button>
      </div>
      {activeConfirmModal &&
        Config.MoneyWashingUpgrades[p.warehouse.meta.money_washing_level] && (
          <ConfirmModal
            title={
              t(`modal_upgrade_money_washing_title`) +
              " " +
              t("money_type") +
              Config.MoneyWashingUpgrades[p.warehouse.meta.money_washing_level]
                ?.price
            }
            message={t(`modal_money_washing_desc`, {
              level: p.warehouse.meta.money_washing_level + 1,
            })}
            onClose={() => setActiveModal(false)}
            onConfirm={handleUpgradeMoneyWashing}
          />
        )}
    </ModalComponent>
  );
};
