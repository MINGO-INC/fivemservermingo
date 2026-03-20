import { fetchNui } from "@/utils/fetchNui";
import { HTMLAttributes, useEffect, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { GrDocumentUpdate } from "react-icons/gr";
import { PiNotePencilFill } from "react-icons/pi";

type WarehouseNameProps = {
  houseName: string;
} & HTMLAttributes<HTMLDivElement>;

const WarehouseName: React.FC<WarehouseNameProps> = ({
  houseName,
  ...props
}) => {
  const { t } = useTranslation();

  const warehouseNameRef = useRef<HTMLInputElement | null>(null);
  const [isNameChangeable, setNameChangeable] = useState<boolean>(false);

  const [wHouseName, setWHouseName] = useState<string | null>(houseName);

  const handleClickNameChangeable = async () => {
    if (isNameChangeable) {
      if (wHouseName !== houseName) {
        await fetchNui("nui:updateCurrentWarehouseName", wHouseName, true);
      }
    }
    setNameChangeable(!isNameChangeable);
  };

  useEffect(() => {
    setWHouseName(houseName);
    return () => {
      setWHouseName(null);
    };
  }, [houseName]);

  useEffect(() => {
    if (isNameChangeable && warehouseNameRef) {
      warehouseNameRef.current?.focus();
    }
  }, [isNameChangeable]);

  return (
    <div
      className="relative rounded-sm border border-202020 bg-black/25 flex flex-col justify-center px-3 py-2"
      {...props}
    >
      <h1 className="text-white/55 text-xs font-primary text-shadow-adez">
        {t("business_name")}
      </h1>
      <input
        ref={warehouseNameRef}
        className="text-white text-sm font-primary whitespace-nowrap overflow-hidden bg-transparent outline-none ring-0"
        onChange={(e) => setWHouseName(e.currentTarget.value)}
        value={wHouseName ?? ""}
        autoFocus={isNameChangeable}
        disabled={!isNameChangeable}
      />
      <button
        className="absolute top-1 right-1"
        onClick={handleClickNameChangeable}
      >
        {isNameChangeable ? (
          <GrDocumentUpdate className="text-1EE8B6/80" />
        ) : (
          <PiNotePencilFill className="text-white/25" />
        )}
      </button>
    </div>
  );
};

export default WarehouseName;
