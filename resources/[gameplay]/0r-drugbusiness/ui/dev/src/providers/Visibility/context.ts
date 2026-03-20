import { createContext } from "react";

export interface VisibilityContextProps {
  setVisible: (visible: boolean) => void;
  visible: boolean;
}

export const VisibilityContext = createContext<VisibilityContextProps>(
  {} as VisibilityContextProps
);
