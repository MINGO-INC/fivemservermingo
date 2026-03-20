import { DataContext } from "@/providers/Data/context";
import { useContext } from "react";

const useData = () => {
  const dataContext = useContext(DataContext);
  return dataContext;
};

export default useData;
