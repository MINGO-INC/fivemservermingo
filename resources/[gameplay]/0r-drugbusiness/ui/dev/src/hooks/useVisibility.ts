import {
  VisibilityContext,
  VisibilityContextProps,
} from "@/providers/Visibility/context";
import { useContext } from "react";

export const useVisibility = (): VisibilityContextProps =>
  useContext<VisibilityContextProps>(VisibilityContext);
