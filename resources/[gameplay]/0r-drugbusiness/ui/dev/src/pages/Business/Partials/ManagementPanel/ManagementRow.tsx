import { ManagementAction } from "@/types/index.type";
import classNames from "classnames";
import { useTranslation } from "react-i18next";

export const ManagementRow = ({ action }: { action: ManagementAction }) => {
  const { t } = useTranslation();

  return (
    <div
      className="relative flex items-center justify-between w-full rounded-sm border border-202020 p-1.5"
      style={{
        background:
          "radial-gradient(94.07% 94.07% at 50% 5.93%, rgba(255, 255, 255, 0.13) 0%, rgba(153, 153, 153, 0.04) 100%)",
      }}
    >
      <div className="flex flex-col whitespace-nowrap overflow-hidden pr-2">
        <h1 className="text-sm font-primary text-shadow-adez overflow-hidden text-ellipsis">
          {t(action.title)}
        </h1>
        <span className="text-xs font-primary text-white/55 overflow-hidden text-ellipsis">
          {t(action.description)}
        </span>
      </div>
      <div className="flex items-center gap-2">
        {action.actionType === "button" &&
          action.buttons?.map((btn, idx) => (
            <button
              disabled={btn.disable}
              key={idx}
              className={classNames(
                "text-xs font-primary font-medium px-4 py-1 disabled:opacity-50",
                {
                  "bg-white/10": btn.type != "danger",
                  "bg-C12D2D/80": btn.type == "danger",
                }
              )}
              onClick={btn.onClick}
            >
              {t(btn.label)}
            </button>
          ))}
        {action.actionType === "toggle" && action.toggle && (
          <label className="setting-switch outline-none ring-0">
            <input
              type="checkbox"
              checked={action.toggle.checked}
              onChange={action.toggle.onChange}
            />
          </label>
        )}
      </div>
    </div>
  );
};
