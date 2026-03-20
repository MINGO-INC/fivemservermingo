import useData from "@/hooks/useData";
import { useVisibility } from "@/hooks/useVisibility";
import Business from "@/pages/Business";
import BuyWarehouse from "@/pages/BuyWarehouse";
import { Alert, IconButton } from "@mui/material";
import classNames from "classnames";
import { IoCloseCircleOutline } from "react-icons/io5";

const Main = () => {
  const { visible } = useVisibility();
  const { page, alert, setAlert } = useData();

  const load = () => {
    switch (page) {
      case "business":
        return <Business />;
      case "buy-warehouse":
        return <BuyWarehouse />;
      default:
        return <Business />;
    }
  };

  return (
    <>
      <div
        className={classNames(
          "w-full h-full z-0 transition-opacity duration-300",
          {
            "opacity-0": !visible,
            "opacity-100": visible,
          }
        )}
        style={{ visibility: visible ? "visible" : "hidden" }}
      >
        <div className="relative w-full h-full bg-black/50">{load()}</div>
        {alert && (
          <Alert
            className="z-[9999] absolute top-4 right-4"
            severity={alert.type}
            tabIndex={-1}
            action={
              <IconButton
                aria-label="close"
                color="inherit"
                size="small"
                onClick={() => {
                  setAlert(undefined);
                }}
              >
                <IoCloseCircleOutline fontSize="inherit" />
              </IconButton>
            }
          >
            {alert.text}
          </Alert>
        )}
      </div>
    </>
  );
};
export default Main;
