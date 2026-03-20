import useData from "@/hooks/useData";
import PlayerInfo from "./Partials/PlayerInfo";
import Blip from "./Partials/Blip";
import ManagerList from "./Partials/ManagerList";
import ProcureRawMaterials from "./Partials/ProcureRawMaterials";
import ChangeBusinessTheme from "./Partials/ChangeBusinessTheme";
import WorkingInfo from "./Partials/WorkingInfo";
import WarehouseInfo from "./Partials/WareHouseInfo";
import WarehouseName from "./Partials/WareHouseName";
import ExtensiveInfo from "./Partials/ExtensiveInfo";
import ManagementPanel from "./Partials/ManagementPanel";
import SafeActions from "./Partials/SafeActions";
import { TbLayoutSidebarLeftExpandFilled } from "react-icons/tb";
import classNames from "classnames";
import { useState } from "react";
import Log from "./Partials/Log";

const Business = () => {
  const { warehouse, Player } = useData();

  const [isSidebar, setSidebar] = useState<boolean>(false);

  return (
    warehouse && (
      <div className="w-full h-full flex items-center justify-center">
        <div
          className="flex flex-col"
          style={{
            border: "1px solid #151515",
            background:
              "linear-gradient(180deg, #070707 0.01%, #121212 60.82%, #000 100%)",
            boxShadow: "0px 4px 4px 0px rgba(0, 0, 0, 0.25)",
          }}
        >
          <div className="relative flex justify-between">
            <div className="flex w-[420px] pl-6 pt-5 pb-3 pr-4 border-r border-151515">
              <PlayerInfo
                player={Player}
                isOwner={warehouse.owner_id == Player.identifier}
              />
            </div>
            <WarehouseInfo warehouse={warehouse} />
          </div>
          <hr className="border-151515" />
          <div className="flex w-full h-full overflow-auto relative">
            <div
              className={classNames(
                "min-w-[420px] w-[420px]  flex flex-col gap-3 pl-6 pt-4 pr-4 border-r border-151515 overflow-auto scrollbar-hidden",
                "max-lg:h-full max-xl:inset-0 max-xl:z-50 max-xl:bg-0c0c0c max-xl:absolute max-lg:transition-transform duration-300",
                { "max-xl:-translate-x-full": !isSidebar }
              )}
            >
              <WarehouseName id="warehouse-name" houseName={warehouse.name} />
              <Blip />
              <ManagerList
                id="warehouse-managers"
                owner_id={warehouse.owner_id}
                managers={warehouse.managers}
              />
              <ProcureRawMaterials />
            </div>
            <div className="xl:hidden py-1 relative z-50">
              <button
                onClick={() => setSidebar(!isSidebar)}
                className="text-white/55 transition-opacity hover:text-white"
              >
                <TbLayoutSidebarLeftExpandFilled className="w-6 h-6" />
              </button>
            </div>
            <div className="flex flex-col px-4 gap-3 pb-4 pt-2 max-w-screen-lg w-full h-full">
              <div className="flex items-end">
                <ChangeBusinessTheme
                  currentTheme={warehouse.business_theme}
                  warehouseLevel={warehouse.level}
                />
                <ManagementPanel warehouse={warehouse} />
              </div>
              <div className="flex gap-2.5 w-full">
                <div className="flex flex-col justify-between gap-3 h-full">
                  <div className="h-80 bg-0c0c0c/25 border border-202020 rounded-sm">
                    <Log />
                  </div>
                  <div className="bg-0c0c0c/25 border border-202020 rounded-sm">
                    <SafeActions warehouse={warehouse} />
                  </div>
                </div>
                <div className="flex flex-col justify-end rounded-sm border border-202020 w-96 min-w-96 bg-0c0c0c/25">
                  <ExtensiveInfo warehouse={warehouse} />
                  <WorkingInfo warehouse={warehouse} />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    )
  );
};

export default Business;
