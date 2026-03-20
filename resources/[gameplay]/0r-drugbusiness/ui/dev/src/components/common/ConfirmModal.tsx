import { CircularProgress } from "@mui/material";
import { useTranslation } from "react-i18next";
import { useState, useEffect } from "react";

type ConfirmModalProps = {
  onClose: () => void;
  onConfirm?: () => void;
  message?: string;
  loading?: boolean;
  title?: string;
  wait?: boolean;
};

const ConfirmModal: React.FC<ConfirmModalProps> = ({
  onClose,
  onConfirm,
  message,
  loading,
  title,
  wait,
}) => {
  const { t } = useTranslation();
  const [isButtonDisabled, setIsButtonDisabled] = useState(wait || false);
  const [countdown, setCountdown] = useState(5);

  useEffect(() => {
    if (wait) {
      setIsButtonDisabled(true);
      setCountdown(5);

      const timer = setInterval(() => {
        setCountdown((prev) => {
          if (prev <= 1) {
            clearInterval(timer);
            setIsButtonDisabled(false);
            return 0;
          }
          return prev - 1;
        });
      }, 1000);

      return () => clearInterval(timer); // Cleanup on unmount
    }
  }, [wait]);

  return (
    <div className="bg-0c0c0c/80 absolute inset-0 flex items-center justify-center z-[9990]">
      <div className="min-h-[180px] w-96 bg-0c0c0c p-3 border border-202020 flex">
        {!loading ? (
          <div className="w-full flex gap-2 flex-col items-center justify-between border border-white/15 rounded-sm p-3">
            <h1
              className="font-sfpro font-bold text-[#29BA99] uppercase text-xl text-center"
              style={{
                textShadow: "0px 0px 20.059px rgba(60, 243, 196, 0.53)",
              }}
            >
              {title ? title : t("confirm_action")}
            </h1>
            <h1 className="text-center text-sm font-gilroy text-white/50 py-1 pb-2">
              {message}
            </h1>
            <div className="flex items-center justify-center gap-5">
              {onConfirm && (
                <button
                  onClick={onConfirm}
                  disabled={isButtonDisabled}
                  className={`w-32 p-1.5 text-xs text-center bg-[#00d2a0]/20 text-[#29ba99] border border-transparent hover:border-[#29ba99] transition-colors ${
                    isButtonDisabled ? "opacity-50 cursor-not-allowed" : ""
                  }`}
                >
                  {isButtonDisabled
                    ? `${t("confirm")} (${countdown}s)`
                    : t("confirm")}
                </button>
              )}
              <button
                onClick={onClose}
                className="w-32 p-1.5 bg-[#ff5050]/20 text-xs text-center text-[#ff5050] border border-transparent hover:border-[#ff5050] transition-colors"
              >
                {t("cancel")}
              </button>
            </div>
          </div>
        ) : (
          <div className="flex items-center justify-center w-full">
            <CircularProgress disableShrink color="inherit" />
          </div>
        )}
      </div>
    </div>
  );
};

export default ConfirmModal;
