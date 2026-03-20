import { Slider } from "@mui/material";
import { Box, styled } from "@mui/system";
import { useState } from "react";
import { useTranslation } from "react-i18next";

type DismissEmployeesModalProps = {
  employeeCount: number;
  onClose: () => void;
  onConfirm: (amount: number) => void;
};

const PrettoSlider = styled(Slider)({
  color: "#1EE8B6A1",
  height: 8,
  "& .MuiSlider-track": {
    border: "none",
  },
  "& .MuiSlider-thumb": {
    backgroundColor: "#fff",
    border: "2px solid currentColor",
    "&:focus, &:hover, &.Mui-active, &.Mui-focusVisible": {
      boxShadow: "inherit",
    },
    "&::before": {
      display: "none",
    },
  },
  "& .MuiSlider-valueLabel": {
    lineHeight: 1.2,
    fontSize: 12,
    background: "unset",
    padding: 0,
    width: 24,
    height: 24,
    borderRadius: "0% 0% 0% 0%",
    backgroundColor: "#1EE8B6A1",
    transformOrigin: "bottom left",
    transform: "translate(50%, -100%) rotate(-45deg) scale(0)",
    "&::before": { display: "none" },
    "&.MuiSlider-valueLabelOpen": {
      transform: "translate(50%, -100%) rotate(-45deg) scale(1)",
    },
    "& > *": {
      transform: "rotate(45deg)",
    },
  },
});

const DismissEmployeesModal: React.FC<DismissEmployeesModalProps> = ({
  onClose,
  onConfirm,
  employeeCount,
}) => {
  const { t } = useTranslation();
  const [amount, setAmount] = useState<number>(0);

  return (
    <div className="bg-0c0c0c/80 absolute inset-0 flex items-center justify-center z-[9990]">
      <div className="min-h-[220px] w-96 bg-0c0c0c p-3 border border-202020 flex">
        <div className="w-full flex gap-2 flex-col items-center justify-between border border-white/15 rounded-sm p-3">
          <h1
            className="font-sfpro font-bold text-[#29BA99] uppercase text-xl"
            style={{ textShadow: "0px 0px 20px rgba(60, 243, 196, 0.53)" }}
          >
            {t("dismiss_employees")}
          </h1>
          <h1 className="text-center text-sm font-gilroy text-white/50">
            {t("desc_dismiss_employees")}
          </h1>
          <Box
            sx={{
              width: "100%",
              backgroundColor: "#121212",
              display: "flex",
              px: 4,
              py: 1,
            }}
          >
            <PrettoSlider
              valueLabelDisplay="auto"
              defaultValue={0}
              step={1}
              marks
              min={0}
              max={employeeCount}
              onChange={(_, v) => setAmount(v as number)}
            />
          </Box>
          <div className="flex items-center justify-center gap-5 mt-1">
            <button
              onClick={() => onConfirm(amount)}
              className="w-32 p-1.5 text-xs text-center bg-[#00d2a0]/20 text-[#29ba99] border border-transparent hover:border-[#29ba99] transition-colors"
              disabled={!amount || amount == 0}
            >
              {t("confirm")}
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

export default DismissEmployeesModal;
