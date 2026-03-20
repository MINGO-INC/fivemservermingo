import ModalComponent from "@/components/common/Modal";
import useData from "@/hooks/useData";
import { fetchNui } from "@/utils/fetchNui";
import classNames from "classnames";
import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { ManagementAction, Warehouse } from "@/types/index.type";
import { ManagementRow } from "./ManagementRow";
import ConfirmModal from "@/components/common/ConfirmModal";
import PurchaseStockModal from "./PurchaseStockModal";
import DismissEmployeesModal from "./DismissEmployeesModal";
import RecruitEmployeesModal from "./RecruitEmployeesModal";

type ManagementPanelProps = {
  warehouse: Warehouse;
};

const ManagementPanel = ({ warehouse }: ManagementPanelProps) => {
  const { t } = useTranslation();
  const { isSleep, setSleep, Config } = useData();

  const [isPanelModalOpen, setPanelModalOpen] = useState(false);
  const [secondaryModal, setSecondaryModal] = useState<string | null>(null);

  const [employeePaymentShouldPay, setEmployeePaymentShouldPay] = useState<
    boolean | number | undefined
  >(undefined);

  const [nextInteriorLeveLPrice, setNextInteriorLeveLPrice] = useState<
    number | boolean | undefined
  >();

  useEffect(() => {
    if (secondaryModal === "payment_employee") {
      fetchNui<boolean | number>("nui:employee:haveToPay", true, 6500)
        .then((result) => {
          setEmployeePaymentShouldPay(result);
        })
        .catch(() => {
          setEmployeePaymentShouldPay(false);
        });
    } else if (secondaryModal === "upgrade_interior") {
      fetchNui<boolean | number>(
        "nui:warehouse:getInteriorUpgradePrice",
        {
          theme: warehouse.business_theme,
          level: warehouse.meta.interior_level + 1,
        },
        5000
      )
        .then((result) => {
          setNextInteriorLeveLPrice(typeof result == "number" ? result : 0);
        })
        .catch(() => {
          setNextInteriorLeveLPrice(false);
        });
    }
  }, [secondaryModal, warehouse.meta.interior_level, warehouse.business_theme]);

  const openSecondaryModal = (modalType: string) =>
    setSecondaryModal(modalType);
  const closeSecondaryModal = () => setSecondaryModal(null);

  const openManagementPanel = () => setPanelModalOpen(true);
  const closeManagementPanel = () => {
    setPanelModalOpen(false);
    closeSecondaryModal();
  };

  const handleUpdateBlipDisplay = async () => {
    if (isSleep) return;
    setSleep(true);
    await fetchNui("nui:updateCurrentWarehouseBlipHidden", true, true);
    setSleep(false);
  };

  const handleChangeInteriorLightState = async () => {
    if (isSleep) return;
    setSleep(true);
    await fetchNui("nui:changeWarehouseInteriorLightState", true, true);
    setSleep(false);
  };

  const handleTerminateWarehouse = async () => {
    if (isSleep) return;
    setSleep(true);
    const response = await fetchNui("nui:terminateWarehouse", true, true);
    if (response) closeManagementPanel();
    setSleep(false);
  };

  const handleBuySecuritySystem = async () => {
    if (isSleep) return;
    setSleep(true);
    const response = await fetchNui(
      "nui:security:buySecuritySystem",
      true,
      true
    );
    if (response) closeSecondaryModal();
    setSleep(false);
  };

  const handleOpenSecurityCameras = async () => {
    if (isSleep) return;
    setSleep(true);
    const response = await fetchNui("nui:security:openCameras", true, true);
    if (response) closeManagementPanel();
    setSleep(false);
  };

  const handlePurchaseStock = async (data: any) => {
    if (isSleep) return;
    setSleep(true);
    const response = await fetchNui(
      "nui:stock:purchaseByType",
      { id: data.selectedItem, amount: parseInt(data.amount) },
      true
    );
    if (response) closeSecondaryModal();
    setSleep(false);
  };

  const handlePaymentEmployeeSalaries = async () => {
    if (isSleep) return;
    setSleep(true);
    const response = await fetchNui("nui:employee:paySalaries", true, true);
    if (response) closeSecondaryModal();
    setSleep(false);
  };

  const handleEmployeeRecruitment = async (amount: number) => {
    if (isSleep) return;
    setSleep(true);
    const response = await fetchNui("nui:employee:recruitment", amount, true);
    if (response) closeSecondaryModal();
    setSleep(false);
  };

  const handleDismissEmployees = async (amount: number) => {
    if (isSleep) return;
    setSleep(true);
    const response = await fetchNui("nui:employee:dismiss", amount, true);
    if (response) closeSecondaryModal();
    setSleep(false);
  };

  const handleUpgradeVehicle = async () => {
    if (isSleep) return;
    setSleep(true);
    const response = await fetchNui(
      "nui:rawmaterials:upgradeVehicle",
      true,
      true
    );
    if (response) closeSecondaryModal();
    setSleep(false);
  };

  const handleUpgradeRMStocks = async () => {
    if (isSleep) return;
    setSleep(true);
    const response = await fetchNui(
      "nui:rawmaterials:upgradeMaxStock",
      true,
      true
    );
    if (response) closeSecondaryModal();
    setSleep(false);
  };

  const handleUpgradeInterior = async () => {
    if (isSleep) return;
    setSleep(true);
    const response = await fetchNui(
      "nui:warehouse:upgradeInterior",
      true,
      true
    );
    if (response) closeSecondaryModal();
    setSleep(false);
  };

  const getNextLevelVehicleInfo = (level: number) => {
    return Config.VehicleUpgrades[level - 1];
  };

  const getNextLevelRMStocksInfo = (level: number) => {
    return Config.RawMaterialStockUpgrades[level - 1];
  };

  const renderSecondaryModal = () => {
    switch (secondaryModal) {
      case "terminate_warehouse":
        return (
          <ConfirmModal
            message={t(`modal_${secondaryModal}_desc`)}
            onClose={closeSecondaryModal}
            onConfirm={handleTerminateWarehouse}
            wait
          />
        );
      case "buy_security":
        return (
          <ConfirmModal
            message={
              t(`modal_${secondaryModal}_desc`) +
              " " +
              t("money_type") +
              Config.SecuritySystemPrice
            }
            onClose={closeSecondaryModal}
            onConfirm={handleBuySecuritySystem}
          />
        );
      case "purcase_stock":
        return (
          <PurchaseStockModal
            onClose={closeSecondaryModal}
            onConfirm={handlePurchaseStock}
            selectableItems={[
              { id: "water", name: t("water") },
              { id: "gas", name: t("gas") },
              { id: "electricity", name: t("electricity") },
            ]}
          />
        );
      case "payment_employee": {
        return employeePaymentShouldPay != false ? (
          <ConfirmModal
            title={
              t(`modal_${secondaryModal}_title`) +
              " " +
              t("money_type") +
              employeePaymentShouldPay
            }
            message={t(`modal_${secondaryModal}_desc`)}
            onClose={() => {
              closeSecondaryModal();
              setEmployeePaymentShouldPay(undefined);
            }}
            onConfirm={handlePaymentEmployeeSalaries}
            loading={employeePaymentShouldPay == undefined}
          />
        ) : (
          <ConfirmModal
            title={t("modal_noneed_title")}
            message={t("modal_noneed_desc")}
            onClose={() => {
              closeSecondaryModal();
              setEmployeePaymentShouldPay(undefined);
            }}
            loading={employeePaymentShouldPay == undefined}
          />
        );
      }
      case "employee_recruitment":
        return (
          <RecruitEmployeesModal
            onClose={closeSecondaryModal}
            onConfirm={handleEmployeeRecruitment}
          />
        );
      case "dismiss_employees":
        return (
          <DismissEmployeesModal
            employeeCount={warehouse.employee_count}
            onClose={closeSecondaryModal}
            onConfirm={handleDismissEmployees}
          />
        );
      case "upgrade_vehicle":
        return (
          <ConfirmModal
            title={
              t(`modal_${secondaryModal}_title`) +
                " " +
                t("money_type") +
                getNextLevelVehicleInfo(
                  warehouse.meta.rm_task_vehicle_level + 1
                )?.price || "0"
            }
            message={t(`modal_${secondaryModal}_desc`, {
              1: warehouse.meta.rm_task_vehicle_level,
              2:
                getNextLevelVehicleInfo(
                  warehouse.meta.rm_task_vehicle_level + 1
                )?.maxPackageCount || 0,
            })}
            onClose={closeSecondaryModal}
            onConfirm={handleUpgradeVehicle}
          />
        );
      case "upgrade_interior":
        return (
          nextInteriorLeveLPrice != false && (
            <ConfirmModal
              title={
                t(`modal_${secondaryModal}_title`) +
                " " +
                t("money_type") +
                nextInteriorLeveLPrice
              }
              message={t(`modal_${secondaryModal}_desc`, {
                1: warehouse.meta.interior_level,
              })}
              onClose={closeSecondaryModal}
              onConfirm={handleUpgradeInterior}
              loading={nextInteriorLeveLPrice == undefined}
            />
          )
        );
      case "upgrade_raw_materials_stock":
        return (
          <ConfirmModal
            title={
              t(`modal_${secondaryModal}_title`) +
                " " +
                t("money_type") +
                getNextLevelRMStocksInfo(
                  warehouse.meta.raw_materials_stock_level + 1
                )?.price || "0"
            }
            message={t(`modal_${secondaryModal}_desc`, {
              1: warehouse.meta.raw_materials_stock_level,
              2:
                getNextLevelRMStocksInfo(
                  warehouse.meta.raw_materials_stock_level + 1
                )?.maxStockCount || 0,
            })}
            onClose={closeSecondaryModal}
            onConfirm={handleUpgradeRMStocks}
          />
        );
      default:
        return <></>;
    }
  };

  const actions: ManagementAction[] = [
    {
      title: "upgrade_interior",
      description: "desc_upgrade_interior",
      actionType: "button",
      buttons: [
        {
          label: "upgrade",
          onClick: () => openSecondaryModal("upgrade_interior"),
          disable: warehouse.meta.interior_level >= 3,
        },
      ],
    },
    {
      title: "upgrade_vehicle",
      description: "desc_upgrade_vehicle",
      actionType: "button",
      buttons: [
        {
          label: "upgrade",
          onClick: () => openSecondaryModal("upgrade_vehicle"),
          disable:
            Object.values(Config.VehicleUpgrades).length <=
            warehouse.meta.rm_task_vehicle_level,
        },
      ],
    },
    {
      title: "upgrade_raw_materials_stock",
      description: "desc_upgrade_raw_materials_stock",
      actionType: "button",
      buttons: [
        {
          label: "upgrade",
          onClick: () => openSecondaryModal("upgrade_raw_materials_stock"),
          disable:
            Object.values(Config.RawMaterialStockUpgrades).length ==
            warehouse.meta.raw_materials_stock_level,
        },
      ],
    },
    {
      title: "recruit_employee",
      description: "desc_recruit_employee",
      actionType: "button",
      buttons: [
        {
          label: "pay",
          onClick: () => openSecondaryModal("payment_employee"),
          disable: warehouse.employee_count < 1,
        },
        {
          label: "change",
          onClick: () => openSecondaryModal("employee_recruitment"),
        },
      ],
    },
    {
      title: "dismiss_employees",
      description: "desc_dismiss_employees",
      actionType: "button",
      buttons: [
        {
          label: "Dismiss",
          onClick: () => openSecondaryModal("dismiss_employees"),
          disable: warehouse.employee_count == 0,
        },
      ],
    },
    {
      title: "purchase_storage",
      description: "desc_purchase_storage",
      actionType: "button",
      buttons: [
        { label: "buy", onClick: () => openSecondaryModal("purcase_stock") },
      ],
    },
    {
      title: "hide_map_blip",
      description: "desc_hide_map_blip",
      actionType: "toggle",
      toggle: {
        checked: warehouse.meta.blip_hidden,
        onChange: handleUpdateBlipDisplay,
      },
    },
    {
      title: "security_system",
      description: "desc_security_system",
      actionType: "button",
      buttons: [
        {
          label: "buy",
          onClick: () => openSecondaryModal("buy_security"),
          disable: warehouse.meta.security_system,
        },
      ],
    },
    {
      title: "security_camera",
      description: "desc_security_camera",
      actionType: "button",
      buttons: [
        {
          label: "open",
          onClick: handleOpenSecurityCameras,
          disable: !warehouse.meta.security_system,
        },
      ],
    },
    {
      title: "interior_light",
      description: "desc_interior_light",
      actionType: "toggle",
      toggle: {
        checked: warehouse.meta.interior_light,
        onChange: handleChangeInteriorLightState,
      },
    },
    {
      title: "terminate_contract",
      description: "desc_terminate_contract",
      actionType: "button",
      buttons: [
        {
          label: "delete",
          onClick: () => openSecondaryModal("terminate_warehouse"),
          type: "danger",
        },
      ],
    },
  ];

  return (
    <>
      <div
        onClick={openManagementPanel}
        className="relative flex flex-col gap-1 group cursor-pointer"
      >
        <div className="relative flex items-center justify-center">
          <img
            className="w-full"
            src="images/common/managers.png"
            alt="management-panel"
          />
          <div
            className={classNames(
              "absolute inset-0 z-0 bg-black/50 transition-colors group-hover:bg-black/5"
            )}
          />
        </div>
        <button
          className={classNames(
            "border border-transparent bg-20846D/30 py-1 text-1EE8B6/75 transition-colors group-hover:border-1EE8B6 hover:text-1EE8B6"
          )}
        >
          <h1 className="font-primary font-medium text-xs">
            {t("management_menu")}
          </h1>
        </button>
      </div>

      <ModalComponent
        open={isPanelModalOpen}
        onClose={closeManagementPanel}
        width={500}
      >
        <div className="flex flex-col gap-1 border p-2 border-202020">
          <div className="flex gap-2">
            <div
              className="w-16 h-16 min-w-16 min-h-16 rounded-sm border border-202020 p-1.5"
              style={{
                background:
                  "radial-gradient(94.07% 94.07% at 50% 5.93%, rgba(255, 255, 255, 0.13) 0%, rgba(153, 153, 153, 0.04) 100%)",
              }}
            >
              <img
                className="rounded-sm"
                src="images/common/profile0.png"
                alt="player-info-profile"
              />
            </div>
            <div
              className="relative w-full rounded-sm border border-202020 px-2 pb-3"
              style={{
                background:
                  "radial-gradient(94.07% 94.07% at 50% 5.93%, rgba(255, 255, 255, 0.13) 0%, rgba(153, 153, 153, 0.04) 100%)",
              }}
            >
              <div className="flex flex-col h-full justify-end font-primary">
                <h1 className="text-shadow-adez">{t("management_panel")}</h1>{" "}
                <h1 className="text-white/55 text-xs">
                  {t("desc_management_panel")}
                </h1>
              </div>
              <div className="absolute z-10 top-1.5 right-1 bg-20846D/30 text-1EE8B6 rounded-sm px-2.5 py-0.5 flex items-center justify-center">
                <h1 className="text-xs font-primary">{t("business")}</h1>{" "}
              </div>
            </div>
          </div>

          {actions.map((action, idx) => (
            <ManagementRow key={idx} action={action} />
          ))}
        </div>
        {/* İkincil Modal Örneği */}
        {secondaryModal && renderSecondaryModal()}
      </ModalComponent>
    </>
  );
};

export default ManagementPanel;
