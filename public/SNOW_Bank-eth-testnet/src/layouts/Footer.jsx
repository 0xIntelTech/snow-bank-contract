import React from "react";
import { socials } from "config";

export default function Footer() {
  return (
    <footer className="absolute bottom-0 w-full mb-2 container left-1/2 -translate-x-1/2 py-2">
      <div className="gap-4 flex justify-center items-center">
        {socials.map((item, index) => {
          const Icon = item.icon;
          return (
            <a
              href={item.href}
              key={index}
              className={`p-1 flex items-center justify-center h-[35px!important] w-[35px!important] main_btn_footer hover:scale-[100%!important]`}
              target="_blank"
              rel="noopener noreferrer"
            >
              <Icon />
              {item.name}
            </a>
          );
        })}
      </div>
    </footer>
  );
}
