import useData from "@/hooks/useData";
import { fetchNui } from "@/utils/fetchNui";
import { useTranslation } from "react-i18next";
import { FaRegEye } from "react-icons/fa";

const Blip = () => {
  const { t } = useTranslation();
  const { isSleep, setSleep } = useData();

  const BlipColors = [
    { color: "#e03232", id: 1 },
    { color: "#71cb71", id: 2 },
    { color: "#5db6e5", id: 3 },
    { color: "#fefefe", id: 4 },
    { color: "#eec64e", id: 5 },
    { color: "#c25050", id: 6 },
    { color: "#9c6eaf", id: 7 },
    { color: "#fe7ac3", id: 8 },
  ];

  const handleUpdateWarehouseBlip = async (colorId: number) => {
    if (isSleep) return;
    setSleep(true);
    await fetchNui("nui:updateCurrentWarehouseBlipColor", colorId, true);
    setSleep(false);
  };

  const handleUpdateWarehouseBlipDisplay = async () => {
    await fetchNui("nui:updateCurrentWarehouseBlipHidden", true, true);
  };

  return (
    <div className="flex flex-col gap-1.5">
      <div className="flex items-center justify-between">
        <h1 className="font-primary text-white/55 text-sm text-shadow-adez">
          {t("update_blip")}
        </h1>
        <button
          onClick={handleUpdateWarehouseBlipDisplay}
          className="flex items-center gap-0.5 group"
        >
          <FaRegEye className="text-white/45 group-hover:text-white transition-colors" />
        </button>
      </div>
      <div className="flex items-center justify-around p-1 scrollbar-hidden rounded border border-202020 bg-[#080808]">
        {BlipColors.map((value, key) => (
          <button
            key={key}
            onClick={() => handleUpdateWarehouseBlip(value.id)}
            className="w-[42px] h-[42px] min-w-[42px] min-h-[42px] rounded-sm border border-202020"
            style={{ backgroundColor: value.color }}
          ></button>
        ))}
      </div>
    </div>
  );
};

export default Blip;
