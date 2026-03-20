export type Page = "business" | "buy-warehouse";

export interface Player {
  identifier: string;
  name: string;
}

export type BusinessTypeString = "weed" | "cocaine" | "meth";

export interface BusinessType {
  key: BusinessTypeString;
  label: string;
  requiredLevel: number;
  price: number;
}

export interface Manager extends Player {
  owner?: boolean;
}

export interface Meta {
  blip_hidden: boolean;
  blip_color: boolean;
  max_package_stock: number;
  max_raw_materials_stock: number;
  security_system: boolean;
  interior_light: boolean;
  is_working: boolean;
  rm_task_vehicle_level: number;
  interior_level: number;
  last_working_at?: number;
  raw_materials_stock_level: number;
  money_washing_level: number;
}

export interface Warehouse {
  id: number;
  warehouse_index: number;
  name: string;
  owner_id: string;
  business_theme: BusinessTypeString;
  experience: number;
  level: number;
  managers: Manager[];
  nextLeveLExp: number;
  meta: Meta;
  clean_money: number;
  dirty_money: number;
  raw_materials_stock: number;
  water_stock: number;
  gas_stock: number;
  electricity_stock: number;
  packaged_product_stock: number;
  employee_count: number;
  last_processed?: number;
  production_time: number;
  production_count: number;
  created_at: number;
}

export interface BuyWarehouse {
  index: number;
  coords: unknown;
  label: string;
  price: number;
}

export interface ManagementAction {
  title: string; // Başlık
  description: string; // Açıklama
  actionType: "button" | "toggle"; // Eylem türü: düğme veya anahtar
  buttons?: {
    label: string;
    onClick: () => void;
    type?: "danger";
    disable?: boolean;
  }[]; // Düğmeler için yapı
  toggle?: {
    checked: boolean; // Anahtar durumu
    onChange: () => void; // Anahtar değişim işleyicisi
  };
}
