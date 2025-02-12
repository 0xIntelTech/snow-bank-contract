import React from "react";

import Swap from "pages/Swap";
import NotFound from "pages/Notfound";
import Farms from "pages/Farms";
import NFTPresale from "pages/NFTPresale";
import Roadmap from "pages/Roadmap";
import ComingSoon from "pages/ComingSoon";

const router = [
  {
    path: "/",
    element: <Farms />,
  },
  {
    path: "/nfts",
    element: <NFTPresale />,
  },
  {
    path: "/roadmap",
    element: <Roadmap />,
  },
  {
    path: "/stake",
    element: <Farms />,
  },
  {
    path: "/swap",
    element: <Swap />,
  },
  {
    path: "/game",
    element: <ComingSoon />,
  },
  {
    path: "/bank",
    element: <ComingSoon />,
  },
  // {
  //   path: "/nft-claim",
  //   element: <NFT />,
  // },
  // {
  //   path: "/presale",
  //   element: <SnowPresale />,
  // },
  {
    path: "*",
    element: <NotFound />,
  },
];

export default router;
