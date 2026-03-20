import BuyModal from "@/components/common/BuyModal";
import useData from "@/hooks/useData";
import { fetchNui } from "@/utils/fetchNui";

const BuyWarehouse = () => {
  const { buyWarehouse, setBuyWarehouse } = useData();

  if (!buyWarehouse) return null;

  return (
    <BuyModal
      price={buyWarehouse.price}
      label={buyWarehouse.label}
      onBuy={() => {
        setBuyWarehouse(undefined);
        fetchNui("nui:buyNewWarehouse", buyWarehouse.index, true);
      }}
      onClose={() => {
        setBuyWarehouse(undefined);
        fetchNui("nui:onCancelBuyWarehouse", true, true);
      }}
    />
  );
};

export default BuyWarehouse;
