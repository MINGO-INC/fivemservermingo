import { useTranslation } from "react-i18next";

type BuyModalProps = {
  onClose: () => void;
  onBuy: () => void;
  price: number;
  label: string;
};

const BuyModal: React.FC<BuyModalProps> = ({
  onClose,
  onBuy,
  price,
  label,
}) => {
  const { t } = useTranslation();

  return (
    <div className="w-full h-full bg-0c0c0c/50 flex items-center justify-center">
      <div className="min-h-[180px] w-96 bg-0c0c0c p-3 border border-202020 flex">
        <div className="w-full flex gap-2 flex-col items-center justify-between border border-white/15 rounded-sm p-3">
          <h1
            className="font-sfpro font-bold text-[#29BA99] uppercase text-xl"
            style={{ textShadow: "0px 0px 20.059px rgba(60, 243, 196, 0.53)" }}
          >
            {t("purchase") + " " + t("money_type") + price?.toLocaleString()}
          </h1>
          <h1 className="text-center text-sm font-gilroy text-white/50">
            <span className="font-medium">{label}</span>
            {", " + t("desc_buy_any")}
          </h1>
          <div className="flex items-center justify-center gap-5">
            <button
              onClick={onBuy}
              className="w-32 p-1.5 text-xs text-center bg-[#00d2a0]/20 text-[#29ba99] border border-transparent hover:border-[#29ba99] transition-colors"
            >
              {t("buy")}
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

export default BuyModal;
