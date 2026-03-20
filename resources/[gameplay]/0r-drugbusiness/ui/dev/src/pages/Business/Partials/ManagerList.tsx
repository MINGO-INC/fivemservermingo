import { Manager } from "@/types/index.type";
import { useTranslation } from "react-i18next";
import { FaCrown } from "react-icons/fa";
import ModalComponent from "@/components/common/Modal";
import { useState } from "react";
import { LightTooltip } from "@/components/common/LightTooltip";
import { fetchNui } from "@/utils/fetchNui";
import useData from "@/hooks/useData";
import { AiOutlinePlus } from "react-icons/ai";
import { MdDelete } from "react-icons/md";

type ManagerListProps = {
  managers: Manager[];
  owner_id: string;
} & React.HTMLAttributes<HTMLDivElement>;

const ManagerList: React.FC<ManagerListProps> = ({
  managers,
  owner_id,
  ...props
}) => {
  const { t } = useTranslation();
  const { isSleep, setSleep } = useData();
  const [isManagerDetailModalOpen, setManagerDetailModalOpen] = useState(false);
  const [selectedManager, setSelectedManager] = useState<Manager | null>(null);
  const [isManagerInviteModalOpen, setManagerInviteModalOpen] = useState(false);

  const handleManagerDetailModalOpen = (manager: Manager) => {
    setSelectedManager(manager);
    setManagerDetailModalOpen(true);
  };
  const handleManagerDetailModalClose = () => {
    setManagerDetailModalOpen(false);
    setSelectedManager(null);
  };
  const handleRemoveManager = async () => {
    if (isSleep) return;
    setSleep(true);
    await fetchNui(
      "nui:removeManagerFromCurrentWarehouse",
      selectedManager,
      true
    );
    handleManagerDetailModalClose();
    setSleep(false);
  };

  const [inviteInputValue, setInviteInputValue] = useState<number | string>(1);
  const handleManagerInviteModalOpen = () => {
    setManagerInviteModalOpen(true);
  };
  const handleManagerInviteModalClose = () => {
    setManagerInviteModalOpen(false);
    setInviteInputValue("");
  };
  const handleInviteManager = async () => {
    if (isSleep) return;
    if (!inviteInputValue) return;
    setSleep(true);
    await fetchNui(
      "nui:inviteManagerToCurrentWarehouse",
      inviteInputValue || 1,
      true
    );
    handleManagerInviteModalClose();
    setSleep(false);
  };

  const handleTransferCompanyToSelectedManager = async () => {
    if (isSleep) return;
    setSleep(true);
    await fetchNui("nui:transferWarehouseToManager", selectedManager, true);
    handleManagerDetailModalClose();
    setSleep(false);
  };

  return (
    <>
      <div className="flex flex-col gap-1" {...props}>
        <h1 className="font-primary text-white/55 text-sm text-shadow-adez">
          {t("manager_list")}
        </h1>
        <div className="flex flex-col gap-0.5">
          {managers?.map((manager, index) => (
            <div key={index} className="flex gap-1">
              <div className="relative w-full p-1.5 flex items-center gap-1.5 rounded border border-202020 bg-black/25">
                <div
                  className="flex items-center justify-center p-1 rounded border border-202020"
                  style={{
                    background:
                      "radial-gradient(94.07% 94.07% at 50% 5.93%, rgba(255, 255, 255, 0.13) 0%, rgba(153, 153, 153, 0.04) 100%)",
                  }}
                >
                  <img
                    className="rounded-sm w-9 h-9"
                    src="images/common/profile0.png"
                    alt="managerlist-profile"
                  />
                </div>
                <div className="flex flex-col">
                  <h1 className="text-white text-sm font-primary text-shadow-adez">
                    {manager.name}
                  </h1>
                  <span className="text-xs text-white/55 font-primary -mt-0.5 text-shadow-adez">
                    {t(manager.identifier == owner_id ? "owner" : "manager")}
                  </span>
                </div>
                {manager.identifier == owner_id && (
                  <div className="absolute top-1.5 right-1 bg-20846D/30 text-1EE8B6/80 rounded-sm px-2.5 flex items-center justify-center">
                    <h1
                      className="text-xs font-primary"
                      style={{ lineHeight: "20px" }}
                    >
                      {t(manager.identifier == owner_id ? "owner" : "manager")}
                    </h1>
                  </div>
                )}
              </div>
              <div className="w-8 bg-black/25 border border-202020 rounded-sm flex items-center justify-center">
                {manager.identifier == owner_id ? (
                  <FaCrown className="text-[#4E4B4B]" />
                ) : (
                  <button
                    onClick={() => handleManagerDetailModalOpen(manager)}
                    className="outline-none ring-0"
                  >
                    <MdDelete className="w-5 h-5 text-[#4E4B4B]" />
                  </button>
                )}
              </div>
            </div>
          ))}
          {managers &&
            Array.from({ length: Math.max(0, 6 - managers.length) }).map(
              (_, index) => (
                <div key={index} className="flex gap-1 h-14">
                  <div className="relative overflow-hidden w-full flex items-center border border-202020 bg-black/25">
                    <div className="flex items-center justify-center absolute left-0 bottom-0">
                      <img
                        className="w-24"
                        src="images/icons/warehouse_1.png"
                        alt="managerlist-warehouse"
                      />
                    </div>
                    <div className="flex flex-col justify-center items-center translate-x-8 w-full">
                      <h1 className="text-white text-xs font-primary text-shadow-adez">
                        {t("invite_manager")}
                      </h1>
                      <span
                        className="text-xs text-white/45 font-primary w-1/2 text-center text-shadow-adez"
                        style={{ lineHeight: "12px" }}
                      >
                        {t("desc_invite_manager")}
                      </span>
                    </div>
                  </div>
                  <div className="w-8 bg-black/25 border border-202020 rounded-sm flex items-center justify-center">
                    <button onClick={handleManagerInviteModalOpen}>
                      <AiOutlinePlus className="text-[#4E4B4B]" />
                    </button>
                  </div>
                </div>
              )
            )}
        </div>
      </div>
      <ModalComponent
        open={isManagerDetailModalOpen}
        onClose={handleManagerDetailModalClose}
        title={t("manager_detail")}
      >
        <div className="flex flex-col gap-6 pt-2">
          <div className="relative rounded-sm border border-202020 bg-black/25 gap-1 p-2 pt-4 whitespace-nowrap">
            <h1 className="absolute top-0 -translate-y-1/2 rounded-sm px-2 bg-[#080808] border border-202020 text-353535 text-sm font-bold font-primary uppercase">
              {t("identifier")}
            </h1>
            <h1 className="lowercase text-sm font-medium font-primary text-ellipsis overflow-hidden text-a1a1a1">
              {selectedManager?.identifier}
            </h1>
          </div>
          <div className="relative rounded-sm border border-202020 bg-black/25 gap-1 p-2 pt-4 whitespace-nowrap">
            <h1 className="absolute top-0 -translate-y-1/2 rounded-sm px-2 bg-[#080808] border border-202020 text-353535 text-sm font-bold font-primary uppercase">
              {t("name")}
            </h1>
            <h1 className="text-sm font-medium font-primary text-ellipsis overflow-hidden text-a1a1a1">
              {selectedManager?.name}
            </h1>
          </div>
        </div>
        <hr className="my-4 border-white/10" />
        <div className="flex justify-between">
          <LightTooltip
            title={t("double_click_transfer")}
            enterNextDelay={1000}
          >
            <button
              onDoubleClick={handleTransferCompanyToSelectedManager}
              className="py-2 px-2 bg-[#FF6767]/15 border border-[#FF6B6B]/80 hover:border-[#FF6B6B]/80 transition-colors hover:bg-[#FF6B6B]/80/50"
            >
              <h1 className="uppercase font-bold font-primary tracking-wide text-xs">
                {t("transfer_company")}
              </h1>
            </button>
          </LightTooltip>
          <LightTooltip title={t("double_click_remove")} enterNextDelay={1000}>
            <button
              onDoubleClick={handleRemoveManager}
              className="py-2 px-4 bg-[#FF6767]/15 border border-[#FF6B6B]/80 hover:border-[#FF6B6B]/80 transition-colors hover:bg-[#FF6B6B]/80/50"
            >
              <h1 className="uppercase font-bold font-primary tracking-wide text-sm">
                {t("remove")}
              </h1>
            </button>
          </LightTooltip>
        </div>
      </ModalComponent>
      <ModalComponent
        open={isManagerInviteModalOpen}
        onClose={handleManagerInviteModalClose}
        title={t("invite_manager")}
      >
        <div className="relative rounded-sm border border-202020 bg-black/25 p-2 pt-4 mt-6 whitespace-nowrap">
          <h1 className="absolute top-0 -translate-y-1/2 rounded-sm px-2 bg-[#080808] border border-202020 text-353535 text-sm font-bold font-primary uppercase">
            {t("player_source_id")}
          </h1>
          <input
            type="number"
            className="h-10 w-full bg-transparent border border-202020 outline-none p-2 mt-1 placeholder:text-white-50"
            autoFocus
            placeholder={t("player_source_id")}
            min={1}
            value={inviteInputValue}
            onChange={(e) =>
              setInviteInputValue(Math.max(1, parseInt(e.currentTarget.value)))
            }
          />
        </div>
        <div className="flex items-center justify-end mt-3">
          <button
            onClick={handleInviteManager}
            className="bg-20846D/30 border border-transparent hover:border-1EE8B6 transition-colors py-1 px-6 rounded-sm"
          >
            <h1 className="text-1EE8B6/80 font-primary uppercase font-medium">
              {t("invite")}
            </h1>
          </button>
        </div>
      </ModalComponent>
    </>
  );
};

export default ManagerList;
