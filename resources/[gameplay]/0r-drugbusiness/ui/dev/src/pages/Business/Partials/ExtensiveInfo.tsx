import { Warehouse } from "@/types/index.type";
import { useEffect, useState, useMemo } from "react";
import { useTranslation } from "react-i18next";
import { FaRegClock, FaPersonRunning } from "react-icons/fa6";
import { ImLab } from "react-icons/im";
import { IoCalendar } from "react-icons/io5";
import { GiCube, GiValve } from "react-icons/gi";
import { TbPackages } from "react-icons/tb";
import { BsCloudFog2Fill } from "react-icons/bs";
import { MdOutlineElectricalServices } from "react-icons/md";
import { FaTruckLoading } from "react-icons/fa";
import { AiOutlineLoading3Quarters } from "react-icons/ai";

interface ExtensiveInfoProps {
  warehouse: Warehouse | null;
}

const ExtensiveInfo = ({ warehouse }: ExtensiveInfoProps) => {
  const { t } = useTranslation();
  const [timeDifference, setTimeDifference] = useState<number>(0);

  const calculateTimeDifference = () => {
    if (!warehouse || !warehouse.meta.is_working) return 0;

    const currentTime = Date.now() / 1000;
    const {
      last_processed: lastProcessed,
      production_time: productionTime,
      meta: meta,
    } = warehouse;
    const nextProcess =
      (lastProcessed ?? meta?.last_working_at ?? 0) + productionTime;

    return Math.max(nextProcess - currentTime, 0);
  };

  useEffect(() => {
    if (!warehouse || !warehouse.meta.is_working) {
      setTimeDifference(0);
      return;
    }

    const updateTime = () => {
      const newTimeDiff = calculateTimeDifference();

      setTimeDifference(newTimeDiff);
    };

    updateTime();
    const interval = setInterval(updateTime, 1000);

    return () => clearInterval(interval);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [warehouse]);

  const minutesLeft = useMemo(
    () => Math.floor((timeDifference % 3600) / 60),
    [timeDifference]
  );

  const progressPercentage = useMemo(() => {
    if (!warehouse?.production_time || !warehouse?.meta.is_working) return 0;
    const totalTime = warehouse.production_time + 5;
    const elapsedTime = totalTime - timeDifference;

    return Math.max(0, Math.min((elapsedTime / totalTime) * 100, 100));
  }, [timeDifference, warehouse]);

  if (!warehouse) {
    return <></>;
  }

  return (
    <div className="flex flex-col h-full p-1.5 gap-2">
      <div className="bg-0c0c0c border border-202020 p-1 flex gap-1 items-center">
        <div
          className="w-20 h-20 min-w-20 min-h-20 border border-202020 rounded-sm flex items-center justify-center p-1"
          style={{
            background:
              "radial-gradient(94.07% 94.07% at 50% 5.93%, rgba(255, 255, 255, 0.13) 0%, rgba(153, 153, 153, 0.04) 100%)",
          }}
        >
          <img
            src="images/icons/warehouse.png"
            alt={t("warehouse_info_alt")}
            className="max-w-full max-h-full object-contain"
          />
        </div>
        <div className="flex flex-col overflow-hidden w-full">
          <h1 className="text-sm text-shadow-adez text-white/75 font-primary whitespace-nowrap text-ellipsis overflow-hidden">
            {t("current_progress_skill")}
          </h1>
          <div className="flex items-center gap-1 text-white/50 text-shadow-adez mt-[1px]">
            <FaRegClock className="w-3 min-w-3" />
            <h2 className="text-xs whitespace-nowrap">
              {warehouse.meta?.is_working
                ? minutesLeft > 0
                  ? minutesLeft + " " + t("production_time_left")
                  : t("almost_ready")
                : "..."}
            </h2>
          </div>
          <div className="flex items-center gap-1 w-full mt-auto">
            <div
              className="h-7 w-full relative border border-202020"
              style={{
                background:
                  "radial-gradient(94.07% 94.07% at 50% 5.93%, rgba(255, 255, 255, 0.13) 0%, rgba(153, 153, 153, 0.04) 100%)",
              }}
            >
              <div
                className="absolute inset-0"
                style={{
                  width: progressPercentage + "%",
                  background: "rgba(30, 232, 182, 0.33)",
                }}
              ></div>
            </div>
            <div className="flex flex-col items-center relative">
              {progressPercentage < 100 ? (
                <h1 className="text-xl text-shadow-adez">
                  {progressPercentage.toFixed(1)}
                  <span
                    hidden={progressPercentage >= 100}
                    className="text-sm text-white/50"
                  >
                    {"%"}
                  </span>
                </h1>
              ) : (
                <div className="relative flex items-center justify-center mx-2.5">
                  <FaTruckLoading className="w-4 h-4 text-1EE8B6" />
                  <AiOutlineLoading3Quarters className="absolute text-1EE8B6 w-8 h-8 animate-[spin_2s_linear_infinite]" />
                </div>
              )}
            </div>
          </div>
          <div>
            <h1 className="text-xs text-white/55 whitespace-nowrap text-ellipsis overflow-hidden">
              {t("you_will_earn")}
              <span className="text-1EE8B6/80">
                {" "}
                {warehouse.production_count}{" "}
              </span>
              {t("products")}
              {"."}
            </h1>
          </div>
        </div>
      </div>
      <div className="bg-0c0c0c border border-202020 p-1 flex gap-1 items-center">
        <div className="w-full flex flex-col gap-0.5">
          <div
            className="rounded-sm flex items-center justify-between p-1 px-1.5"
            style={{
              background:
                "radial-gradient(94.07% 94.07% at 50% 5.93%, rgba(255, 255, 255, 0.13) 0%, rgba(153, 153, 153, 0.04) 100%)",
            }}
          >
            <div className="flex items-center gap-1">
              <GiCube />
              <h1 className="text-xs font-sfpro">{t("packaged_product")}</h1>
            </div>
            <h1 className="text-xs font-sfpro">
              {warehouse.packaged_product_stock}
              {"/"}
              {warehouse.meta.max_package_stock} {t("piece")}
            </h1>
          </div>
          <div
            className="rounded-sm flex items-center justify-between p-1 px-1.5"
            style={{
              background:
                "radial-gradient(94.07% 94.07% at 50% 5.93%, rgba(255, 255, 255, 0.13) 0%, rgba(153, 153, 153, 0.04) 100%)",
            }}
          >
            <div className="flex items-center gap-1">
              <ImLab />
              <h1 className="text-xs font-sfpro">{t("lab_type")}</h1>
            </div>
            <h1 className="text-xs font-sfpro first-letter:uppercase">
              {warehouse.business_theme}
            </h1>
          </div>
          <div
            className="rounded-sm flex items-center justify-between p-1 px-1.5"
            style={{
              background:
                "radial-gradient(94.07% 94.07% at 50% 5.93%, rgba(255, 255, 255, 0.13) 0%, rgba(153, 153, 153, 0.04) 100%)",
            }}
          >
            <div className="flex items-center gap-1">
              <FaPersonRunning />
              <h1 className="text-xs font-sfpro">{t("total_employees")}</h1>
            </div>
            <h1 className="text-xs font-sfpro first-letter:uppercase">
              {warehouse.employee_count} {t("employees")}
            </h1>
          </div>
          <div
            className="rounded-sm flex items-center justify-between p-1 px-1.5"
            style={{
              background:
                "radial-gradient(94.07% 94.07% at 50% 5.93%, rgba(255, 255, 255, 0.13) 0%, rgba(153, 153, 153, 0.04) 100%)",
            }}
          >
            <div className="flex items-center gap-1">
              <IoCalendar />
              <h1 className="text-xs font-sfpro">{t("created_at")}</h1>
            </div>
            <h1 className="text-xs font-sfpro first-letter:uppercase">
              {new Date(warehouse.created_at).toLocaleDateString(undefined, {
                year: "numeric",
                month: "2-digit",
                day: "2-digit",
              })}
            </h1>
          </div>
        </div>
        <div
          className="w-[100px] h-[100px] min-w-[100px] min-h-[100px] border border-202020 rounded-sm flex items-center justify-center p-1"
          style={{
            background:
              "radial-gradient(94.07% 94.07% at 50% 5.93%, rgba(255, 255, 255, 0.13) 0%, rgba(153, 153, 153, 0.04) 100%)",
          }}
        >
          <img
            src="images/icons/supermarket.png"
            alt={t("supermarket")}
            className="max-w-full max-h-full object-contain"
          />
        </div>
      </div>
      <div className="bg-0c0c0c border border-202020 p-1 flex gap-1 items-center">
        <div className="w-full flex flex-col gap-0.5">
          <div
            className="rounded-sm flex items-center justify-between p-1 px-1.5"
            style={{
              background:
                "radial-gradient(94.07% 94.07% at 50% 5.93%, rgba(255, 255, 255, 0.13) 0%, rgba(153, 153, 153, 0.04) 100%)",
            }}
          >
            <div className="flex items-center gap-1">
              <TbPackages />
              <h1 className="text-xs font-sfpro">
                {t("raw_materials")} {t("stock")}
              </h1>
            </div>
            <h1 className="text-xs font-sfpro">
              {warehouse.raw_materials_stock}
              {"/"}
              {warehouse.meta.max_raw_materials_stock}
            </h1>
          </div>
          <div
            className="rounded-sm flex items-center justify-between p-1 px-1.5"
            style={{
              background:
                "radial-gradient(94.07% 94.07% at 50% 5.93%, rgba(255, 255, 255, 0.13) 0%, rgba(153, 153, 153, 0.04) 100%)",
            }}
          >
            <div className="flex items-center gap-1">
              <GiValve />
              <h1 className="text-xs font-sfpro">
                {t("water")} {t("stock")}
              </h1>
            </div>
            <h1 className="text-xs font-sfpro">
              {warehouse.water_stock}
              {"/"}
              {1000}
            </h1>
          </div>
          <div
            className="rounded-sm flex items-center justify-between p-1 px-1.5"
            style={{
              background:
                "radial-gradient(94.07% 94.07% at 50% 5.93%, rgba(255, 255, 255, 0.13) 0%, rgba(153, 153, 153, 0.04) 100%)",
            }}
          >
            <div className="flex items-center gap-1">
              <BsCloudFog2Fill />
              <h1 className="text-xs font-sfpro">
                {t("gas")} {t("stock")}
              </h1>
            </div>
            <h1 className="text-xs font-sfpro">
              {warehouse.gas_stock}
              {"/"}
              {1000}
            </h1>
          </div>
          <div
            className="rounded-sm flex items-center justify-between p-1 px-1.5"
            style={{
              background:
                "radial-gradient(94.07% 94.07% at 50% 5.93%, rgba(255, 255, 255, 0.13) 0%, rgba(153, 153, 153, 0.04) 100%)",
            }}
          >
            <div className="flex items-center gap-1">
              <MdOutlineElectricalServices />
              <h1 className="text-xs font-sfpro">
                {t("electricity")} {t("stock")}
              </h1>
            </div>
            <h1 className="text-xs font-sfpro">
              {warehouse.electricity_stock}
              {"/"}
              {1000}
            </h1>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ExtensiveInfo;
