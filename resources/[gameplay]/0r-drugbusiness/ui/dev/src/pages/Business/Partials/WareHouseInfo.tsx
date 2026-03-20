import { Warehouse } from "@/types/index.type";
import { useTranslation } from "react-i18next";

type WarehouseInfoType = {
  warehouse: Warehouse;
};

const WarehouseInfo = ({ warehouse }: WarehouseInfoType) => {
  const { t } = useTranslation();

  return (
    warehouse && (
      <div className="flex items-center gap-1.5 mr-6">
        <div className="flex flex-col items-end">
          <div className="flex gap-1 text-sm font-primary">
            <h1 className="first-letter:uppercase text-white/55 text-shadow-adez">
              {warehouse.business_theme}
            </h1>
            <h1 className="text-white/55 font-primary">{t("business")}</h1>
          </div>
          <div className="flex flex-col items-end -mt-1">
            <h1 className="font-primary text-sm text-shadow-adez">
              {warehouse.name}
            </h1>
            <div className="relative flex flex-col h-0.5 bg-white/30 w-32 overflow-hidden">
              <div
                className="absolute inset-0 bg-1EE8B6/80"
                style={{
                  width:
                    Math.floor(
                      (warehouse.experience / warehouse.nextLeveLExp) * 100
                    ) + "%",
                }}
              ></div>
            </div>
            <div className="flex items-center justify-between mt-0.5 w-32">
              <h1 className="text-xs text-white/75">
                {t("level")} {warehouse.level}
              </h1>
              <h1 className="text-xs text-white/75">
                {warehouse.experience} {t("exp")}
              </h1>
            </div>
          </div>
        </div>
        <div
          className="w-16 min-w-16 h-16 min-h-16 rounded-sm border border-202020 p-1 flex items-center justify-center"
          style={{
            background:
              "radial-gradient(94.07% 94.07% at 50% 5.93%, rgba(255, 255, 255, 0.13) 0%, rgba(153, 153, 153, 0.04) 100%)",
          }}
        >
          <img src="images/icons/warehouse.png" alt="warehouseinfo-warehouse" />
        </div>
      </div>
    )
  );
};

export default WarehouseInfo;
