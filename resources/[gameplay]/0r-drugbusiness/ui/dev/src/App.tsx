import { createRoot } from "react-dom/client";
import { DataProvider } from "@/providers/Data";
import { VisibilityProvider } from "@/providers/Visibility";
import { Main } from "@/components/index";
import "@/services/i18n";
import "@/styles/index.css";

createRoot(document.getElementById("root")!).render(
  <DataProvider>
    <VisibilityProvider>
      <Main />
    </VisibilityProvider>
  </DataProvider>
);
