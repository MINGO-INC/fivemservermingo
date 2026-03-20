import useData from "@/hooks/useData";
import { fetchNui } from "@/utils/fetchNui";
import { useTranslation } from "react-i18next";

const ProcureRawMaterials = () => {
  const { t } = useTranslation();
  const { setSleep, isSleep } = useData();

  const handleStartDrugSaleMission = async () => {
    if (isSleep) return;
    setSleep(true);
    await fetchNui("nui:salemission:start", true, true);
    setSleep(false);
  };

  const handleStartRawCollection = async () => {
    if (isSleep) return;
    setSleep(true);
    await fetchNui("nui:rawmaterials:startCollection", true, true);
    setSleep(false);
  };

  return (
    <>
      <div className="flex flex-col mt-3">
        <h1 className="font-primary text-white/55 text-sm mb-3 text-shadow-adez">
          {t("raw_materials_and_drug_sale")}
        </h1>
        <div className="flex gap-2 items-center">
          <div
            className="relative w-14 h-14 min-w-14 min-h-14 flex items-center justify-center"
            style={{
              borderRadius: "2px",
              border: "1px solid #202020",
              background:
                "radial-gradient(94.07% 94.07% at 50% 5.93%, rgba(255, 255, 255, 0.13) 0%, rgba(153, 153, 153, 0.04) 100%)",
            }}
          >
            <img
              className="absolute w-12"
              src="images/icons/drug_veh.png"
              alt="drug_veh"
            />
          </div>
          <div className="flex flex-col">
            <h1 className="text-sm font-primary text-shadow-adez text-white/55">
              {t("information")}
            </h1>
            <h1 className="text-xs text-white/45 font-primary">
              {t("desc_raw_materials_and_drug_sale")}
            </h1>
          </div>
        </div>
        <div className="flex items-center gap-2 mt-4">
          <button
            onClick={handleStartRawCollection}
            className="py-1 w-full bg-20846D/30 border border-transparent hover:border-1EE8B6 transition-colors text-1EE8B6/80 rounded-sm"
          >
            <h1 className="text-sm font-primary font-medium">
              {t("start_collection")}
            </h1>
          </button>
          <button
            onClick={handleStartDrugSaleMission}
            className="py-1 w-full bg-[#FF6767]/15 border border-transparent hover:border-[#FF6B6B]/80 transition-colors text-[#FF6B6B]/80 rounded-sm"
          >
            <h1 className="text-sm font-primary font-medium">
              {t("sale_mission")}
            </h1>
          </button>
        </div>
      </div>
    </>
  );
};

export default ProcureRawMaterials;
