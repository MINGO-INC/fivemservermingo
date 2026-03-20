import React, { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { useNuiEvent } from "@/hooks/useNuiEvent";
import { DataContext, Log } from "./context";
import { fetchNui } from "@/utils/fetchNui";
import "@/services/debug.g";
import { Page, Player, Warehouse, BuyWarehouse } from "@/types/index.type";

export const DataProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const { i18n } = useTranslation();
  const [Config, setConfig] = useState({} as never);
  const [page, setPage] = useState<Page>("business");

  const [alert, setAlert] = useState<{ text: string; type: string }>();
  const [isSleep, setSleep] = useState<boolean>(false);
  const [warehouse, setWarehouse] = useState<Warehouse | undefined>();
  const [Player, setPlayer] = useState<Player>({} as Player);
  const [logs, setLogs] = useState<Log[]>([]);

  const [buyWarehouse, setBuyWarehouse] = useState<BuyWarehouse | undefined>(
    undefined
  );

  useEffect(() => {
    fetchNui("nui:loadUI", true, true);
  }, []);

  useNuiEvent("ui:setupUI", (data) => {
    if (data.setLocale) {
      i18n.addResourceBundle("en", "translation", data.setLocale);
    }
    if (data.setConfig) setConfig(data.setConfig);
    if (data.setPlayer) setPlayer(data.setPlayer);

    fetchNui("nui:onLoadUI", true, true);
  });
  useNuiEvent("ui:setPage", (page: Page) => {
    setPage(page);
  });
  useNuiEvent("ui:setAlert", (text) => {
    if (!alert) {
      setTimeout(() => {
        setAlert(undefined);
      }, 3000);
    }
    setAlert(text);
  });

  useNuiEvent("ui:setCurrentWarehouse", (data) => {
    setWarehouse(data);
  });
  useNuiEvent("ui:setPlayer", setPlayer);
  useNuiEvent("ui:setBuyWarehouse", setBuyWarehouse);
  useNuiEvent("ui:setLogs", setLogs);

  const value = {
    Config,
    page,
    alert,
    setAlert,
    isSleep,
    setSleep,
    warehouse,
    Player,
    buyWarehouse,
    setBuyWarehouse,
    logs,
  };

  return <DataContext.Provider value={value}>{children}</DataContext.Provider>;
};
