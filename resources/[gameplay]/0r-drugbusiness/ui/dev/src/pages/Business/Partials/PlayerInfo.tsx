import { Player } from "@/types/index.type";
import { useTranslation } from "react-i18next";

type PlayerInfoProps = {
  player: Player;
  isOwner?: boolean;
};

const PlayerInfo = ({ player, isOwner }: PlayerInfoProps) => {
  const { t } = useTranslation();

  return (
    player && (
      <div className="flex items-center gap-1.5 w-full">
        <div
          className="flex items-center justify-center w-16 min-w-16 min-h-16 h-16 p-1.5 rounded-sm border border-202020"
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
        <div className="relative w-full h-full flex flex-col px-2.5 pt-1.5 border border-202020 bg-black/25 rounded-sm">
          <h1 className="font-primary text-shadow-adez text-sm">
            {player.name}
          </h1>
          <span className="text-sm text-white/50 font-primary text-shadow-adez">
            {t(isOwner ? "owner" : "manager")}
          </span>
          <div className="absolute top-1.5 right-1 bg-20846D/30 text-1EE8B6 rounded-sm px-2.5 flex items-center justify-center">
            <h1 className="text-xs font-primary" style={{ lineHeight: "20px" }}>
              {t(isOwner ? "owner" : "manager")}
            </h1>
          </div>
        </div>
      </div>
    )
  );
};

export default PlayerInfo;
