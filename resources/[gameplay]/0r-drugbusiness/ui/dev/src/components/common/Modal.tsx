import React from "react";
import { Modal, Box } from "@mui/material";
import classNames from "classnames";

interface ModalProps {
  open: boolean;
  onClose: () => void;
  title?: string;
  children?: React.ReactNode;
  width?: number | string;
}

const ModalComponent: React.FC<ModalProps> = ({
  open,
  onClose,
  title,
  children,
  width = 400,
}) => {
  return (
    <Modal
      open={open}
      onClose={onClose}
      aria-labelledby="modal-title"
      aria-describedby="modal-description"
      className="select-none bg-black/75"
    >
      <Box
        sx={{
          position: "absolute",
          top: "50%",
          left: "50%",
          transform: "translate(-50%, -50%)",
          width: width,
          boxShadow: "0 4px 20px rgba(0, 0, 0, 0.5)",
          px: 2,
          py: 1,
          pb: 2,
          maxHeight: "90vh",
          overflowY: "auto",
          color: "white",
        }}
        className="bg-[#080808] outline-none border border-white/10"
      >
        <div
          className={classNames("flex items-center justify-between pb-1 mb-3", {
            "border-b border-white/10": title,
          })}
        >
          {title && (
            <h1
              id="modal-title"
              className="text-a1a1a1 font-primary tracking-wider font-medium uppercase"
            >
              {title}
            </h1>
          )}
        </div>
        <button
          hidden={!title}
          onClick={onClose}
          className="absolute w-3 h-3 rounded-full top-1 right-1 outline-none bg-C12D2D"
        ></button>
        <Box id="modal-description" className="text-gray-300">
          {children}
        </Box>
      </Box>
    </Modal>
  );
};

export default ModalComponent;
