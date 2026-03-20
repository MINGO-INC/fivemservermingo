import { styled, Tooltip, tooltipClasses, TooltipProps } from "@mui/material";

export const LightTooltip = styled(({ className, ...props }: TooltipProps) => (
  <Tooltip {...props} classes={{ popper: className }} />
))(() => ({
  [`& .${tooltipClasses.tooltip}`]: {
    backgroundColor: "#e6e6fa",
    color: "rgba(0, 0, 0, 0.87)",
    fontWeight: 700,
    textTransform: "uppercase",
  },
  [`& .${tooltipClasses.arrow}`]: {
    color: "#e6e6fa",
  },
}));
