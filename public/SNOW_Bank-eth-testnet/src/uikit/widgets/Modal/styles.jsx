import React from "react";
import styled from "styled-components";
import Flex from "../../components/Box/Flex";
import { Box } from "../../components/Box";
import { ArrowBackIcon, CloseIcon } from "../../components/Svg";
import { IconButton } from "../../components/Button";

export const ModalHeader = styled.div`
  align-items: center;
  background: transparent;
  display: flex;
  padding: 12px 24px;
`;

export const ModalTitle = styled(Flex)`
  background: transparent;
  align-items: center;
  flex: 1;
`;

export const ModalBody = styled(Flex)`
  flex-direction: column;
  max-height: 90vh;
  overflow-y: auto;
  background: transparent;
`;

export const ModalCloseButton = ({ onDismiss }) => {
  return (
    <IconButton
      variant="text"
      onClick={onDismiss}
      aria-label="Close the dialog"
    >
      <CloseIcon color="white" width="24px" />
    </IconButton>
  );
};

export const ModalBackButton = ({ onBack }) => {
  return (
    <IconButton variant="text" onClick={onBack} area-label="go back" mr="8px">
      <ArrowBackIcon color="primary" />
    </IconButton>
  );
};

export const ModalContainer = styled(Box)`
  width: 100%;
  max-height: 100vh;
  z-index: 10000;

  @media screen and (min-width: 370px) {
    width: auto;
    min-width: 350px;
    max-width: 100%;
  }
`;
