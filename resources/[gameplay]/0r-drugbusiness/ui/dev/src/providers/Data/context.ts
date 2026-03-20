import {
  BusinessType,
  BuyWarehouse,
  Page,
  Player,
  Warehouse,
} from "@/types/index.type";
import { createContext } from "react";

export interface Config {
  InventoryImagesFolder: string;
  BusinessTypes: BusinessType[];
  SecuritySystemPrice: number;
  Stock: { [key: string]: { unit_price: number } };
  Employee: {
    recruitment_fee: number;
    salary_fee: number;
  };
  VehicleUpgrades: {
    [key: number]: {
      price: number;
      maxPackageCount: number;
    };
  };
  RawMaterialStockUpgrades: {
    [key: number]: {
      price: number;
      maxStockCount: number;
    };
  };
  MoneyWashingUpgrades: {
    [key: number]: {
      price: number;
      productionPerMin: number;
    };
  };
}

export interface Log {
  log_message: string;
  created_at: string;
}

type DataContextProps = {
  Config: Config;
  page: Page;
  isSleep: boolean;
  setSleep: React.Dispatch<React.SetStateAction<boolean>>;
  warehouse?: Warehouse;
  Player: Player;
  alert?: { text: string; type: any };
  setAlert: React.Dispatch<React.SetStateAction<any>>;
  buyWarehouse?: BuyWarehouse;
  setBuyWarehouse: React.Dispatch<React.SetStateAction<any>>;
  logs: Log[];
};

export const DataContext = createContext<DataContextProps>(
  {} as DataContextProps
);
