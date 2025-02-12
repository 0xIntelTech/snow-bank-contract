import { BIG_TEN } from "utils/bigNumber";
import BigNumber from "bignumber.js";
import { IoBook } from "react-icons/io5";
import { FaDiscord } from "react-icons/fa6";
import { FaGithub, FaYoutube } from "react-icons/fa";
import { FaTelegramPlane } from "react-icons/fa";
import { FaTwitter } from "react-icons/fa";

export const BASE_URL = "https://snowbank.io";
export const ALCHEMY_ID = "86wTK178jC4XNO9sh-iVI7P5fV1tg_Dx";

export const CHAIN_ID = 56;
export const TESTNET_CHAIN_ID = 5;

// house_010525: not used
export const TREASURY = "0x2324Bf6650AEA8710d1f868C829986eD6aDAfD4A"; // 0x41140Df415A2898937d147842C314c70B3aab82E // 0x2324Bf6650AEA8710d1f868C829986eD6aDAfD4A

export const DEFAULT_GAS_LIMIT = 2000000;
export const DEFAULT_GAS_PRICE = 2;
export const DEFAULT_TOKEN_DECIMAL = BIG_TEN.pow(18);
export const NUMBER_OF_FARMS_VISIBLE = 12;
export const snowWethFarmPid = 0;
export const wplsUsdcFarmPid = 1;
export const YEAR = 60 * 60 * 24 * 365;
export const YEAR_BN = new BigNumber(YEAR);

export const NFT_PRICE = 0.3;
export const SALE_PRICE = 60;
export const LAUNCH_PRICE = 70;
export const MAX_PER_USER = 80000;
export const HARD_CAP = 50;
export const SOFT_CAP = 10;
// export const MAX_PER_USER = 300;

export const mainTokenSymbol = "SNOW";
export const DOCS_URL = "https://snowbank.gitbook.io/snow-bank";

export const BASE_EXCHANGE_URL_BY_CHAIN = {
  56: "https://pancakeswap.finance",
};

export const BASE_EXCHANGE_URL = BASE_EXCHANGE_URL_BY_CHAIN[CHAIN_ID];

export const BASE_ADD_LIQUIDITY_URL = `${BASE_EXCHANGE_URL}/liquidity`;
export const BASE_SWAP_URL = `${BASE_EXCHANGE_URL}/swap`;
export const ARCHIVED_NODE = "https://bsc-dataseed.plschain.org/";

// export const YEAR = 60 * 60 * 24 * 365
// export const YEAR_BN = new BigNumber(YEAR)

export const privateSNOWPrice = 12;
export const BASE_EXPLORER = "https://bscscan.com/";

export const socials = [
  {
    icon: () => <IoBook />,
    name: "",
    href: "https://snowbank.gitbook.io/snow-bank",
  },
  {
    icon: () => <FaDiscord />,
    name: "",
    href: "https://discord.com/invite/Gde9pgxX",
  },
  {
    icon: () => <FaGithub />,
    name: "",
    href: "https://github.com/cryptoGuru525/snow_bank_final",
  },
  // {
  //   icon: () => <FaYoutube />,
  //   name: "",
  //   href: "https://youtube.com/@lodgecapital",
  // },
  {
    icon: () => <FaTwitter />,
    name: "",
    href: "https://x.com/SnowBank_io",
  },
  {
    icon: () => <FaTelegramPlane />,
    name: "",
    href: "https://t.me/Snowbanktg",
  },
];

export const routes = [
  {
    name: "STAKE",
    url: "/",
  },
  {
    name: "NFTs",
    url: "/nfts",
  },
  {
    name: "SWAP",
    url: "/swap",
  },
  {
    name: "ROADMAP",
    url: "/roadmap",
  },
];

export const roadmaps = [
  {
    title: "EARLY DECEMBER 2024",
    content: "Snow Bank deployment on Pulsechain",
  },
  {
    title: "MID DECEMBER 2024",
    content: "Snow Bank deployment on Avalanche",
  },
  {
    title: "LATE DECEMBER 2024",
    content: "Snow Bank deployment on BASE",
  },
  {
    title: "EARLY JANUARY 2025",
    content: "Snow Bank deployment on BSC (Binance Smart Chain)",
  },
  {
    title: "MID JANUARY 2025",
    content: "Snow Bank deployment on Ethereum Mainnet",
  },
  {
    title: "LATE JANUARY 2025",
    content: "Snow Bank deployment on Solana",
  },
];
