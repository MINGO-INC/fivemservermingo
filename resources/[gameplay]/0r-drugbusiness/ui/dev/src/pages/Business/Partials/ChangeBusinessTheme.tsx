import ConfirmModal from "@/components/common/ConfirmModal";
import useData from "@/hooks/useData";
import { BusinessTypeString } from "@/types/index.type";
import { fetchNui } from "@/utils/fetchNui";
import classNames from "classnames";
import { useState } from "react";
import { useTranslation } from "react-i18next";

type ChangeBusinessThemeProps = {
  currentTheme: BusinessTypeString;
  warehouseLevel: number;
};

const ChangeBusinessTheme = ({
  currentTheme,
  warehouseLevel,
}: ChangeBusinessThemeProps) => {
  const { t } = useTranslation();
  const { Config, isSleep, setSleep } = useData();

  const isThemeLocked = (level: number) => warehouseLevel < level;
  const [isModalOpen, setModalOpen] = useState<boolean>(false);
  const [selectedTheme, setSelectedTheme] = useState<BusinessTypeString>();

  const handleThemeUpdate = async () => {
    if (isSleep || selectedTheme === currentTheme) return;
    setSleep(true);
    await fetchNui("nui:updateCurrentWarehouseTheme", selectedTheme, true);
    setSelectedTheme(undefined);
    setSleep(false);
  };

  const handleOpenModal = (type: BusinessTypeString) => {
    setSelectedTheme(type);
    setModalOpen(!isModalOpen);
  };

  const handleCloseModal = () => {
    setModalOpen(false);
    setSelectedTheme(undefined);
  };

  return (
    <>
      <div className="flex flex-col gap-2">
        <h1 className="font-primary text-sm text-white/55 text-shadow-adez">
          {t("change_business_theme")}
        </h1>
        <div className="flex">
          {Config?.BusinessTypes?.map((type, index) => {
            const isSelected = type.key === currentTheme;
            const isLocked = isThemeLocked(type.requiredLevel);

            return (
              <div
                onClick={() =>
                  !isSelected && !isLocked && handleOpenModal(type.key)
                }
                key={index}
                className={classNames(
                  "relative flex flex-col gap-1 mr-1 group",
                  {
                    "cursor-pointer": !isSelected && !isLocked,
                  }
                )}
              >
                {/* Theme Image and Label */}
                <div className="relative flex items-center justify-center">
                  <img
                    className="w-full"
                    src={`images/common/type_${type.key}.png`}
                    alt={`${type.label} theme`}
                  />
                  <h1 className="absolute bottom-0 left-0.5 z-10 text-xs font-medium font-sfpro text-white/25">
                    {type.label}
                  </h1>

                  {/* Overlay for selection state */}
                  <div
                    className={classNames(
                      "absolute inset-0 z-0 transition-opacity",
                      {
                        "bg-black/75": !isSelected,
                        "opacity-0": isSelected,
                        "group-hover:opacity-0": !isSelected && !isLocked,
                      }
                    )}
                  />

                  {/* Lock overlay for unavailable themes */}
                  {!isSelected && isLocked && (
                    <div className="absolute inset-0 z-0 flex flex-col items-center justify-center">
                      <img
                        className="absolute"
                        src="images/icons/lock.png"
                        alt="locked"
                      />
                      <h1 className="mt-12 text-sm font-primary font-medium text-white/75">
                        {t("level")} {type.requiredLevel}
                      </h1>
                    </div>
                  )}
                </div>

                <div
                  className={classNames(
                    "flex items-center justify-center border border-transparent bg-20846D/30 py-1 text-1EE8B6/75 transition-colors",
                    {
                      "group-hover:border-1EE8B6 group-hover:text-1EE8B6":
                        !isSelected && !isLocked,
                    }
                  )}
                >
                  <h1 className="font-primary font-medium text-xs">
                    {isSelected
                      ? t("selected")
                      : `${t("buy")} ${type.price.toLocaleString()} ${t(
                          "money_type"
                        )}`}
                  </h1>
                </div>
              </div>
            );
          })}
        </div>
      </div>
      {selectedTheme && (
        <ConfirmModal
          onClose={handleCloseModal}
          onConfirm={handleThemeUpdate}
          message={t("modal_theme_update_desc", { theme: selectedTheme })}
          wait
        />
      )}
    </>
  );
};

export default ChangeBusinessTheme;
